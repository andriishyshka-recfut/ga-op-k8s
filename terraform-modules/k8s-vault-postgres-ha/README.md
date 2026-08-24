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

## No TLS on pgpool (deliberate)

Passwords transit the pod network in clear text (client->pgpool and pgpool->backend).
Acceptable only for in-cluster traffic guarded by NetworkPolicy; istio is disabled for the
postgres namespace so there is no mesh mTLS.

Because TLS is off, the chart does NOT inject the os-shell volume-permissions init
container — so no os-shell image override is needed. If TLS is ever enabled, the chart will
pull `docker.io/bitnami/os-shell`, which no longer exists post bitnami->bitnamilegacy move,
and would need a `volumePermissions.image` override.

## Storage

The module expects precreated GCE persistent disks and creates matching Kubernetes PV/PVC
resources for the Bitnami chart.

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

Example:

```json
{
  "postgresql-ha": {
    "sandbox": {
      "postgresql_liveness_probe": {
        "enabled": true,
        "initialDelaySeconds": 30,
        "periodSeconds": 10,
        "timeoutSeconds": 5,
        "failureThreshold": 6,
        "successThreshold": 1
      },
      "pgpool_readiness_probe": {
        "enabled": true,
        "initialDelaySeconds": 5,
        "periodSeconds": 5,
        "timeoutSeconds": 5,
        "failureThreshold": 5,
        "successThreshold": 1
      }
    }
  }
}
```

If you need to replace Bitnami's built-in command entirely, use the matching
`*_custom_*_probe` key instead of the standard `*_probe` one.

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
