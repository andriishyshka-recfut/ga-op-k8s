# ClickHouse

Deploys the official ClickHouse operator, ClickHouse, and Keeper with TLS.
Environment configuration controls topology, resources, storage, and backups.

Provision namespaces, permanent disks, and Vault credentials before deployment.
Requires cert-manager and a Vault PKI role for ClickHouse certificates.
The module binds each replica to its prepared disk through retained PVs/PVCs.
Keeper requires a positive odd replica count; disk counts must match topology.

Credentials are read from Vault using ephemeral resources and passed through
write-only arguments. Preserve internal cluster credentials together with
ClickHouse and Keeper disks during DR.

Applications connect through the ClickHouse headless Service using native TLS
and the issuing CA. Use Replicated databases for schema synchronization and
ReplicatedMergeTree tables for data replication.
