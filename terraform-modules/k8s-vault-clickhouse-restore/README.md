# ClickHouse restore

Restores all databases or a selected database from a native MinIO backup across
the ClickHouse cluster. Uses existing authentication, TLS, and backup disk settings.

Run through `tekton/stage-5/05-clickhouse-restore` or the restore Tekton task.
Set `RestoreBackupName` and a unique `RestoreRunId`. Leave `RestoreDatabase` empty
for a full restore, or provide a database name for selective restoration.

Prepare an empty destination and pause writes and backups during restoration.
Terraform waits for the Job to complete; failed restores are not retried
automatically. A failure may leave partial data, so prepare the destination
before retrying with a new run ID. Verify restored data before resuming writes.
