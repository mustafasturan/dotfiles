#!/bin/bash
set -euo pipefail

# ===== Configurable defaults =====
SNAPSHOT_ROOT="/"
INCLUDE_BTRFS_HOME=false
EXCLUDE_PATHS=("/home/user/Downloads" "/tmp")

SCHEDULE_HOURLY=false
SCHEDULE_DAILY=true
SCHEDULE_WEEKLY=true
SCHEDULE_MONTHLY=false
SCHEDULE_BOOT=true

COUNT_HOURLY=0
COUNT_DAILY=7
COUNT_WEEKLY=4
COUNT_MONTHLY=0
COUNT_BOOT=10

function err() {
  echo "Error: $*" >&2
  exit 1
}

function prompt_confirm() {
  # Usage: prompt_confirm "Message"
  while true; do
    read -rp "$1 [y/n]: " yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

function detect_root_partition() {
  findmnt -n -o SOURCE "$SNAPSHOT_ROOT" || err "Failed to detect root device"
}

function detect_fstype() {
  findmnt -n -o FSTYPE "$SNAPSHOT_ROOT" || err "Failed to detect filesystem type"
}

function install_timeshift() {
  if ! command -v timeshift &>/dev/null; then
    echo "Timeshift is not installed."
    if prompt_confirm "Install Timeshift now?"; then
      sudo pacman -Sy --noconfirm timeshift
    else
      err "Timeshift installation declined, exiting."
    fi
  else
    echo "Timeshift is already installed."
  fi
}

function configure_timeshift_json() {
  local snapshot_device=$1
  local fs_type=$2

  local btrfs_mode=false
  [ "$fs_type" = "btrfs" ] && btrfs_mode=true

  local excludes_json
  excludes_json=$(printf '"%s",' "${EXCLUDE_PATHS[@]}")
  excludes_json="[${excludes_json%,}]"

  echo "Configuring /etc/timeshift.json with the following settings:"
  cat <<EOF
  Snapshot device: $snapshot_device
  Filesystem type: $fs_type
  Btrfs mode: $btrfs_mode
  Include btrfs home: $INCLUDE_BTRFS_HOME
  Excluded paths: ${EXCLUDE_PATHS[*]}
  Schedules:
    Hourly: $SCHEDULE_HOURLY (keep $COUNT_HOURLY)
    Daily: $SCHEDULE_DAILY (keep $COUNT_DAILY)
    Weekly: $SCHEDULE_WEEKLY (keep $COUNT_WEEKLY)
    Monthly: $SCHEDULE_MONTHLY (keep $COUNT_MONTHLY)
    Boot: $SCHEDULE_BOOT (keep $COUNT_BOOT)
EOF

  if prompt_confirm "Proceed with this configuration?"; then
    sudo tee /etc/timeshift.json > /dev/null <<EOF
{
  "backup_device_uuid": null,
  "parent_device_uuid": null,
  "do_first_run": false,
  "btrfs_mode": $btrfs_mode,
  "schedule_monthly": $SCHEDULE_MONTHLY,
  "schedule_weekly": $SCHEDULE_WEEKLY,
  "schedule_daily": $SCHEDULE_DAILY,
  "schedule_hourly": $SCHEDULE_HOURLY,
  "schedule_boot": $SCHEDULE_BOOT,
  "count_monthly": $COUNT_MONTHLY,
  "count_weekly": $COUNT_WEEKLY,
  "count_daily": $COUNT_DAILY,
  "count_hourly": $COUNT_HOURLY,
  "count_boot": $COUNT_BOOT,
  "include_btrfs_home": $INCLUDE_BTRFS_HOME,
  "snapshot_device": "$snapshot_device",
  "snapshot_root": "$SNAPSHOT_ROOT",
  "exclude": $excludes_json,
  "parent_device": "$snapshot_device"
}
EOF
    echo "Configuration saved to /etc/timeshift.json"
  else
    err "Configuration declined, exiting."
  fi
}

function enable_timeshift_service() {
  local fs_type=$1

  if [ "$fs_type" = "btrfs" ]; then
    echo "Enabling timeshift.service for BTRFS snapshots..."
    sudo systemctl enable --now timeshift.service
  else
    echo "Enabling timeshift.timer for RSYNC snapshots..."
    sudo systemctl enable --now timeshift.timer
  fi
}

# ===== Main =====

echo "Starting Timeshift setup..."

# ===== Early check for existing Timeshift =====
if command -v timeshift &>/dev/null; then
  echo "Timeshift is already installed."
  if prompt_confirm "Do you want to take an on-demand Timeshift snapshot now and exit?"; then
    echo "Taking on-demand Timeshift snapshot..."
    sudo timeshift --create --comments "On-demand snapshot from setup script" --tags O
  fi
fi

detected_device=$(detect_root_partition)
echo "Detected root partition: $detected_device"
if prompt_confirm "Use detected device '$detected_device' for snapshots?"; then
  SNAPSHOT_DEVICE=$detected_device
else
  read -rp "Enter snapshot device (e.g. /dev/sdaX): " input_device
  SNAPSHOT_DEVICE=$input_device
fi

detected_fs=$(detect_fstype)
echo "Detected filesystem type: $detected_fs"
if ! prompt_confirm "Is this correct?"; then
  read -rp "Enter filesystem type (e.g. ext4, btrfs): " input_fs
  detected_fs=$input_fs
fi

install_timeshift
configure_timeshift_json "$SNAPSHOT_DEVICE" "$detected_fs"
enable_timeshift_service "$detected_fs"

echo "Timeshift setup complete! You can manage snapshots with 'sudo timeshift'."
