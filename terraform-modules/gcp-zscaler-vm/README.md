# gcp-zscaler-vm

Lightweight Terraform module for creating one or more GCP VMs suitable as a base for Zscaler workloads.

This module intentionally keeps scope small:

- creates one or more `google_compute_instance` resources in a single zone
- always reserves a public IP
- always reserves the configured private IP on the VM network interface
- always creates the `zpa-app-connector` service account and grants `roles/iam.serviceAccountTokenCreator` on that service account to itself
- supports bootstrap via `user_data` or `startup_script`
- injects SSH key into instance metadata when provided
- uses existing VPC network and subnetwork
- boots VMs from a dedicated Zscaler base image
- reads its runtime config from `Settings.zscaler`

Config structure:
- `Settings.zscaler.enabled` controls whether this module does anything at all; when set to `false`, it creates no Zscaler VMs, IP addresses, service account resources, or related network lookups
- `Settings.zscaler.defaults` holds shared defaults for all Terraform-managed Zscaler VMs
- `Settings.zscaler.instances` holds per-group definitions for Terraform-managed Zscaler VMs; each group expands into `count_vm` VMs and inherits omitted fields from `defaults`
- `Settings.zscaler.predefined_private_ip_address` is not consumed by this module; other stacks may still use it to track already existing Zscaler host IPs as `/32`

It does not create:

- VPC / subnetworks
- firewall rules
- autoscaling / managed instance groups
- ZPA connector groups or provisioning keys

## Example

```hcl
module "zscaler_vm" {
  source = "../../terraform-modules/gcp-zscaler-vm"

  Settings     = var.Settings
  Cluster      = var.Cluster
  VaultAddress = var.VaultAddress
}
```

Example `config.tfvars.json` block:

```jsonc
"Settings": {
  "zscaler": {
    "enabled": true,
    "defaults": {
      "name": "zscaler",
      "zone": "us-east4-b",
      "machine_type": "e2-standard-4",
      "primary_network": "vpc",
      "primary_subnetwork": "envoy",
      // Required: the prebuilt Zscaler base image used to boot managed VMs.
      "zscaler_image": "projects/<project-id>/global/images/<base-image-name>",
      "create_service_account_key": true,
      "service_account_key_rotation_days": 30,
      "service_account_id": "zpa-app-connector",
      "enable_oslogin": true,
      "tags": ["zscaler"],
      "labels": {
        "service": "zscaler"
      }
    },
    "predefined_private_ip_address": ["172.19.0.7"],
    "instances": {
      "main": {
        "count_vm": 2,
        // Used as the Zscaler host IPs, reserved on nic0 and exposed to shared allowlists as /32.
        "private_ip_address": ["172.19.0.13", "172.19.0.14"]
      },
      "test": {
        "count_vm": 1,
        "private_ip_address": ["172.19.0.15"]
      }
    }
  }
}
```

Public IP behavior:
- the module creates a new reserved public IP for every VM and attaches it to the VM network interface
- for grouped instances, the default public IP naming follows the VM naming convention, for example `zscaler-main-01-vm-public-ip`

Private IP behavior:
- `private_ip_address` is the source of truth for the Zscaler host IP used by other stacks as `/32`
- every VM created by `count_vm` must have a matching `private_ip_address`, otherwise Terraform fails during plan/apply
- the module reserves each `private_ip_address` on the VM network interface and does not fall back to an auto-assigned internal IP

VMs are created with one network interface:
- `nic0`: `primary_network` / `primary_subnetwork`

Bootstrap behavior:
- if `user_data` is set, it wins
- otherwise, if `startup_script` is set, it is used
- otherwise, the module generates a metadata startup script that installs a `systemd` oneshot service for runtime provisioning
- the `zscaler-provision.service` unit authenticates to Vault via GCP auth, reads `secret/misc/zscaler/server-keys` field `key`, writes `/opt/zscaler/var/provision_key`, and restarts the connector
- the first boot initializes `/opt/zscaler/var/provision_key` and `/opt/zscaler/var/provision_key.sha256`
- a `zscaler-provision.timer` re-checks Vault every 15 minutes and reprovisions only when the key hash changes
- package installation for the base image lives only in [scripts/zscaler-base-image-build-startup.sh](./scripts/zscaler-base-image-build-startup.sh)

Service account behavior:
- the module always creates a dedicated VM service account
- default `service_account_id` is `zpa-app-connector`
- default `create_service_account_key` is `false`
- if `create_service_account_key = true`, the module creates a JSON key for the module-managed VM service account
- default `service_account_key_rotation_days` is `25`
- if `service_account_key_rotation_days` is a number, Terraform rotates the JSON key on the next `apply` after that interval elapses
- if `service_account_key_rotation_days = null`, automatic Terraform-driven key rotation is disabled
- if `create_service_account_key = false`, no JSON key is created and workloads running on the VM are expected to use GCP Application Default Credentials (ADC)
- the module attaches `google_service_account.vm.email` to the VM
- the module grants `roles/iam.serviceAccountTokenCreator` on the created service account to itself so `vault login -method=gcp` can use GCP IAM auth from inside the VM
- the module does not grant any project-level IAM roles; any additional project permissions must be managed elsewhere

Outputs related to service account auth:
- if `create_service_account_key = true`, the created JSON key is still written to Terraform state after a successful `apply` of the `06-vm` stack

Vault GCP auth integration:
- the module configures `vault_gcp_auth_backend` at `auth/gcp-zscaler` and the `zscaler-vm` role for Zscaler VMs
- ADC is the preferred default for that backend
- when `Settings.zscaler.defaults.create_service_account_key = false` or is omitted, the Vault GCP auth backend is configured without `credentials`, so Vault uses ADC
- when `Settings.zscaler.defaults.create_service_account_key = true`, the module passes the created service account key JSON directly to Vault as `credentials`
- Zscaler/Vault credentials must not be stored in local `Settings.zscaler.defaults` values such as `vault_gcp_auth_backend_credentials`
- `bound_service_accounts` is set to `google_service_account.vm.email`

Module defaults:
- `name = "zscaler"`
- `service_account_id = "zpa-app-connector"`
- `can_ip_forward = true`
- `enable_oslogin = true`
- `tags = ["zscaler"]`
- `labels = { service = "zscaler" }`
- `boot_disk_size_gb = 64`
- `boot_disk_type = "pd-balanced"`
- `automatic_restart = true`
- `on_host_maintenance = "MIGRATE"`
- `allow_stopping_for_update = true`
- `ssh_username = "admin"`
- `enable_secure_boot = false`
- `enable_vtpm = true`
- `enable_integrity_monitoring = true`

Managed instance names are created as `<defaults.name>-<instance-id>-vm`.
For grouped instances, `<instance-id>` is `<group>-<zero-padded-index>`, for example `zscaler-main-01-vm` or `zscaler-test-01-vm`.

## Base Image Workflow

This repo includes a helper startup script at [scripts/zscaler-base-image-build-startup.sh](./scripts/zscaler-base-image-build-startup.sh) and a thin `gcloud` wrapper at [scripts/build-zscaler-base-image.sh](./scripts/build-zscaler-base-image.sh).

Suggested flow:

Default values inside `./scripts/build-zscaler-base-image.sh`:

```bash
MACHINE_TYPE="e2-standard-4"
SOURCE_IMAGE="projects/rhel-cloud/global/images/rhel-9-v20240709"
BOOT_DISK_SIZE_GB="64"
NETWORK_TAGS="zscaler"
IMAGE_FAMILY="zscaler-base"
IMAGE_STORAGE_LOCATION="us"
```

Set shell variables once for the examples below when you want to override defaults or make the commands copy-paste ready:

```bash
PROJECT_ID="ardent-rarity-239115"
ZONE="us-east4-b"
BUILDER_VM_NAME="zscaler-base-image-builder"
BASE_IMAGE_NAME="zscaler-base-20260609"
PRIMARY_SUBNETWORK="envoy"
ZSCALER_VM_NAME="zscaler-main-01-vm"
SOURCE_IMAGE="projects/rhel-cloud/global/images/rhel-9-v20240709"
```

`SOURCE_IMAGE` is passed explicitly to the build script when you want to override the built-in default. The script does not read it from `config.tfvars.json`.

1. Create a temporary builder VM from `$SOURCE_IMAGE`:

   ```bash
   cd terraform-modules/gcp-zscaler-vm

   SOURCE_IMAGE="$SOURCE_IMAGE" \
   ./scripts/build-zscaler-base-image.sh \
     "$PROJECT_ID" \
     "$ZONE" \
     "$BUILDER_VM_NAME" \
     "$BASE_IMAGE_NAME" \
     "$PRIMARY_SUBNETWORK"
   ```

2. Wait for the startup script to finish installing `vault` and `zpa-connector`.
   You can confirm completion by checking serial console output for `ZSCALER_BASE_IMAGE_BUILD_READY`:

   ```bash
   gcloud compute instances get-serial-port-output "$BUILDER_VM_NAME" \
     --project="$PROJECT_ID" \
     --zone="$ZONE" \
     --port=1 | grep ZSCALER_BASE_IMAGE_BUILD_READY
   ```
3. Stop the builder VM.
4. Create a custom image from its boot disk.
5. Point `Settings.zscaler.defaults.zscaler_image` at the new image.

To re-provision an existing Zscaler VM later without recreating it:

```bash
gcloud compute ssh "$ZSCALER_VM_NAME" \
  --project="$PROJECT_ID" \
  --zone="$ZONE" \
  --command='sudo systemctl restart zscaler-provision.service'
```

Keep secrets and per-machine enrollment out of the image. The module's metadata startup script now installs a boot-time provisioning service, and that service handles Vault auth, provisioning key placement, and connector restart when a real Zscaler VM boots.
