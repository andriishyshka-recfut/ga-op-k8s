# Vault MongoDB Database Secrets

Terraform module for configuring Vault's MongoDB Database Secrets Engine.

## Highlights

- Configures the Vault database mount, MongoDB connection, dynamic roles, and per-application policies.
- Supports database-level `read` and `readWrite` access and collection-level custom MongoDB roles.
- Reconciles custom roles through a content-versioned Kubernetes Job.
- Supports default credential TTLs with optional per-application overrides.
- Validates module-owned configuration while leaving provider and API constraints to Vault and Kubernetes.

## Configuration examples

Database-level access:

```json
{
  "defaults": {
    "default_ttl_seconds": 900,
    "max_ttl_seconds": 3600
  },
  "applications": {
    "example-app": {
      "databases": {
        "example-db": {
          "role_type": "readWrite"
        }
      }
    }
  }
}
```

Collection-level access:

```json
{
  "defaults": {
    "default_ttl_seconds": 900,
    "max_ttl_seconds": 3600
  },
  "applications": {
    "example-app": {
      "default_ttl_seconds": 1800,
      "max_ttl_seconds": 7200,
      "databases": {
        "example-db": {
          "collections": {
            "orders": {
              "role_type": "readWrite"
            },
            "audit_log": {
              "role_type": "read"
            }
          }
        }
      }
    }
  }
}
```

Each database entry must define either `role_type` or `collections`, but not both.
