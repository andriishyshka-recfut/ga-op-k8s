# ClickHouse backup

Schedules native full backups across the ClickHouse cluster to MinIO, excluding
system and information-schema databases. Configuration controls whether backups
run, their schedule, retention in days, and the minimum number of backups to keep.

Requires the deployment's authentication, TLS, MinIO, and registry Secrets, plus
access to the environment's backup bucket. Overlapping scheduled Jobs are blocked.

After success, a completion marker is stored in MinIO. Cleanup deletes only marked
backups older than `retention_days` and outside the newest `minimum_backups`.
Unmarked backups are left untouched. Failed backups do not trigger cleanup.
Kubernetes Job history is separate: successful and failed Jobs have count limits.
