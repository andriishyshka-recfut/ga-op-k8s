# k8s-vault-postgres-ha-backup

Backup module extracted from `k8s-vault-postgres-ha` for `postgresql-ha`.

Current behavior:

- cluster-wide backups use one daily full `pg_dumpall | gzip`
- optional daily `globals.sql` backup stores `pg_dumpall --globals-only`
- optional per-database full backups use `pg_dump -Fc` with ownership and ACLs
- all backup types keep the last 7 days by default

Per-database backups are enabled from `postgresql-ha.<profile>.backup.databases`, for example:

```json
"backup": {
  "enabled": true,
  "databases": ["birl", "gitlab"]
}
```

Only database names that also exist in the Vault `db-users` structure are backed up.

Paths:

- cluster backups:
  - `s3://<bucket>/postgresql-ha/<cluster_name>/cluster/<cluster_name>-<timestamp>.sql.gz`
- globals:
  - `s3://<bucket>/postgresql-ha/<cluster_name>/globals-<timestamp>.sql`
- per-database backups:
  - `.../postgresql-ha/<cluster_name>/databases/<database>/<database>-<timestamp>.dump`
  - `.../postgresql-ha/<cluster_name>/databases/<database>/<database>-<timestamp>.owner`
  - `.../postgresql-ha/<cluster_name>/databases/<database>/<database>-<timestamp>.grants.sql`

Settings:

- `schedule`
  - default: `0 2 * * *`
- `retention`
  - default: `7d`
- `globals_enabled`
  - default: `true`
