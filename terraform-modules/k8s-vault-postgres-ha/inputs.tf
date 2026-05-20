variable "Cluster" {}
variable "Color" {}
variable "Settings" {}
variable "GkeClusterConnectionSettings" {}
variable "VaultAddress" {}

data "vault_generic_secret" "root_user" {
  path = "secret/${local.vault_path}/root-user"
}

data "vault_generic_secret" "ha_auth" {
  path = "secret/${local.ha_auth_vault_path}"
}

data "vault_kv_secrets_list_v2" "db_user_list" {
  mount = "secret"
  name  = "${local.vault_path}/db-users"
}

data "vault_generic_secret" "databases" {
  for_each = local.databases
  path     = "secret/${local.vault_path}/db-users/${each.value}"
}

locals {
  cluster_settings     = var.Settings.clusters[var.Cluster]
  postgres_ha_settings = local.cluster_settings["postgresql-ha"]
  persistent_postgres  = local.cluster_settings.persistent_resources.permanentDisks.services["postgresql-ha"]["postgresql-ha"]
  zones                = local.cluster_settings.persistent_resources.permanentDisks.zones

  cluster_name                        = endswith(local.postgres_ha_settings.cluster_name, "-ha") ? local.postgres_ha_settings.cluster_name : "${local.postgres_ha_settings.cluster_name}-ha"
  namespace                           = local.postgres_ha_settings.namespace
  vault_path                          = local.postgres_ha_settings.vault_path
  chart_version                       = local.postgres_ha_settings.chart_version
  database                            = lookup(local.postgres_ha_settings, "database", "postgres")
  postgres_replicas                   = local.postgres_ha_settings.replicas
  pgpool_replicas                     = lookup(local.postgres_ha_settings, "pgpool_replicas", 1)
  storage_size                        = format("%sGi", local.persistent_postgres.size)
  postgresql_image_registry           = lookup(local.postgres_ha_settings, "postgresql_image_registry", "")
  postgresql_image_repository         = lookup(local.postgres_ha_settings, "postgresql_image_repository", "")
  postgresql_image_tag                = lookup(local.postgres_ha_settings, "postgresql_image_tag", "")
  pgpool_image_registry               = lookup(local.postgres_ha_settings, "pgpool_image_registry", "")
  pgpool_image_repository             = lookup(local.postgres_ha_settings, "pgpool_image_repository", "")
  pgpool_image_tag                    = lookup(local.postgres_ha_settings, "pgpool_image_tag", "")
  postgresql_resources                = lookup(local.postgres_ha_settings, "resources", null)
  pgpool_resources                    = lookup(local.postgres_ha_settings, "pgpool_resources", null)
  postgresql_pod_anti_affinity_preset = lookup(local.postgres_ha_settings, "postgresql_pod_anti_affinity_preset", "hard")
  pgpool_pod_anti_affinity_preset     = lookup(local.postgres_ha_settings, "pgpool_pod_anti_affinity_preset", "hard")
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
  postgresql_pdb_create        = lookup(local.postgres_ha_settings, "postgresql_pdb_create", true)
  postgresql_pdb_min_available = lookup(local.postgres_ha_settings, "postgresql_pdb_min_available", 2)
  pgpool_pdb_create            = lookup(local.postgres_ha_settings, "pgpool_pdb_create", true)
  pgpool_pdb_min_available     = lookup(local.postgres_ha_settings, "pgpool_pdb_min_available", 1)

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

  enable_post_script   = lookup(local.postgres_ha_settings, "enable_post_script", false)
  post_script_tag      = lookup(local.postgres_ha_settings, "post_script_tag", "v0.0.8")
  post_script_image    = lookup(local.postgres_ha_settings, "post_script_image", "harbor.regemini.io/op/postgres-script")
  post_script_job_name = lookup(local.postgres_ha_settings, "post_script_job_name", "post-postgres")
  vault_role_name      = lookup(local.postgres_ha_settings, "vault_role_name", "postgres")
  vault_role_path      = lookup(local.postgres_ha_settings, "vault_role_path", "k8s-${var.Cluster}-${var.Color}")
  ha_auth_vault_path   = lookup(local.postgres_ha_settings, "ha_auth_vault_path", "${local.vault_path}/ha-auth")

  auth_secret_name                = lookup(local.postgres_ha_settings, "auth_secret_name", "${local.cluster_name}-postgresql-ha-auth")
  pgpool_custom_users_secret_name = lookup(local.postgres_ha_settings, "pgpool_custom_users_secret_name", "${local.cluster_name}-pgpool-custom-users")
  root_secret_name                = lookup(local.postgres_ha_settings, "root_secret_name", "${local.cluster_name}-superuser")
  post_script_secret_name         = lookup(local.postgres_ha_settings, "post_script_secret_name", local.root_secret_name)

  databases               = nonsensitive(toset(data.vault_kv_secrets_list_v2.db_user_list.names))
  db_user_pass            = { for name in local.databases : name => tomap(data.vault_generic_secret.databases[name].data) }
  db_user_names           = sort(keys(local.db_user_pass))
  pgpool_custom_usernames = join(";", [for name in local.db_user_names : local.db_user_pass[name].username])
  pgpool_custom_passwords = join(";", [for name in local.db_user_names : local.db_user_pass[name].password])

  db_bootstrap_sql = join("\n\n", concat(
    ["\\set ON_ERROR_STOP on"],
    [for db_name, user in local.db_user_pass : <<-EOT
DO $role$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${replace(user.username, "'", "''")}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${replace(user.username, "'", "''")}', '${replace(user.password, "'", "''")}');
  END IF;
END
$role$;

SELECT format('CREATE DATABASE %I OWNER %I', '${replace(db_name, "'", "''")}', '${replace(user.username, "'", "''")}')
WHERE NOT EXISTS (
  SELECT 1 FROM pg_database WHERE datname = '${replace(db_name, "'", "''")}'
)\gexec
EOT
    ]
  ))
  db_bootstrap_job_name = lookup(local.postgres_ha_settings, "db_bootstrap_job_name", "${local.cluster_name}-db-bootstrap-${substr(sha1(local.db_bootstrap_sql), 0, 8)}")
}
