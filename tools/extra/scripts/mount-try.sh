#!/usr/bin/env bash
###############################################################################
# mount-try.sh
#==============================
# DESCRIPTION:
#   Attempts to mount a CIFS/SMB share by iterating through a list of SMB
#   protocol versions until one succeeds. Accepts server, share, username,
#   password, and domain via command-line options. Includes common options such as:
#     • security mode (sec)
#     • client‐side ownership (mount_uid, mount_gid)
#     • permission bits (file_mode, dir_mode)
#   Upon a successful mount, prints the exact mount command that worked, shows
#   the mount details, and then runs smbcacls (using the external binary) to
#   display the share’s ACLs. If all tested versions fail, it reports failure
#   and exits with a nonzero code.
#————————————————————
# Usage:
#   sudo ./mount-try.sh -H <server_ip_or_hostname> -S <share_name> \
#                      -u <username> -p <password> [-d <domain>] [-m <mountpoint>]
#
#   Options:
#     -H  Hostname or IP of the SMB/CIFS server (required)
#     -S  Share name on that server (required)
#     -u  Username for authentication (required)
#     -p  Password for authentication (required)
#     -d  Domain or workgroup (optional; defaults to WORKGROUP)
#     -m  Local mount point (optional; defaults to /mnt/cifs_share)
#
# Return Values:
#   0  – Mounted successfully (and exits immediately after success), or
#         already mounted (no action taken)
#   1  – Missing required arguments or all tested SMB versions failed
#————————————————————
# Requirements:
#   • bash
#   • cifs-utils (provides the mount.cifs helper)
#   • smbcacls (from Samba client utilities)
#   • Root privileges (or appropriate sudo permissions) to perform the mount
#
###############################################################################
echo 1

set -uo pipefail
IFS=$'\n\t'

# Default values for optional parameters
DOMAIN="WORKGROUP"
MPOINT="/mnt/cifs_share"
SEC="ntlmssp"

# Avoid collision with readonly UID/GID
MOUNT_UID="1000"
MOUNT_GID="1000"
FILE_MODE="0644"
DIR_MODE="0755"

print_usage() {
    cat << EOF
Usage:
  sudo $0 -H <server_ip_or_hostname> -S <share_name> \\
           -u <username> -p <password> [-d <domain>] [-m <mountpoint>]

Options:
  -H  Hostname or IP of the SMB/CIFS server (required)
  -S  Share name on that server (required)
  -u  Username for authentication (required)
  -p  Password for authentication (required)
  -d  Domain or workgroup (optional; defaults to WORKGROUP)
  -m  Local mount point (optional; defaults to /mnt/cifs_share)
EOF
}

# Parse command-line options
while getopts ":H:S:u:p:d:m:" opt; do
    case "$opt" in
        H) SERVER_HOST="$OPTARG" ;;
        S) SHARE_NAME="$OPTARG" ;;
        u) USER="$OPTARG" ;;
        p) PASS="$OPTARG" ;;
        d) DOMAIN="$OPTARG" ;;
        m) MPOINT="$OPTARG" ;;
        *)
            echo "[-] Invalid option: -$OPTARG"
            print_usage
            exit 1
            ;;
    esac
done

# Verify required arguments are set
if [ -z "${SERVER_HOST:-}" ] || [ -z "${SHARE_NAME:-}" ] \
                                                         || [ -z "${USER:-}" ] || [ -z "${PASS:-}" ]; then
    echo "[-] Missing required arguments."
    print_usage
    exit 1
fi

# Construct the UNC path (//server/share)
SERVER="//${SERVER_HOST}/${SHARE_NAME}"

# Generate sanitized mount point if not explicitly provided
if [[ -z "${MPOINT:-}" || "${MPOINT}" == "/mnt/cifs_share" ]]; then
    # Sanitize server IP by replacing dots with underscores
    SAFE_SERVER="${SERVER_HOST//./_}"

    # Sanitize share name: replace non-alphanumeric with underscores
    SAFE_SHARE=$(echo "${SHARE_NAME}" | sed 's/[^a-zA-Z0-9]/_/g')

    MPOINT="./${SAFE_SERVER}-${SAFE_SHARE}"
    echo "[*] No mount point specified. Using generated mount point: '${MPOINT}'"
fi

# Ensure the mount directory exists
if [ ! -d "${MPOINT}" ]; then
    echo "[*] Creating mount point at '${MPOINT}'..."
    mkdir -p "${MPOINT}"
    if [ $? -ne 0 ]; then
        echo "[-] Failed to create directory '${MPOINT}'. Aborting."
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# NEW: Check if something is already mounted at the desired mount point.
# If so, report and exit without remounting.
# ---------------------------------------------------------------------------
if mountpoint -q "${MPOINT}"; then
    echo "[*] Notice: '${MPOINT}' is already a mounted filesystem. No action taken."
    exit 0
fi

# Common CIFS options (read‐only + credentials + domain + security + ownership + perms)
COMMON_OPTS="ro,username=${USER},password=${PASS},domain=${DOMAIN},sec=${SEC},\
uid=${MOUNT_UID},gid=${MOUNT_GID},file_mode=${FILE_MODE},dir_mode=${DIR_MODE}"

# List of SMB versions to try (in descending order of preference)
VERSIONS=(3.0 2.1 2.0 1.0)

echo "[*] Attempting to mount '${SERVER}' to '${MPOINT}' with various SMB versions..."
for VER in "${VERSIONS[@]}"; do
    echo "[*] Trying with vers=${VER}..."
    # Directly call mount without eval, quoting every variable
    if mount -t cifs "$SERVER" "$MPOINT" -o "$COMMON_OPTS,vers=$VER"; then
        echo "[+] Success: mounted with vers=${VER}."
        echo
        echo "[+] Working mount command:"
        echo "    mount -t cifs '$SERVER' '$MPOINT' -o '$COMMON_OPTS,vers=$VER'"
        echo
        echo "[+] Retrieving ACLs via smbcacls:"
        # Use `command smbcacls` to ensure the external binary is invoked
        command smbcacls -W "$DOMAIN" -U "$USER" --password="$PASS" "$SERVER" ""
        echo
        exit 0
    else
        echo "[-] Failed with vers=${VER}. Trying next version..."
        echo
    fi
done

echo "[!] All tested SMB versions failed (tried: ${VERSIONS[*]})."
exit 1
