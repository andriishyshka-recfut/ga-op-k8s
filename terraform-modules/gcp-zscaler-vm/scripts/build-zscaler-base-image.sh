#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  build-zscaler-base-image.sh <project-id> <zone> <builder-name> <image-name> <subnet>

Example:
  ./scripts/build-zscaler-base-image.sh ardent-rarity-239115 us-east4-b zscaler-base-image-builder zscaler-base-20260609 envoy

Required positional arguments:
  project-id    GCP project that will own the VM and image
  zone          Compute Engine zone for the temporary builder VM
  builder-name  Name for the temporary VM and its boot disk
  image-name    Name for the resulting custom image
  subnet        Existing subnetwork name for nic0

Optional environment variables:
  MACHINE_TYPE=e2-standard-4
  SOURCE_IMAGE=projects/rhel-cloud/global/images/rhel-9-v20240709
  BOOT_DISK_SIZE_GB=64
  NETWORK_TAGS=zscaler
  SERVICE_ACCOUNT_EMAIL=<email>
  IMAGE_FAMILY=zscaler-base
  IMAGE_STORAGE_LOCATION=us
  STARTUP_SCRIPT_PATH=<defaults to ./scripts/zscaler-base-image-build-startup.sh relative to this module>
EOF
}

if [[ $# -lt 5 ]]; then
  usage
  exit 1
fi

PROJECT_ID="$1"
ZONE="$2"
BUILDER_NAME="$3"
IMAGE_NAME="$4"
SUBNET="$5"

MACHINE_TYPE="${MACHINE_TYPE:-e2-standard-4}"
SOURCE_IMAGE="${SOURCE_IMAGE:-projects/rhel-cloud/global/images/rhel-9-v20240709}"
BOOT_DISK_SIZE_GB="${BOOT_DISK_SIZE_GB:-64}"
NETWORK_TAGS="${NETWORK_TAGS:-zscaler}"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_EMAIL:-}"
IMAGE_FAMILY="${IMAGE_FAMILY:-zscaler-base}"
IMAGE_STORAGE_LOCATION="${IMAGE_STORAGE_LOCATION:-us}"
STARTUP_SCRIPT_PATH="${STARTUP_SCRIPT_PATH:-${SCRIPT_DIR}/zscaler-base-image-build-startup.sh}"
DISK_NAME="${BUILDER_NAME}"

SOURCE_IMAGE_LABEL="${SOURCE_IMAGE##*/}"

if [[ ! -f "${STARTUP_SCRIPT_PATH}" ]]; then
  echo "Startup script not found: ${STARTUP_SCRIPT_PATH}" >&2
  exit 1
fi

create_cmd=(
  gcloud compute instances create "${BUILDER_NAME}"
  --project="${PROJECT_ID}"
  --zone="${ZONE}"
  --machine-type="${MACHINE_TYPE}"
  --subnet="${SUBNET}"
  --create-disk="auto-delete=yes,boot=yes,device-name=${DISK_NAME},image=${SOURCE_IMAGE},mode=rw,size=${BOOT_DISK_SIZE_GB},type=pd-balanced"
  --metadata-from-file="startup-script=${STARTUP_SCRIPT_PATH}"
  --tags="${NETWORK_TAGS}"
)

if [[ -n "${SERVICE_ACCOUNT_EMAIL}" ]]; then
  create_cmd+=(--service-account="${SERVICE_ACCOUNT_EMAIL}")
fi

echo "Creating base-image builder VM ${BUILDER_NAME}..."
echo "Using source image: ${SOURCE_IMAGE}"
"${create_cmd[@]}"

cat <<EOF

Builder VM started.
Wait until the startup script finishes, checking for this:

  gcloud compute instances get-serial-port-output ${BUILDER_NAME} --project=${PROJECT_ID} --zone=${ZONE} --port=1 | grep ZSCALER_BASE_IMAGE_BUILD_READY

Wait when ready, then run:

  gcloud compute instances stop ${BUILDER_NAME} --project=${PROJECT_ID} --zone=${ZONE}

  gcloud compute images create ${IMAGE_NAME} \\
    --project=${PROJECT_ID} \\
    --source-disk=${DISK_NAME} \\
    --source-disk-zone=${ZONE} \\
    --family=${IMAGE_FAMILY} \\
    --labels=source_image=${SOURCE_IMAGE_LABEL} \\
    --storage-location=${IMAGE_STORAGE_LOCATION} \\
    --description='${SOURCE_IMAGE}'

Optional cleanup after the image is created:

  gcloud compute instances delete ${BUILDER_NAME} --project=${PROJECT_ID} --zone=${ZONE}
EOF
