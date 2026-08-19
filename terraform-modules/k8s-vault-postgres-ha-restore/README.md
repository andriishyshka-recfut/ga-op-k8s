# k8s-vault-postgres-ha-restore

Standalone restore module for `postgresql-ha` per-database backups.

This module is intentionally separate from `k8s-vault-postgres-ha-backup` so
restore can be triggered as a one-off operation without storing restore
parameters in the persistent cluster config.

Inputs:

- `Cluster`
- `Settings`
- `PostgresqlHaProfile`
- `RestoreDatabase`
- `RestoreBackupTimestamp`
- optional `RestoreJobName`

Behavior:

- reads backup storage settings from `Settings.clusters[Cluster]["postgresql-ha"][PostgresqlHaProfile].backup`
- builds object paths for:
  - `<database>-<timestamp>.dump`
  - `<database>-<timestamp>.owner`
  - `<database>-<timestamp>.grants.sql`
- creates a one-off Kubernetes `Job`
- restores into a new database named `<database>_<runtime-timestamp>`

Prerequisites:

1. Backup settings must already be configured for `postgresql-ha`.
2. The backup credentials secret referenced by `postgresql-ha.backup.secret_name`
   must already exist in the target namespace.
3. Roles should be restored from `globals.sql` first if they are missing in the
   target cluster.

Runtime usage:

- do not store restore parameters in `config.tfvars.json`
- pass them as runtime Terraform variables:
  - `PostgresqlHaProfile`
  - `RestoreDatabase`
  - `RestoreBackupTimestamp`
  - optional `RestoreJobName`
- Tekton restore runs use the dedicated `tg-run-postgres-ha-restore` task

Tekton task params:

- `postgresql_ha_profile`
  - selects the profile under `Settings.clusters[Cluster]["postgresql-ha"]`
  - examples: `sandbox`, `prod`, `red`
- `restore_database`
  - source database name from backup storage
- `restore_backup_timestamp`
  - backup timestamp in `YYYYMMDDTHHMMSSZ` format
- `restore_job_name`
  - optional custom Kubernetes Job name override

TaskRun usage from `tekton-tasks/devops`:

- The repo contains a reusable TaskRun template at
  `tekton-tasks/devops/postgres-ha-restore.yaml`.
- You can patch its values on the fly and apply it without editing the file
  manually.

Example:

```bash
PROFILE=red
DB=gitlabhq_production
TS=20260819T020000Z

cat tekton-tasks/devops/postgres-ha-restore.yaml \
  | sed "s/value: \"sandbox\"/value: \"$PROFILE\"/" \
  | sed "s/value: \"birl\"/value: \"$DB\"/" \
  | sed "s/value: \"20260729T143850Z\"/value: \"$TS\"/" \
  | kubectl apply -f -
```

This applies a `TaskRun` for `tg-run-postgres-ha-restore`, which then runs
`terragrunt apply` in `k8s/tekton/stage-5/05-postgres-ha-restore` with:

- `PostgresqlHaProfile=<PROFILE>`
- `RestoreDatabase=<DB>`
- `RestoreBackupTimestamp=<TS>`
