language for human-agent conversational: ukrainian, russian, english
language for README: english

Bitnami `postgresql-ha` + Vault creds. Read README.md before touching pgpool auth, TLS, storage, or Vault wiring.

Do NOT:
- change `PGPOOL_AUTHENTICATION_METHOD` off `scram-sha-256`, or turn `enable_pool_hba` off (Bitnami rejects `password`).
- load app users into `pgpool_passwd` — they auth via the clear-text `password` pass-through lines in `pgpool.poolHbaConfiguration`; only `postgres`/`repmgr`/`sr_check` use `scram`.
- reintroduce a pgpool credential-sync CronJob (removed — see README).
- enable TLS without re-adding a `volumePermissions.image` override (bitnamilegacy os-shell).
- reorder bootstrap: `<db>-rw|ro` roles must be CREATEd before the post module adopts them as static roles.

Credential mode is static; apps read `<vault_backend_path>/static-creds/<db>-rw|ro`.

Changing db-users, role names, `vault_backend_path`, or `credential_mode` → also update `../k8s-vault-postgres-post` (run twice from `tekton/stage-6/06-postgres/main.tf`).

Keep aligned: `Settings.clusters[Cluster]["postgresql-ha"][<profile>]`, its matching
`persistent_resources.permanentDisks.services["postgresql-ha"][<profile>]`, and Vault
secrets in `clusters/*/00_persistent-resources/postgres.tf`.
