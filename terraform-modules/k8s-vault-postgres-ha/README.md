# k8s-vault-postgres-ha

PostgreSQL HA cluster based on Bitnami `postgresql-ha` (Postgres + repmgr + pgpool),
managed by Terraform and Helm, with Vault-backed credentials and bootstrap of
database users.

**Stack:** terraform, helm, vault, kubernetes, bitnami postgresql-ha.

## Naming and service URIs

- Helm sets `fullnameOverride = cluster_name`, so Kubernetes service names are derived
  directly from `postgresql-ha.cluster_name`.
- The module is now invoked once per `postgresql-ha` profile. The caller iterates
  `Settings.clusters[Cluster]["postgresql-ha"]` and passes the selected profile name
  as `PostgresqlHaProfile`.
- The persistent disk group for that module instance must use the same key as the
  selected profile, because the module reads:
  `persistent_resources.permanentDisks.services["postgresql-ha"][PostgresqlHaProfile]`.
- In this branch, `cluster_name` is profile-specific:
  - `sandbox`: `postgresql-ha`
  - `prod`: `postgresql-ha-prod`
  - `prod red`: `postgresql-ha-red`
- Because of that, the main pgpool service DNS is also profile-specific:
  - `sandbox`: `postgresql-ha-pgpool.postgres.svc.cluster.local:5432`
  - `prod`: `postgresql-ha-prod-pgpool.postgres.svc.cluster.local:5432`
  - `prod red`: `postgresql-ha-red-pgpool.postgres.svc.cluster.local:5432`
- The HA service URI is derived in Terraform from `cluster_name` and `namespace` as
  `${cluster_name}-pgpool.${namespace}.svc.cluster.local:5432`, using `cluster_name`
  exactly as provided in config.
- Vault paths and backend names may still differ between environments; those are separate
  from the Kubernetes service naming and do not have to match `cluster_name`.

## Vault paths and credentials

- `postgresql-ha.vault_path` is the primary Vault path for HA-specific secrets and
  database users.
- `root-user` is read from `secret/<postgresql-ha.vault_path>/root-user`.
- `ha-auth` is read from `postgresql-ha.ha_auth_vault_path` when set; otherwise it
  defaults to `${postgresql-ha.vault_path}/ha-auth`.
- Application DB users are sourced from `secret/<vault_path>/db-users/*`.
- Canonical secret format for one entry `secret/<vault_path>/db-users/<db_key>` is:

```json
{
  "username": "birl",
  "password": "secret",
  "URI": "postgresql-ha-pgpool.postgres.svc.cluster.local:5432",
  "database": "birl"
}
```

- `<db_key>` is the database name to create.
- `payload.username` is the owner username to create/use for that database.
- `payload.password` is the owner password source.
- The module also derives `${payload.username}-rw` and `${payload.username}-ro` roles
  (see `app_db_users`).
- `payload.database` and `payload.URI` are allowed in the canonical secret format, but
  are currently not used by this module's bootstrap logic.
- Applications fetch credentials from the Vault database backend the same way as dynamic
  mode, only from `<vault_backend_path>/static-creds/<db>-rw|ro` (stable username,
  Vault-rotated password) instead of `.../creds/...`.
- In `clusters/*/00_persistent-resources/postgres.tf`, `root-user` is created in the
  active Vault path of the enabled Postgres type. If only `postgresql-ha` is enabled,
  no `postgres` config section is required.

## Bootstrap

Bootstrap SQL is idempotent for database creation. It creates:

- owner role = `payload.username`
- rw role = `${payload.username}-rw`
- ro role = `${payload.username}-ro`
- database = `<db_key>`

The owner password is refreshed from `payload.password`. The rw/ro roles are created if
missing and keep the same stable usernames so the `k8s-vault-postgres-post` static roles
can adopt them.

## pgpool authentication (clear-text pass-through)

pgpool uses a custom `pool_hba.conf` (chart param `pgpool.poolHbaConfiguration`, set when
app DB users exist) with a **MIXED** frontend auth model, first match wins:

- System users pgpool knows via `pgpool_passwd` (`postgres`, `repmgr`/`sr_check`) keep
  `scram-sha-256` (per-user lines first, so their credentials are authenticated locally by
  pgpool and never transit in clear text).
- Everyone else — application users, both static `<db>-rw|ro` AND any dynamic role — falls
  through to the clear-text `password` method (pass-through). For pass-through users pgpool
  relays the client password to the backend instead of storing it in `pgpool_passwd`, so
  Vault can rotate app passwords with no pgpool re-sync.

**No pgpool-sync CronJob (removed).** An earlier design had pgpool store app passwords in
`pgpool_passwd` (the non-pass-through model). Because those stored copies went stale every
time Vault rotated a password, a `pgpool-sync` CronJob had to periodically re-read the
current passwords from Vault and rewrite `pgpool_passwd` (effectively a `kubectl rollout
restart`/reload of pgpool). Clear-text pass-through removes the stored copies entirely, so
there is nothing to keep in sync — the CronJob was deleted and must not be reintroduced.

`scram-sha-256` in `pool_hba` only works for users present in `pgpool_passwd` (the system
users); app users are deliberately NOT loaded there, which is why they must use `password`,
not `scram`. `PGPOOL_AUTHENTICATION_METHOD` stays `scram-sha-256` (the Bitnami container
ONLY accepts `md5`/`scram-sha-256` there — `password` is rejected at startup) and
`enable_pool_hba` stays on. This avoids the earlier scram-vs-pool_hba conflict
(`allow_clear_text_frontend_auth` needs `pool_hba` OFF, which broke the scram backend
connection).

## TLS

TLS is opt-in per profile under `postgresql-ha.<profile>.tls`. Sandbox enables it
with Vault PKI mount `pki-postgres`, signing role `postgres`, and ClusterIssuer
`postgres-sandbox`. Other profiles retain the chart defaults (TLS disabled).

```json
"tls": {
  "enabled": true,
  "enforce": false,
  "pki_mount": "pki-postgres",
  "pki_role": "postgres",
  "issuer_name": "postgres-sandbox"
}
```

Like the ClickHouse module, this module creates a Vault-backed ClusterIssuer and
Certificate resources using the shared cert-manager templates. It does not create
or initialize the Vault PKI engine. Before applying, provision `pki-postgres` with
a CA and role `postgres`, permitting the service and pod DNS names in `certs.tf`.
The role must allow the requested 720h lifetime (configurable with `tls.duration`).
The existing Vault Kubernetes auth role `cert-manager` must permit signing at
`pki-postgres/sign/postgres`; its service-account token is
`sa-<Cluster>-cert-manager`. cert-manager and its CRDs must already be installed.
Issuer names must be unique across profiles in the same Kubernetes cluster.

Certificates are stored in `<cluster_name>-pgpool-tls` and
`<cluster_name>-postgresql-tls`. Helm waits for both Certificates to become Ready.
Both Pgpool and PostgreSQL receive `tls.crt` and `tls.key`. The TLS permissions
init containers use the explicit `bitnamilegacy/os-shell` image override.

Sandbox uses `tls.enforce = false` (the default): TLS is available, but existing HBA rules still
allow non-TLS connections. Clients should use `sslmode=verify-full` with a trusted
CA bundle and a hostname listed in the certificate SANs. Merely enabling server
TLS does not enforce encryption, configure backend identity verification, or
prove that repmgr/streaming replication uses TLS. Those checks and client changes
must precede a subsequent TLS-only HBA rollout. The local Pgpool exporter retains
its loopback connection with `SSLMODE=disable`.

Set `tls.enforce = true` only after migrating clients and verifying replication.
It requires `tls.enabled = true`. This installs HBA rules in both Pgpool and
PostgreSQL that reject non-TLS remote connections for IPv4 and IPv6, including
physical replication. Unix sockets and local PostgreSQL loopback connections
remain available; Pgpool permits the configured root user over loopback for its
exporter. Enforcement also works when no application users exist, retaining
SCRAM rather than enabling password pass-through in that case. This setting
requires encryption; it does not configure client CA/hostname verification.

cert-manager renews certificates (default `tls.renew_before = "48h"`). The chart
copies certificates in init containers, so Secret renewal alone does not update
the running processes' certificate files. Plan controlled pod restarts after
renewal, accounting for the PostgreSQL primary and failover; this module does not
yet automate these restarts. Verify the presented certificate after rotation.

## Storage

The module expects precreated GCE persistent disks and creates matching Kubernetes PV/PVC
resources for the Bitnami chart.

## Connection budget

Connection settings are required in each profile, with no fallback defaults:

| Setting | Production | Sandbox / red |
| --- | --- | --- |
| `postgresql_max_connections` | 200 | 100 |
| `pgpool_num_init_children` | 16 | 32 |
| `pgpool_max_pool` | 4 | 1 |
| PostgreSQL memory request / limit | 1 GiB / 2 GiB | 256 MiB / 512 MiB |

With two Pgpool replicas, cached backend connections can reach 128 per PostgreSQL
server in production and 64 in sandbox/red, leaving headroom for other connections.
Pgpool rollout strategy is hardcoded in locals: `maxSurge=0`, `maxUnavailable=1`.

## Probe configuration

The module now passes through Bitnami `postgresql-ha` probe settings when they are present
in `Settings.clusters[Cluster]["postgresql-ha"][<profile>]`. If a key is omitted, the
chart keeps its own default.

Supported profile keys:

- `postgresql_liveness_probe`
- `postgresql_readiness_probe`
- `postgresql_startup_probe`
- `postgresql_custom_liveness_probe`
- `postgresql_custom_readiness_probe`
- `postgresql_custom_startup_probe`
- `pgpool_liveness_probe`
- `pgpool_readiness_probe`
- `pgpool_startup_probe`
- `pgpool_custom_liveness_probe`
- `pgpool_custom_readiness_probe`
- `pgpool_custom_startup_probe`
- `metrics_enabled`
- `metrics_service_enabled`
- `metrics_service_monitor_enabled`
- `metrics_service_monitor_namespace`
- `metrics_service_monitor_interval`
- `metrics_service_monitor_labels`
- `pgpool_metrics_enabled`
- `pgpool_metrics_image`
- `pgpool_metrics_port`
- `pgpool_metrics_pod_monitor_enabled`
- `pgpool_metrics_pod_monitor_namespace`
- `pgpool_metrics_pod_monitor_interval`
- `pgpool_metrics_pod_monitor_labels`

Default Bitnami values for `postgresql` probes:

- `postgresql.livenessProbe.enabled = true`
- `postgresql.livenessProbe.initialDelaySeconds = 15`
- `postgresql.livenessProbe.periodSeconds = 10`
- `postgresql.livenessProbe.timeoutSeconds = 5`
- `postgresql.livenessProbe.failureThreshold = 6`
- `postgresql.livenessProbe.successThreshold = 1`
- `postgresql.readinessProbe.enabled = true`
- `postgresql.readinessProbe.initialDelaySeconds = 5`
- `postgresql.readinessProbe.periodSeconds = 10`
- `postgresql.readinessProbe.timeoutSeconds = 5`
- `postgresql.readinessProbe.failureThreshold = 6`
- `postgresql.readinessProbe.successThreshold = 1`
- `postgresql.startupProbe.enabled = false`
- `postgresql.startupProbe.initialDelaySeconds = 5`
- `postgresql.startupProbe.periodSeconds = 10`
- `postgresql.startupProbe.timeoutSeconds = 5`
- `postgresql.startupProbe.failureThreshold = 10`
- `postgresql.startupProbe.successThreshold = 1`

Example:

```json
{
  "postgresql-ha": {
    "sandbox": {
      "postgresql_liveness_probe": {
        "enabled": true,
        "initialDelaySeconds": 15,
        "periodSeconds": 30,
        "timeoutSeconds": 5,
        "failureThreshold": 6,
        "successThreshold": 1
      },
      "postgresql_readiness_probe": {
        "enabled": true,
        "initialDelaySeconds": 5,
        "periodSeconds": 30,
        "timeoutSeconds": 5,
        "failureThreshold": 6,
        "successThreshold": 1
      }
    }
  }
}
```

If you need to replace Bitnami's built-in command entirely, use the matching
`*_custom_*_probe` key instead of the standard `*_probe` one.

## Metrics

Bitnami `postgresql-ha` can expose PostgreSQL exporter metrics for Prometheus. In this
module, metrics are controlled from the `postgresql-ha` profile with these keys:

- `metrics_enabled` — enables the `postgres_exporter` sidecar in PostgreSQL pods
- `metrics_image_registry` / `metrics_image_repository` / `metrics_image_tag` — override
  the exporter image when the chart default is not pullable in your registry setup
- `metrics_service_enabled` — creates the internal metrics `Service`
- `metrics_service_monitor_enabled` — creates a Prometheus Operator `ServiceMonitor`
- `metrics_service_monitor_namespace` — namespace for the `ServiceMonitor`
- `metrics_service_monitor_interval` — scrape interval, for example `30s`
- `metrics_service_monitor_labels` — extra labels for `ServiceMonitor` discovery

Recommended values for this repository:

```json
{
  "metrics_enabled": true,
  "metrics_image_registry": "docker.io",
  "metrics_image_repository": "bitnamilegacy/postgres-exporter",
  "metrics_image_tag": "0.17.1-debian-12-r16",
  "metrics_service_enabled": true,
  "metrics_service_monitor_enabled": true,
  "metrics_service_monitor_namespace": "monitoring",
  "metrics_service_monitor_interval": "30s",
  "metrics_service_monitor_labels": {
    "release": "prometheus"
  }
}
```

Notes:

- Bitnami exporter metrics are disabled by default (`metrics.enabled = false`).
- The Bitnami chart exposes metrics on its exporter service port `9187`.
- The upstream chart version in use references
  `docker.io/bitnami/postgres-exporter:0.17.1-debian-12-r16`, but in this repository
  the same tag is available via `docker.io/bitnamilegacy/postgres-exporter`.
- Prometheus Operator CRDs must already exist in the cluster.
- For this repository, `release: prometheus` matches the label pattern already used by
  existing `ServiceMonitor` resources in `monitoring`.

## Pgpool Metrics

The Bitnami `postgresql-ha` chart does not expose a built-in Prometheus exporter for
Pgpool. This module runs the official `pgpool2_exporter` as a **sidecar inside every
pgpool pod** (via the chart's `pgpool.sidecars`), connecting over the pod's loopback
(`127.0.0.1:5432`) rather than through the shared pgpool `Service`. This gives one
metrics target per pgpool replica; an exporter reached only through the Service would
instead sit on a single long-lived connection pinned to whichever pgpool pod it first
landed on, hiding the other replicas.

Supported profile keys:

- `pgpool_metrics_enabled`
- `pgpool_metrics_image`
- `pgpool_metrics_port`
- `pgpool_metrics_pod_monitor_enabled`
- `pgpool_metrics_pod_monitor_namespace`
- `pgpool_metrics_pod_monitor_interval`
- `pgpool_metrics_pod_monitor_labels`

Recommended values for this repository:

```json
{
  "pgpool_metrics_enabled": true,
  "pgpool_metrics_image": "pgpool/pgpool2_exporter:1.2.2",
  "pgpool_metrics_port": 9719,
  "pgpool_metrics_pod_monitor_enabled": true,
  "pgpool_metrics_pod_monitor_namespace": "monitoring",
  "pgpool_metrics_pod_monitor_interval": "30s",
  "pgpool_metrics_pod_monitor_labels": {
    "release": "prometheus"
  }
}
```

Notes:

- The exporter is the official `pgpool/pgpool2_exporter` image from the Pgpool project,
  injected as a sidecar container, and authenticates with the root credentials already
  managed by this module (same secret as `db_bootstrap`/superuser).
- Scraping uses a Prometheus Operator `PodMonitor` (not a `ServiceMonitor`, since there
  is no dedicated exporter Service) named `${cluster_name}-pgpool-exporter`, selecting
  pods by `app.kubernetes.io/instance=${cluster_name}` +
  `app.kubernetes.io/component=pgpool` in `monitoring` by default.
- This only covers pgpool-level state (backend node status/role, health checks,
  replication delay, connection pool saturation). It does not cover: pod/container
  resource usage (CPU/RAM/OOMKilled — use cAdvisor/kube-state-metrics), why a
  connection to pgpool is refused at the Kubernetes level (CrashLoopBackOff, missing
  Endpoints, PVC issues — check pod status/events directly), or Postgres-level
  internals (locks, vacuum, WAL — that's the separate `postgres_exporter` sidecar under
  [Metrics](#metrics) above).

## Backup

Backup code exists only as commented-out draft and is not active.

## Cross-module dependency

`../k8s-vault-postgres-post` holds Vault resources that depend on BOTH the `postgres/`
(CNPG, `../k8s-vault-postgres`) and `postgres-ha/` (this module) backends — it is invoked
twice from `tekton/stage-6/06-postgres/main.tf`, once per backend. Its connections/roles
reference Vault role names `<db>-rw|ro`, while the adopted physical PostgreSQL usernames
can be `${payload.username}-rw|ro`. Changes to db-users, role names, backend paths
(`vault_backend_path`), or `credential_mode` here must be reconciled in
`k8s-vault-postgres-post` (and vice versa). Renaming or removing a backend/role can break
the post module's apply.

## Related

- `../k8s-vault-postgres` — previous working option based on CNPG.
- `../k8s-vault-postgres-post` — configures the Vault database secrets backend (static
  roles by default via `credential_mode`, dynamic optional) that back these users; see the
  cross-module dependency note above.

## Post-deploy verification

After a `postgresql-ha` deploy or re-create, verify that the cluster attached the intended
persistent GCE disks, did not bootstrap an empty database, and still serves the expected
data.

### 1. Verify PV/PVC bindings

The HA module precreates both PVs and PVCs and binds them to explicit GCE disks:

- PV reclaim policy is `Retain`.
- PVC names are `${pv_claim_name_prefix}-<index>`.
- Each PV points to a concrete GCE disk via `volume_handle`.

Useful checks:

```bash
kubectl -n postgres get pvc
kubectl get pv | grep postgresql-ha
kubectl get pv <pv-name> -o yaml
```

In the PV output, verify:

- `spec.csi.volumeHandle` points to the expected GCE disk
- `spec.claimRef.name` points to the expected PVC
- `status.phase` is `Bound`

### 2. Verify the root secret used for psql access

The module creates a Kubernetes secret with the Postgres superuser credentials:

```bash
kubectl -n postgres get secret postgresql-ha-superuser -o jsonpath='{.data.username}' | base64 -d; echo
kubectl -n postgres get secret postgresql-ha-superuser -o jsonpath='{.data.password}' | base64 -d; echo
```

If `root_secret_name` was overridden in config, use that name instead.

### 3. Connect to pgpool and inspect the `birl` database

Run a temporary `psql` client pod:

```bash
kubectl -n postgres run psql-client --rm -it --restart=Never \
  --image=postgres:17 \
  --env="PGPASSWORD=$(kubectl -n postgres get secret postgresql-ha-superuser -o jsonpath='{.data.password}' | base64 -d)" -- \
  psql -h postgresql-ha-pgpool.postgres.svc.cluster.local \
  -U "$(kubectl -n postgres get secret postgresql-ha-superuser -o jsonpath='{.data.username}' | base64 -d)" \
  -d birl
```

Inside `psql`, check the expected tables:

```sql
SELECT count(*) FROM bankaliases;
SELECT count(*) FROM bankfractions;
SELECT count(*) FROM banks;
SELECT count(*) FROM fractions;
```

Expected example output:

```sql
birl=# SELECT count(*) FROM bankaliases;
 count
-------
  1174
(1 row)

birl=# SELECT count(*) FROM bankfractions;
 count
-------
  4786
(1 row)

birl=# SELECT count(*) FROM banks;
 count
-------
  2435
(1 row)

birl=# SELECT count(*) FROM fractions;
 count
-------
  4739
(1 row)
```

If these counts are close to the known-good values and the tables exist, that is a strong
signal that:

- the correct persistent disk was reused
- the database was not reinitialized from scratch
- the application data remained intact

### 4. Optional sanity checks

Useful extra checks from inside `psql`:

```sql
\dt
\du
SELECT current_database();
```

These help confirm that:

- you are connected to `birl`
- the expected roles exist
- the expected tables are present
