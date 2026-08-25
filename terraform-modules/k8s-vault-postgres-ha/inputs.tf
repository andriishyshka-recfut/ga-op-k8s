variable "Cluster" {}
variable "Settings" {}
variable "PostgresqlHaProfile" {}

data "vault_kv_secrets_list_v2" "db_user_list" {
  mount = "secret"
  name  = "${local.vault_path}/db-users"
}

data "vault_generic_secret" "databases" {
  for_each = local.databases
  path     = "secret/${local.vault_path}/db-users/${each.value}"
}

data "vault_generic_secret" "root_user" {
  path = "secret/${local.vault_path}/root-user"
}

data "vault_generic_secret" "ha_auth" {
  path = "secret/${local.ha_auth_vault_path}"
}

locals {
  cluster_settings     = var.Settings.clusters[var.Cluster]
  postgres_ha_settings = local.cluster_settings["postgresql-ha"][var.PostgresqlHaProfile]
  persistent_postgres  = local.cluster_settings.persistent_resources.permanentDisks.services["postgresql-ha"][var.PostgresqlHaProfile]
  zones                = local.cluster_settings.persistent_resources.permanentDisks.zones

  cluster_name                = local.postgres_ha_settings.cluster_name
  namespace                   = local.postgres_ha_settings.namespace
  vault_path                  = local.postgres_ha_settings.vault_path
  chart_version               = local.postgres_ha_settings.chart_version
  postgresql_image_registry   = lookup(local.postgres_ha_settings, "postgresql_image_registry", "")
  postgresql_image_repository = lookup(local.postgres_ha_settings, "postgresql_image_repository", "")
  postgresql_image_tag        = lookup(local.postgres_ha_settings, "postgresql_image_tag", "")
  # Full affinity blocks are kept here as a fallback when preset-based anti-affinity
  # is no longer enough and we need custom topology keys or label selectors.
  # postgresql_affinity = lookup(local.postgres_ha_settings, "postgresql_affinity", {
  #   podAntiAffinity = {
  #     requiredDuringSchedulingIgnoredDuringExecution = [
  #       {
  #         labelSelector = {
  #           matchLabels = {
  #             "app.kubernetes.io/component" = "postgresql"
  #             "app.kubernetes.io/instance"  = local.cluster_name
  #           }
  #         }
  #         topologyKey = "kubernetes.io/hostname"
  #       }
  #     ]
  #   }
  # })
  # pgpool_affinity = lookup(local.postgres_ha_settings, "pgpool_affinity", {
  #   podAntiAffinity = {
  #     requiredDuringSchedulingIgnoredDuringExecution = [
  #       {
  #         labelSelector = {
  #           matchLabels = {
  #             "app.kubernetes.io/component" = "pgpool"
  #             "app.kubernetes.io/instance"  = local.cluster_name
  #           }
  #         }
  #         topologyKey = "kubernetes.io/hostname"
  #       }
  #     ]
  #   }
  # })

  /*
  backup_settings          = lookup(local.postgres_ha_settings, "backup", {})
  backup_enabled           = lookup(local.backup_settings, "enabled", false) && lookup(local.backup_settings, "bucket", "") != ""
  backup_host              = lookup(local.backup_settings, "host", "${local.cluster_name}-pgpool")
  backup_port              = tostring(lookup(local.backup_settings, "port", 5432))
  backup_image             = lookup(local.backup_settings, "image", local.db_bootstrap_image)
  backup_tag               = lookup(local.backup_settings, "tag", local.db_bootstrap_tag)
  backup_minio_vault_path  = lookup(local.backup_settings, "minio_vault_path", "secret/minio/users")
  backup_minio_user        = lookup(local.backup_settings, "minio_user", "backup")
  backup_minio_alias       = lookup(local.backup_settings, "minio_alias", "backup")
  backup_minio_endpoint    = lookup(local.backup_settings, "minio_endpoint", "https://minio.p.regemini.io")
  backup_bucket            = lookup(local.backup_settings, "bucket", "")
  backup_path              = trim(lookup(local.backup_settings, "path", "postgresql-ha-backup/${local.cluster_name}"), "/")
  backup_weekly_schedule   = lookup(local.backup_settings, "weekly_schedule", "0 1 * * 0")
  backup_daily_schedule    = lookup(local.backup_settings, "daily_schedule", "0 2 * * *")
  backup_monthly_schedule  = lookup(local.backup_settings, "monthly_schedule", "0 3 1 * *")
  backup_daily_retention   = lookup(local.backup_settings, "daily_retention", "7d")
  backup_weekly_retention  = lookup(local.backup_settings, "weekly_retention", "28d")
  backup_monthly_retention = lookup(local.backup_settings, "monthly_retention", "183d")
  backup_secret_name       = lookup(local.backup_settings, "secret_name", "${local.cluster_name}-backup-minio")
  */

  disk_count           = local.persistent_postgres.count
  disk_prefix          = local.persistent_postgres.prefix
  pv_selector_label    = lookup(local.postgres_ha_settings, "pv_selector_label", local.disk_prefix)
  pv_claim_name_prefix = lookup(local.postgres_ha_settings, "pv_claim_name_prefix", "data-${local.cluster_name}-postgresql")

  enable_db_bootstrap      = lookup(local.postgres_ha_settings, "enable_db_bootstrap", true)
  db_bootstrap_host        = lookup(local.postgres_ha_settings, "db_bootstrap_host", "${local.cluster_name}-pgpool")
  db_bootstrap_port        = tostring(lookup(local.postgres_ha_settings, "db_bootstrap_port", 5432))
  db_bootstrap_database    = lookup(local.postgres_ha_settings, "db_bootstrap_database", "postgres")
  db_bootstrap_secret_name = lookup(local.postgres_ha_settings, "db_bootstrap_secret_name", "${local.cluster_name}-db-bootstrap")
  db_bootstrap_image       = lookup(local.postgres_ha_settings, "db_bootstrap_image", local.postgresql_image_repository != "" ? "${local.postgresql_image_registry != "" ? "${local.postgresql_image_registry}/" : ""}${local.postgresql_image_repository}" : "postgres")
  db_bootstrap_tag         = lookup(local.postgres_ha_settings, "db_bootstrap_tag", local.postgresql_image_tag != "" ? local.postgresql_image_tag : "17")

  # pgpool uses the clear-text `password` auth method (pass-through): it relays the
  # client password to the backend instead of storing it in pgpool_passwd, so Vault
  # can rotate the static-role passwords with no pgpool re-sync. `password` keeps
  # pool_hba on (unlike allow_clear_text_frontend_auth) so system users still work.
  # NOTE: no TLS -> passwords transit the pod network in clear text.
  # Enabled only when app DB users exist; otherwise the chart default (scram) stays.
  ha_auth_vault_path = lookup(local.postgres_ha_settings, "ha_auth_vault_path", "${local.vault_path}/ha-auth")

  auth_secret_name = lookup(local.postgres_ha_settings, "auth_secret_name", "${local.cluster_name}-postgresql-ha-auth")
  root_secret_name = lookup(local.postgres_ha_settings, "root_secret_name", "${local.cluster_name}-superuser")

  helm_values_context = {
    auth_secret_name                    = local.auth_secret_name
    cluster_name                        = local.cluster_name
    database                            = lookup(local.postgres_ha_settings, "database", "postgres")
    metrics_enabled                     = lookup(local.postgres_ha_settings, "metrics_enabled", false)
    metrics_image_registry              = lookup(local.postgres_ha_settings, "metrics_image_registry", "")
    metrics_image_repository            = lookup(local.postgres_ha_settings, "metrics_image_repository", "")
    metrics_image_tag                   = lookup(local.postgres_ha_settings, "metrics_image_tag", "")
    metrics_service_enabled             = lookup(local.postgres_ha_settings, "metrics_service_enabled", true)
    metrics_service_monitor_enabled     = lookup(local.postgres_ha_settings, "metrics_service_monitor_enabled", false)
    metrics_service_monitor_interval    = lookup(local.postgres_ha_settings, "metrics_service_monitor_interval", "")
    metrics_service_monitor_labels      = lookup(local.postgres_ha_settings, "metrics_service_monitor_labels", { release = "prometheus" })
    metrics_service_monitor_namespace   = lookup(local.postgres_ha_settings, "metrics_service_monitor_namespace", "monitoring")
    pgpool_custom_liveness_probe        = lookup(local.postgres_ha_settings, "pgpool_custom_liveness_probe", null)
    pgpool_custom_readiness_probe       = lookup(local.postgres_ha_settings, "pgpool_custom_readiness_probe", null)
    pgpool_custom_startup_probe         = lookup(local.postgres_ha_settings, "pgpool_custom_startup_probe", null)
    pgpool_image_registry               = lookup(local.postgres_ha_settings, "pgpool_image_registry", "")
    pgpool_image_repository             = lookup(local.postgres_ha_settings, "pgpool_image_repository", "")
    pgpool_image_tag                    = lookup(local.postgres_ha_settings, "pgpool_image_tag", "")
    pgpool_liveness_probe               = lookup(local.postgres_ha_settings, "pgpool_liveness_probe", null)
    pgpool_passthrough                  = length(local.database_names) > 0
    pgpool_pod_anti_affinity_preset     = lookup(local.postgres_ha_settings, "pgpool_pod_anti_affinity_preset", "hard")
    pgpool_replicas                     = lookup(local.postgres_ha_settings, "pgpool_replicas", 1)
    pgpool_readiness_probe              = lookup(local.postgres_ha_settings, "pgpool_readiness_probe", null)
    pgpool_pdb_create                   = lookup(local.postgres_ha_settings, "pgpool_pdb_create", true)
    pgpool_pdb_min_available            = lookup(local.postgres_ha_settings, "pgpool_pdb_min_available", 1)
    pgpool_resources                    = lookup(local.postgres_ha_settings, "pgpool_resources", null)
    pgpool_startup_probe                = lookup(local.postgres_ha_settings, "pgpool_startup_probe", null)
    postgres_replicas                   = local.postgres_ha_settings.replicas
    postgresql_custom_liveness_probe    = lookup(local.postgres_ha_settings, "postgresql_custom_liveness_probe", null)
    postgresql_custom_readiness_probe   = lookup(local.postgres_ha_settings, "postgresql_custom_readiness_probe", null)
    postgresql_custom_startup_probe     = lookup(local.postgres_ha_settings, "postgresql_custom_startup_probe", null)
    postgresql_image_registry           = local.postgresql_image_registry
    postgresql_image_repository         = local.postgresql_image_repository
    postgresql_image_tag                = local.postgresql_image_tag
    postgresql_liveness_probe           = lookup(local.postgres_ha_settings, "postgresql_liveness_probe", null)
    postgresql_pod_anti_affinity_preset = lookup(local.postgres_ha_settings, "postgresql_pod_anti_affinity_preset", "hard")
    postgresql_readiness_probe          = lookup(local.postgres_ha_settings, "postgresql_readiness_probe", null)
    postgresql_pdb_create               = lookup(local.postgres_ha_settings, "postgresql_pdb_create", true)
    postgresql_pdb_min_available        = lookup(local.postgres_ha_settings, "postgresql_pdb_min_available", 2)
    postgresql_resources                = lookup(local.postgres_ha_settings, "resources", null)
    postgresql_startup_probe            = lookup(local.postgres_ha_settings, "postgresql_startup_probe", null)
    root_username                       = data.vault_generic_secret.root_user.data.username
    storage_size                        = format("%sGi", local.persistent_postgres.size)
    pv_selector_label                   = local.pv_selector_label
  }

  databases      = nonsensitive(toset(data.vault_kv_secrets_list_v2.db_user_list.names))
  db_user_pass   = { for name in local.databases : name => tomap(data.vault_generic_secret.databases[name].data) }
  database_names = sort(keys(local.db_user_pass))
  app_db_users = {
    for name in local.database_names : name => {
      owner_username = lookup(local.db_user_pass[name], "username", name)
      owner_password = lookup(local.db_user_pass[name], "password", "")
      rw_username    = "${lookup(local.db_user_pass[name], "username", name)}-rw"
      ro_username    = "${lookup(local.db_user_pass[name], "username", name)}-ro"
      rw_password    = lookup(local.db_user_pass[name], "password", "")
      ro_password    = lookup(local.db_user_pass[name], "password", "")
    }
  }
  db_bootstrap_sql = join("\n\n", concat(
    ["\\set ON_ERROR_STOP on"],
    [for db_name in local.database_names : <<-EOT
DO $role$
BEGIN
  -- The owner role follows the raw KV payload and is reconciled on every run.
  -- The rw/ro roles are later adopted by Vault static roles, so their password is
  -- set ONLY on initial CREATE. Re-running bootstrap must NOT reset those passwords
  -- or it desyncs from Vault and pass-through backend auth via pgpool fails.
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${replace(local.app_db_users[db_name].owner_username, "'", "''")}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${replace(local.app_db_users[db_name].owner_username, "'", "''")}', '${replace(local.app_db_users[db_name].owner_password, "'", "''")}');
  ELSE
    EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', '${replace(local.app_db_users[db_name].owner_username, "'", "''")}', '${replace(local.app_db_users[db_name].owner_password, "'", "''")}');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${replace(local.app_db_users[db_name].rw_username, "'", "''")}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${replace(local.app_db_users[db_name].rw_username, "'", "''")}', '${replace(local.app_db_users[db_name].rw_password, "'", "''")}');
  END IF;

  EXECUTE format('ALTER ROLE %I WITH LOGIN', '${replace(local.app_db_users[db_name].rw_username, "'", "''")}');

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${replace(local.app_db_users[db_name].ro_username, "'", "''")}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${replace(local.app_db_users[db_name].ro_username, "'", "''")}', '${replace(local.app_db_users[db_name].ro_password, "'", "''")}');
  END IF;

  EXECUTE format('ALTER ROLE %I WITH LOGIN', '${replace(local.app_db_users[db_name].ro_username, "'", "''")}');
END
$role$;

SELECT format('CREATE DATABASE %I OWNER %I', '${replace(db_name, "'", "''")}', '${replace(local.app_db_users[db_name].owner_username, "'", "''")}')
WHERE NOT EXISTS (
  SELECT 1 FROM pg_database WHERE datname = '${replace(db_name, "'", "''")}'
)\gexec

\connect ${replace(db_name, "'", "''")}

GRANT ALL PRIVILEGES ON DATABASE "${replace(db_name, "\"", "\"\"")}" TO "${replace(local.app_db_users[db_name].owner_username, "\"", "\"\"")}";
GRANT CONNECT, TEMPORARY ON DATABASE "${replace(db_name, "\"", "\"\"")}" TO "${replace(local.app_db_users[db_name].rw_username, "\"", "\"\"")}";
GRANT CONNECT ON DATABASE "${replace(db_name, "\"", "\"\"")}" TO "${replace(local.app_db_users[db_name].ro_username, "\"", "\"\"")}";
GRANT USAGE, CREATE ON SCHEMA public TO "${replace(local.app_db_users[db_name].rw_username, "\"", "\"\"")}";
GRANT USAGE ON SCHEMA public TO "${replace(local.app_db_users[db_name].ro_username, "\"", "\"\"")}";
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public TO "${replace(local.app_db_users[db_name].rw_username, "\"", "\"\"")}";
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO "${replace(local.app_db_users[db_name].rw_username, "\"", "\"\"")}";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO "${replace(local.app_db_users[db_name].rw_username, "\"", "\"\"")}";
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "${replace(local.app_db_users[db_name].ro_username, "\"", "\"\"")}";
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO "${replace(local.app_db_users[db_name].ro_username, "\"", "\"\"")}";
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO "${replace(local.app_db_users[db_name].ro_username, "\"", "\"\"")}";
ALTER DEFAULT PRIVILEGES FOR ROLE "${replace(local.app_db_users[db_name].owner_username, "\"", "\"\"")}" IN SCHEMA public GRANT SELECT ON TABLES TO "${replace(local.app_db_users[db_name].ro_username, "\"", "\"\"")}";
ALTER DEFAULT PRIVILEGES FOR ROLE "${replace(local.app_db_users[db_name].owner_username, "\"", "\"\"")}" IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO "${replace(local.app_db_users[db_name].ro_username, "\"", "\"\"")}";
ALTER DEFAULT PRIVILEGES FOR ROLE "${replace(local.app_db_users[db_name].rw_username, "\"", "\"\"")}" IN SCHEMA public GRANT SELECT ON TABLES TO "${replace(local.app_db_users[db_name].ro_username, "\"", "\"\"")}";
ALTER DEFAULT PRIVILEGES FOR ROLE "${replace(local.app_db_users[db_name].rw_username, "\"", "\"\"")}" IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO "${replace(local.app_db_users[db_name].ro_username, "\"", "\"\"")}";
EOT
    ]
  ))
  db_bootstrap_job_name = lookup(local.postgres_ha_settings, "db_bootstrap_job_name", "${local.cluster_name}-db-bootstrap-${substr(sha1(local.db_bootstrap_sql), 0, 8)}")
}
