variable "Settings" {}
variable "Cluster" {}
variable "VaultAddress" {}

locals {
  gcp_project = var.Settings.gcpProject
  zscaler     = try(var.Settings.zscaler, {})
  vault       = var.VaultAddress

  zscaler_enabled   = try(local.zscaler.enabled, true)
  zscaler_defaults  = try(local.zscaler.defaults, {})
  zscaler_instances = try(local.zscaler.instances, {})

  zscaler_module_defaults = {
    name                              = "zscaler"
    create_service_account_key        = false
    service_account_key_rotation_days = 25
    service_account_id                = "zpa-app-connector"
    service_account_display_name      = null
    service_account_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
    service_account_iam_roles = [
      "roles/compute.viewer",
      "roles/iam.serviceAccountViewer",
    ]
    can_ip_forward              = true
    enable_oslogin              = true
    tags                        = ["zscaler"]
    labels                      = { service = "zscaler" }
    boot_disk_size_gb           = 64
    boot_disk_type              = "pd-balanced"
    automatic_restart           = true
    on_host_maintenance         = "MIGRATE"
    allow_stopping_for_update   = true
    ssh_username                = "admin"
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  zscaler_effective_defaults = merge(local.zscaler_module_defaults, local.zscaler_defaults)

  name               = local.zscaler_effective_defaults.name
  zone               = try(local.zscaler_defaults.zone, var.Settings.bastion_zone)
  region             = join("-", slice(split("-", local.zone), 0, 2))
  primary_network    = try(local.zscaler_defaults.primary_network, var.Settings.vpc_name)
  primary_subnetwork = try(local.zscaler_defaults.primary_subnetwork, try(local.zscaler_defaults.subnetwork, "envoy"))

  create_service_account_key        = local.zscaler_enabled && local.zscaler_effective_defaults.create_service_account_key
  service_account_key_rotation_days = local.create_service_account_key ? local.zscaler_effective_defaults.service_account_key_rotation_days : null
  service_account_id                = local.zscaler_effective_defaults.service_account_id
  service_account_display_name      = local.zscaler_effective_defaults.service_account_display_name
  service_account_scopes            = local.zscaler_effective_defaults.service_account_scopes
  service_account_iam_roles         = local.zscaler_effective_defaults.service_account_iam_roles

  zscaler_instances_effective = local.zscaler_enabled ? {
    for instance in flatten([
      for group_name, group_cfg in local.zscaler_instances : [
        for vm_index in range(try(group_cfg.count_vm, 0)) : merge(local.zscaler_effective_defaults, group_cfg, {
          vm_id              = format("%s-%02d", group_name, vm_index + 1)
          vm_group           = group_name
          vm_index           = vm_index + 1
          private_ip_address = try(group_cfg.private_ip_address[vm_index], null)
        })
      ]
    ]) :
    instance.vm_id => instance
  } : {}

  generated_runtime_startup_script = <<-RHEL9USERDATA
#!/usr/bin/bash
set -euo pipefail

cat >/usr/local/bin/zscaler-provision.sh <<-'EOF'
#!/usr/bin/bash
set -euo pipefail

PROVISIONING_KEY_PATH="/opt/zscaler/var/provision_key"
PROVISIONING_SHA_PATH="/opt/zscaler/var/provision_key.sha256"

export VAULT_ADDR=${local.vault}

VAULT_TOKEN=""
until [[ -n "$${VAULT_TOKEN}" ]]; do
  VAULT_TOKEN="$(vault login -method=gcp -path=gcp-zscaler -token-only role=zscaler-vm || true)"
  [[ -n "$${VAULT_TOKEN}" ]] || sleep 15
done
export VAULT_TOKEN

PROVISIONING_KEY=""
until [[ -n "$${PROVISIONING_KEY}" ]]; do
  PROVISIONING_KEY="$(vault kv get -field=key secret/misc/zscaler/server-keys || true)"
  [[ -n "$${PROVISIONING_KEY}" ]] || sleep 15
done

mkdir -p /opt/zscaler/var

PROVISIONING_SHA="$(printf '%s' "$${PROVISIONING_KEY}" | sha256sum | awk '{print $1}')"
CURRENT_SHA="$(cat "$${PROVISIONING_SHA_PATH}" 2>/dev/null || true)"
NEEDS_REPROVISION="false"

if [[ ! -f "$${PROVISIONING_SHA_PATH}" ]]; then
  NEEDS_REPROVISION="true"
elif [[ "$${CURRENT_SHA}" != "$${PROVISIONING_SHA}" ]]; then
  NEEDS_REPROVISION="true"
fi

if [[ "$${NEEDS_REPROVISION}" == "true" ]]; then
  systemctl stop zpa-connector || true
  find /opt/zscaler/var -maxdepth 1 -type f -name '*.crypt' -delete
  printf '%s\n' "$${PROVISIONING_KEY}" > "$${PROVISIONING_KEY_PATH}"
  chmod 644 "$${PROVISIONING_KEY_PATH}"
  printf '%s\n' "$${PROVISIONING_SHA}" > "$${PROVISIONING_SHA_PATH}"
  systemctl restart zpa-connector
fi

unset PROVISIONING_KEY
unset PROVISIONING_SHA
unset VAULT_TOKEN
EOF

chmod 700 /usr/local/bin/zscaler-provision.sh

cat >/etc/systemd/system/zscaler-provision.service <<'EOF'
[Unit]
Description=Zscaler provisioning
After=network-online.target nss-lookup.target google-guest-agent.service
Wants=network-online.target nss-lookup.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/zscaler-provision.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/zscaler-provision.timer <<'EOF'
[Unit]
Description=Periodic Zscaler provisioning check

[Timer]
OnBootSec=2min
OnUnitActiveSec=15min
RandomizedDelaySec=30s
Persistent=true
Unit=zscaler-provision.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable zscaler-provision.service
systemctl enable zscaler-provision.timer
systemctl start zscaler-provision.service
systemctl start zscaler-provision.timer
	
RHEL9USERDATA
}

data "google_compute_network" "vpc" {
  count = local.zscaler_enabled ? 1 : 0

  name    = local.primary_network
  project = local.gcp_project
}

data "google_compute_subnetwork" "primary" {
  count = local.zscaler_enabled ? 1 : 0

  name    = local.primary_subnetwork
  region  = local.region
  project = local.gcp_project
}
