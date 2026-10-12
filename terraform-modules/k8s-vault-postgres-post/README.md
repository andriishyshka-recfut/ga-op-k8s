# k8s-vault-postgres-post

Configures the Vault **database secrets engine** for a PostgreSQL cluster: one
connection per application database plus the read-write / read-only roles that
applications consume. Invoked twice from `tekton/stage-6/06-postgres/main.tf` —
once for the CNPG cluster (`postgres` backend, dynamic mode) and once for the
Bitnami `postgresql-ha` cluster (`postgres-ha` backend, static mode).

The set of databases is discovered from the Vault KV list at
`secret/<vault_path>/db-users/*`. Canonical secret format for one entry
`secret/<vault_path>/db-users/<db_key>` is:

```json
{
  "username": "birl",
  "password": "secret",
  "URI": "postgresql-ha-pgpool.postgres:5432",
  "database": "birl"
}
```

Where:

- `<db_key>` is the database name.
- `payload.username` is the logical application owner username.
- `payload.password` is the source password used for static-role adoption.
- `payload.database` and `payload.URI` may be present in the canonical KV secret, but
  are currently not used by this module.

For every `<db_key>` the module creates:

- a connection `<db_key>` on the backend (`vault.tf`, `allowed_roles = [<db_key>-rw, <db_key>-ro]`);
- either **dynamic** roles (`vault_database_secret_backend_role`, `creds/<db_key>-rw|ro`)
  when `credential_mode = "dynamic"`, or **static** roles
  (`vault_database_secret_backend_static_role`, `static-creds/<db_key>-rw|ro`) when
  `credential_mode = "static"`.

Important: Vault role names remain based on `<db_key>`, but the physical PostgreSQL
username used by HA static roles can be based on `payload.username`:

- Vault role name: `<db_key>-rw`, `<db_key>-ro`
- PostgreSQL username: `${payload.username}-rw`, `${payload.username}-ro`

The module is driven by `DbKind`, which must match the cluster config section
name exactly (`postgres` or `postgresql-ha`). For `postgresql-ha`, the caller
passes `PostgresqlHaProfile` and the module reads
`Settings.clusters[Cluster]["postgresql-ha"][PostgresqlHaProfile]`. It then
uses `vault_path`, `vault_backend_path`, `postgres_uri`, and other settings.
For `postgresql-ha`, `postgres_uri` is derived in Terraform from `cluster_name`
and `namespace` as `${cluster_name}-pgpool.${namespace}.svc.cluster.local:5432`
and is no longer configured separately in tfvars.
from that selected profile in `tfvars`.

See `../k8s-vault-postgres-ha/AGENTS.md` for the sibling module that deploys the
chart and bootstraps the roles the static path adopts.

## Where applications get their credentials

Apps do **not** get credentials injected into a Kubernetes Secret by Terraform.
The business apps are **Vault-native**: the pod is told how to reach Vault and
which path to read, and the app logs into Vault (Kubernetes auth) and reads the
credentials itself at runtime. This is what lets a Vault-rotated password be
picked up on reconnect without a redeploy.

The consuming manifests live in the **`k8s-configs`** repo (not here). The pod
gets `VAULT_ADDR` / `VAULT_ROLE` / `VAULT_AUTH_PATH` from annotations, then reads
the DB path from `PSQL_CREDENTIALS_PATH` (Vault DB role) or `PSQL_SECRET_PATH`
(raw KV). `gitops` has nothing to do with this — only `kyverno-policies` and
`monitoring`.

Example — `k8s-configs/base/birl/slip.yaml` (dynamic, on the CNPG `postgres` backend):

```yaml
env:
  - name: VAULT_ADDR
    valueFrom: { fieldRef: { fieldPath: metadata.annotations['vaultAddr'] } }
  - name: VAULT_ROLE
    valueFrom: { fieldRef: { fieldPath: metadata.annotations['vault.hashicorp.com/role'] } }
  - name: VAULT_AUTH_PATH
    valueFrom: { fieldRef: { fieldPath: metadata.annotations['vault.hashicorp.com/auth-path'] } }
  - name: PSQL_SECRET_PATH          # connection metadata (host/port/db)
    value: secret/data/wl/birl/postgres
  - name: PSQL_CREDENTIALS_PATH     # where the app reads user+password
    value: postgres/creds/birl-ro   # dynamic role on the `postgres` backend
```

Reading `postgres/creds/birl-ro` returns a fresh `{username, password}` pair with
a lease. A **static** role on the HA backend is a drop-in: same `{username,
password}` shape, only the path differs — migrating an app is a one-line change:

```yaml
  - name: PSQL_CREDENTIALS_PATH
    value: postgres-ha/static-creds/birl-ro   # static role, stable username, Vault-rotated password
```

`datafix` is the exception — it reads the **raw KV** entry directly
(`PSQL_SECRET_PATH: /secret/data/mw/postgres/db-users/birl`), whose shape is the
canonical KV format above, not the `{username, password}` response returned by the
Vault database backend, so it is *not* a drop-in for either DB-role path.

Each app also needs a Vault policy granting its path — see
`clusters/<cluster>/00_vault-policies/<app>.tf` (e.g. `database/creds/*` +
`sys/leases/renew` for dynamic consumers, or a `secret/.../db-users/<db>` read
for KV consumers).

## Migrating an app from `postgres` (CNPG) to `postgres-ha` — example: `birl`

Both clusters share the same `vault_path` (`mw/postgres`), so they read the same
`db-users` KV with the same passwords. The switch is therefore **not** about
changing passwords — it is about pointing the app at the pgpool host and at the
static-creds path.
Three layers change, in this order:

**1. Vault KV — connection metadata (`secret/wl/birl/postgres`).**
This is the entry `birl` reads via `PSQL_SECRET_PATH: secret/data/wl/birl/postgres`.
It carries the DB host/URI. Repoint it from the CNPG service to pgpool:

```
postgres-rw.postgres:5432   →   postgresql-ha-pgpool.postgres.svc.cluster.local:5432
```

The values are live/external (not in this repo) — edit with `vault kv put`
against the running Vault, not via Terraform.

**2. k8s-configs manifests — the credentials path.**
In `k8s-configs` `base/birl/{slip,draft,base}.yaml`, move the DB-role path from the
dynamic CNPG backend to the static HA backend:

```yaml
  - name: PSQL_CREDENTIALS_PATH
    value: postgres/creds/birl-ro          # was: dynamic role on the `postgres` backend
    # value: postgres-ha/static-creds/birl-ro   # now: static role on the `postgres-ha` backend
```

Same `{username, password}` shape, so no app code change — only the path.

**3. Vault policy — grant the new path.**
The app's Vault token must be allowed to read `postgres-ha/static-creds/birl-*`.
**Which policy to edit depends on the cluster** (this differs — see Known issues):

- **production** — policy `birl-telegram`
  (`clusters/production/00_vault-policies/birl-telegram.tf`, assigned via
  `assignVaultPolicy: ["oidc","birl-telegram"]`). Add the static path alongside the
  existing `postgres/creds/*` grant, same capabilities:
  ```hcl
  path "postgres-ha/static-creds/*" {
    capabilities = ["read","list","create","update"]
  }
  ```
- **sandbox** — the pod uses Vault role `birl` → policy `birl`, which is **not in this
  repo** (maintained manually in Vault). It must be granted the path directly in Vault
  (see Known issues for the exact fix applied).

## Dynamic vs static

| | Dynamic (`creds/<role>`) | Static (`static-creds/<role>`) |
|--|--|--|
| Username | auto-generated, unique per read (`v-…`) | fixed physical role, typically `${payload.username}-rw`/`${payload.username}-ro` |
| Password | random per read | rotated on a schedule (`ALTER USER … PASSWORD`) |
| Lifecycle | `CREATE ROLE` on read, `DROP ROLE` on lease end | role never created/dropped by Vault |
| Lease | yes (TTL) | none |

CNPG uses **dynamic**: its PgBouncer pooler runs an `auth_query` that resolves the
current password (and any freshly-created user) from the database on every
connect, so ephemeral per-lease users work transparently.

`postgresql-ha` uses **static**: pgpool keys its connection pool by `(user, db)`,
so dynamic per-lease usernames cause pool churn and constant backend `CREATE`/`DROP
ROLE`. Stable usernames keep the pool key fixed; Vault rotates only the password.
See `../k8s-vault-postgres-ha/AGENTS.md`.

## Known issues / caveats

- **The `birl` Vault policy is not in IaC (sandbox).** The sandbox `birl` namespace
  authenticates with Vault role `birl` (config `assignVaultPolicy: ["birl"]`), but there
  is no `vault_policy "birl"` anywhere in the repo — it is maintained **manually in Vault**.
  Production instead uses `["oidc","birl-telegram"]`, and `birl-telegram` IS in the repo
  (`clusters/production/00_vault-policies/birl-telegram.tf`).
  **Symptom seen 2026-07-06:** after switching `birl` to the HA backend, the app got
  `403 permission denied` on `GET postgres-ha/static-creds/birl-ro`, because the manual
  `birl` policy still granted only the old `postgres/creds/*` path.
  **Fixed manually** by adding to the `birl` policy in sandbox Vault:
  ```hcl
  path "postgres-ha/static-creds/birl-ro" { capabilities = ["read","list"] }
  path "postgres-ha/static-creds/birl-rw" { capabilities = ["read","list"] }
  ```
  Because this lives only in Vault, it is **lost if Vault is re-provisioned**. Long-term
  fix: codify it as `clusters/sandbox/00_vault-policies/birl.tf` — but first mirror the full
  current policy via `vault policy read birl`, or a `vault_policy "birl"` resource will
  clobber the other grants it already holds.

- **`database/creds/*` is Elasticsearch, not Postgres.** Seen in policies like `vortex`,
  `paste`, `datafix`. It is a **separate** Vault engine (Elasticsearch dynamic creds). Only
  `postgres/creds/*` (CNPG) and `postgres-ha/static-creds/*` (Bitnami HA) are Postgres
  backends — do not "reconcile" `database/creds` into the Postgres paths.

- **Environment drift on the Postgres grant.** As of 2026-07 the `postgres/creds/*` grant
  exists only in production (`birl-telegram.tf`). Sandbox has no `postgres/creds/*` grant at
  all; its Postgres consumers are the manual `birl` policy (above) and `datafix` (raw KV).
  Add a `postgres-ha/static-creds/*` grant in a given cluster only where an app there
  actually consumes the HA backend.

- **`datafix` reads raw KV, not a DB role.** It reads `db-users/birl` via `PSQL_SECRET_PATH`
  (different field shape from DB-role reads), whose passwords already work on HA,
  so no cred-path change is strictly required. But it has **no explicit Postgres host env**,
  so its pgpool host must be found and repointed separately when migrating it to HA.

- **Duplicate path in production `datafix` policy.** `secret/data/mw/minio/sa/datafix_datafix`
  is declared twice in `clusters/production/00_vault-policies/datafix.tf` — harmless, but
  worth removing.
