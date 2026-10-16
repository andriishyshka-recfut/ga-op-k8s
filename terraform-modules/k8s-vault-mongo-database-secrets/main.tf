locals {
  collection_actions = {
    read      = ["find"]
    readWrite = ["find", "insert", "remove", "update"]
  }

  applications = {
    for application_name, application in var.Config.applications :
    application_name => {
      name                = application_name
      policy_name         = "${var.PolicyNamePrefix}-${application_name}"
      default_ttl_seconds = coalesce(application.default_ttl_seconds, var.Config.defaults.default_ttl_seconds)
      max_ttl_seconds     = coalesce(application.max_ttl_seconds, var.Config.defaults.max_ttl_seconds)
      database_roles = [
        for database_name, access in application.databases : {
          role = access.role_type
          db   = database_name
        } if access.role_type != null
      ]
      collection_privileges = flatten([
        for database_name, access in application.databases : [
          for collection_name, collection in access.collections : {
            db         = database_name
            collection = collection_name
            actions    = local.collection_actions[collection.role_type]
          }
        ]
      ])
    }
  }

  custom_roles = {
    for application_name, application in local.applications :
    application_name => {
      name       = "${var.CustomRoleNamePrefix}-${application_name}"
      privileges = application.collection_privileges
    } if length(application.collection_privileges) > 0
  }

  role_reconciler_config = {
    managed_role_prefix = "${var.CustomRoleNamePrefix}-"
    roles = [
      for application_name in sort(keys(local.custom_roles)) : {
        role = local.custom_roles[application_name].name
        privileges = [
          for privilege in local.custom_roles[application_name].privileges : {
            resource = {
              db         = privilege.db
              collection = privilege.collection
            }
            actions = privilege.actions
          }
        ]
      }
    ]
  }

  role_reconciler_script = <<-JAVASCRIPT
    const desired = EJSON.parse(process.env.MONGODB_CUSTOM_ROLES_JSON);
    const admin = db.getSiblingDB("admin");
    const desiredNames = new Set(desired.roles.map((role) => role.role));

    function assertSucceeded(action, result) {
      if (result.ok !== 1) {
        throw new Error(action + " failed: " + EJSON.stringify(result));
      }
    }

    for (const role of desired.roles) {
      const current = admin.runCommand({
        rolesInfo: { role: role.role, db: "admin" },
        showPrivileges: false
      });
      assertSucceeded("Reading role " + role.role, current);

      if (current.roles.length === 0) {
        print("Creating custom role " + role.role);
        assertSucceeded("Creating role " + role.role, admin.runCommand({
          createRole: role.role,
          privileges: role.privileges,
          roles: []
        }));
      } else {
        print("Updating custom role " + role.role);
        assertSucceeded("Updating role " + role.role, admin.runCommand({
          updateRole: role.role,
          privileges: role.privileges,
          roles: []
        }));
      }
    }

    const existing = admin.runCommand({
      rolesInfo: 1,
      showBuiltinRoles: false,
      showPrivileges: false
    });
    assertSucceeded("Listing custom roles", existing);

    for (const role of existing.roles) {
      if (role.db === "admin" &&
          role.role.startsWith(desired.managed_role_prefix) &&
          !desiredNames.has(role.role)) {
        print("Dropping stale custom role " + role.role);
        assertSucceeded("Dropping role " + role.role, admin.runCommand({
          dropRole: role.role
        }));
      }
    }
  JAVASCRIPT

  role_reconciler_revision = substr(sha256(jsonencode({
    config      = local.role_reconciler_config
    script      = local.role_reconciler_script
    image       = var.RoleReconcilerImage
    host        = var.MongoHost
    port        = var.MongoPort
    replica_set = var.MongoReplicaSet
  })), 0, 12)

  role_reconciler_name        = "vault-mongo-custom-roles-reconciler-${local.role_reconciler_revision}"
  role_reconciler_secret_name = "vault-mongo-connector-${substr(sha256(var.ConnectionName), 0, 12)}"
}

resource "kubernetes_secret_v1" "mongodb_connector" {
  metadata {
    name      = local.role_reconciler_secret_name
    namespace = var.KubernetesNamespace
  }

  data = {
    username = var.RootUsername
    password = var.RootPassword
  }

  type = "Opaque"
}

resource "kubernetes_config_map_v1" "role_reconciler" {
  metadata {
    name      = local.role_reconciler_name
    namespace = var.KubernetesNamespace
  }

  data = {
    "reconcile.js" = local.role_reconciler_script
    "roles.json"   = jsonencode(local.role_reconciler_config)
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "kubernetes_job_v1" "role_reconciler" {
  metadata {
    name      = local.role_reconciler_name
    namespace = var.KubernetesNamespace
  }

  spec {
    backoff_limit           = 1
    active_deadline_seconds = 300

    template {
      metadata {
        annotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }

      spec {
        automount_service_account_token = false
        restart_policy                  = "Never"

        container {
          name  = "reconcile"
          image = var.RoleReconcilerImage

          command = ["bash", "-ec"]
          args = [<<-BASH
            exec mongosh \
              --username "$MONGODB_USERNAME" \
              --password "$MONGODB_PASSWORD" \
              --authenticationDatabase admin \
              --quiet \
              "mongodb://$MONGODB_HOST:$MONGODB_PORT/admin?ssl=false&replicaSet=$MONGODB_REPLICA_SET&readPreference=primary" \
              /config/reconcile.js
          BASH
          ]

          env {
            name  = "MONGODB_HOST"
            value = var.MongoHost
          }

          env {
            name  = "MONGODB_PORT"
            value = tostring(var.MongoPort)
          }

          env {
            name  = "MONGODB_REPLICA_SET"
            value = var.MongoReplicaSet
          }

          env {
            name = "MONGODB_USERNAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.mongodb_connector.metadata[0].name
                key  = "username"
              }
            }
          }

          env {
            name = "MONGODB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.mongodb_connector.metadata[0].name
                key  = "password"
              }
            }
          }

          env {
            name = "MONGODB_CUSTOM_ROLES_JSON"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map_v1.role_reconciler.metadata[0].name
                key  = "roles.json"
              }
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
            read_only  = true
          }

          resources {
            requests = {
              cpu    = "25m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map_v1.role_reconciler.metadata[0].name
          }
        }
      }
    }
  }

  wait_for_completion = true

  timeouts {
    create = "10m"
    update = "10m"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "vault_mount" "database" {
  path = var.MountPath
  type = "database"
}

resource "vault_database_secret_backend_connection" "mongodb" {
  backend           = vault_mount.database.path
  name              = var.ConnectionName
  plugin_name       = "mongodb-database-plugin"
  verify_connection = var.VerifyConnection
  allowed_roles     = sort(keys(local.applications))
  password_policy   = var.PasswordPolicyName

  mongodb {
    connection_url = var.ConnectionUrl
    username       = var.RootUsername
    password       = var.RootPassword
  }
}

resource "vault_database_secret_backend_role" "mongodb" {
  for_each = local.applications

  backend         = vault_mount.database.path
  name            = each.value.name
  db_name         = vault_database_secret_backend_connection.mongodb.name
  default_ttl     = each.value.default_ttl_seconds
  max_ttl         = each.value.max_ttl_seconds
  credential_type = "password"

  creation_statements = [
    jsonencode({
      db = "admin"
      roles = concat(
        each.value.database_roles,
        contains(keys(local.custom_roles), each.key) ? [{
          role = local.custom_roles[each.key].name
          db   = "admin"
        }] : []
      )
    })
  ]

  depends_on = [kubernetes_job_v1.role_reconciler]
}

resource "vault_policy" "application" {
  for_each = local.applications

  name = each.value.policy_name
  policy = jsonencode({
    path = {
      "${vault_mount.database.path}/creds/${each.value.name}" = {
        capabilities = ["read"]
      }
    }
  })
}
