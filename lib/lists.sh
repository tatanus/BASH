#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : lists.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-10 12:29:41
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-10 12:29:41  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${LISTS_SH_LOADED:-}" ]]; then
    declare -g LISTS_SH_LOADED=true

    ## DIRECTORIES
    REQUIRED_DIRECTORIES=(
        "${DATA_DIR}"
        "${TOOLS_DIR}"
        "${LOGS_DIR}"
    )

    # List of directories
    REQUIRED_DIRECTORIES=(
        "${DATA_DIR}/CONFIG"
        "${DATA_DIR}/TOOLS"
        "${DATA_DIR}/TOOLS/SCRIPTS"
        "${DATA_DIR}/LOGS"
        "${DATA_DIR}/BACKUP"
        "${DATA_DIR}/OUTPUT/RAW"
        "${DATA_DIR}/OUTPUT/PROCESSED"
        "${DATA_DIR}/LOOT/CREDENTIALS"
        "${DATA_DIR}/LOOT/CREDENTIALS/CCACHE"
        "${DATA_DIR}/LOOT/SCREENSHOTS"
        "${DATA_DIR}/LOOT/FILES"
        "${DATA_DIR}/TASKS/PCAP"
        "${DATA_DIR}/TASKS/RECON/NMAP"
        "${DATA_DIR}/TASKS/RECON/SPOONMAP"
        "${DATA_DIR}/TASKS/RECON/SHARES"
        "${DATA_DIR}/TASKS/MITM/BETTERCAP"
        "${DATA_DIR}/TASKS/MITM/MITM6"
        "${DATA_DIR}/TASKS/MITM/RESPONDER"
        "${DATA_DIR}/TASKS/ADCS"
        "${DATA_DIR}/TASKS/COERCION"
        "${DATA_DIR}/TASKS/LDAP"
        "${DATA_DIR}/TASKS/WEB"
        "${DATA_DIR}/TASKS/SMB/NXC"
        "${DATA_DIR}/TASKS/SMB/E4L"
        "${DATA_DIR}/TASKS/SMB/KERBEROAST"
        "${DATA_DIR}/TASKS/CISCO/PHONES"
        "${DATA_DIR}/TASKS/CISCO/SIET"
        "${DATA_DIR}/TASKS/BLOODHOUND"
        "${DATA_DIR}/TASKS/VULN_SCAN/MSF"
    )

    NECESSARY_ENGAGEMENT_FILES=(
        "${DATA_DIR}/targets.txt"
        "${DATA_DIR}/excludes.txt"
    )

    ## DOT FILES
    DOT_FILES=(
        "bashrc"
        "profile"
        "bash_profile"
        "tmux.conf"
        "screenrc"
    )

    ## DOT FILES
    BASH_DOT_FILES=(
        "bash_path"
        "bash_env"
        "path_env"
        "bash_aliases"
        "screen_aliases"
        "tmux_aliases"
        "tgt_aliases"
        "bash_prompt"
        "bash_prompt_funcs"
        "bash-preexec.sh"
        "logging.sh"
        "screenshot.sh"
        "capture_traffic.sh"
    )

    ## DOT FILES
    PENTEST_FILES=(
        "pentest.alias"
        "pentest.env"
        "pentest.keys"
    )

    # Define the list of configuration files to copy
    TOOL_CONFIG_FILES=(
        "tools/config/msf.config:${HOME}/.msf4/config"
        "tools/config/cme.conf:${HOME}/.cme/cme.conf"
        "tools/config/nxc.conf:${HOME}/.nxc/nxc.conf"
        "tools/config/Responder.conf:${TOOLS_DIR}/Responder/Responder.conf"
        "tools/config/spoonmap.config.json:${TOOLS_DIR}/spoonmap/config.json"
    )

    ## APT-GET PACKAGES
    APT_PACKAGES=(
        "aircrack-ng"
        "apache2"
        "autoconf"
        "automake"
        "autotools-dev"
        "bat"
        "bison"
        "build-essential"
        "cargo"
        "cifs-utils"
        "curl"
        "dirb"
        "dirmngr"
        "dnsenum"
        "dnsrecon"
        "dos2unix"
        "ethtool"
        "fzf"
        "gcc"
        "gcc-x86-64-linux-gnux32"
        "gdebi-core"
        "git"
        "gnupg2"
        "grepcidr"
        "g++"
        "hcxdumptool"
        "hcxtools"
        "hydra"
        "icu-devtools"
        "ifzf"
        "jq"
        "krb5-config"
        "krb5-user"
        "lcov"
        "ldap-utils"
        "letsencrypt"
        "libasound2t64"
        "libasound2-dev"
        "libbz2-dev"
        "libcommon-sense-perl"
        "libffi-dev"
        "libgdbm-dev"
        "libgmpxx4ldbl"
        "libgmp-dev"
        "libicu-dev"
        "libjson-perl"
        "libjson-xs-perl"
        "libkrb5-dev"
        "libldap2-dev"
        "libltdl7"
        "libltdl-dev"
        "liblzma-dev"
        "libncurses5-dev"
        "libnetfilter-queue-dev"
        "libnss3-dev"
        "libpcap-dev"
        "libpq5"
        "libpq-dev"
        "libreadline-dev"
        "libsasl2-dev"
        "libserf-1-1"
        "libsmbclient-dev"
        "libsqlite3-dev"
        "libssl-dev"
        "libtool"
        "libtypes-serialiser-perl"
        "libusb-1.0-0-dev"
        "libutf8proc2"
        "libxml2-dev"
        "libxml2-utils"
        "libxslt1-dev"
        "libyaml-dev"
        "m4"
        "macchanger"
        "make"
        "masscan"
        "maven"
        "medusa"
        "mingw-w64"
        "mlocate"
        "mono-mcs"
        "nbtscan"
        "ncat"
        "net-tools"
        "nmap"
        "phantomjs"
        "postgresql"
        "postgresql-contrib"
        "proxychains4"
        "python3-dev"
        "python3-pip"
        "python3-venv"
        "readline-common"
        "redis"
        "ruby-full"
        "rustc"
        "samba"
        "screen"
        "smbclient"
        "snmp"
        "sqlite3"
        "ssl-cert"
        "sysstat"
        "tmux"
        "tox"
        "traceroute"
        "tshark"
        "unzip"
        "valgrind"
        "vim"
        "wifite"
        "zlib1g-dev"
    )

    ## PYTHON LIBRARIES
    PIP_PACKAGES=(
        "netifaces"
        "aiowinreg"
        "ldapdomaindump"
        "minidump"
        "minikerberos"
        "msldap"
        "setuptools"
        "setuptools_rust"
        "twisted"
        "winacl"
        "mdv"
    )

    ## PIPX PACKAGES
    PIPX_PACKAGES=(
        "git+https://github.com/dirkjanm/adidnsdump#egg=adidnsdump"
        "git+https://github.com/zer1t0/certi"
        "git+https://github.com/ly4k/Certipy"
        "coercer"
        "lsassy"
        "git+https://github.com/blacklanternsecurity/MANSPIDER"
        "mitm6"
        "git+https://github.com/Pennyw0rth/NetExec"
        "pypykatz"
        "https://github.com/ShawnDEvans/smbmap"
    )

    ## GO TOOLS
    GO_TOOLS=(
        "github.com/bettercap/bettercap@latest"
        "github.com/sensepost/gowitness@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/ropnop/kerbrute@latest"
        "github.com/lkarlslund/ldapnomnom@latest"
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    )

    # RUBY TOOLS
    RUBY_GEMS=(
        "nori -v 2.6.0" #temp fix until Ruby is upgraded
        "evil-winrm"
    )

    ## TOOLS to APP TEST
    ## The command should return an exit status of 0 if the application is installed
    declare -A APP_TESTS=(
          ["bettercap"]="bettercap -h"
          ["certi"]="certi.py -h"
          ["certipy"]="certipy -h"
          ["GoogleChrome"]="google-chrome --version"
          ["gowitness"]="gowitness -h"
          ["ldapdomaindump"]="ldapdomaindump -h"
          ["ldapnomnom"]="ldapnomnom -h"
          ["lsassy"]="lsassy -h"
          ["masscan"]="masscan --ping 127.0.0.1"
          ["mitm6"]="mitm6 -h"
          ["nmap"]="nmap --version"
          ["pypykatz"]="pypykatz -h"
          ["secretsdump"]="secretsdump.py -h"
          ["tshark"]="tshark -h"
    )

    ###################################################################
    # MENUS
    ###################################################################

    # Array for Setup_Environment functions
    ENVIRONMENT_MENU_ITEMS=(
        "Undo_Setup_Dot_Files"

        "Setup_Directories"
        "Setup_Necessary_Files"
        "Setup_Dot_Files"
        "Setup_Cron_Jobs"

        "Setup_Docker"
        "Setup_Msf_Scripts"
        "Setup_Support_Scripts"
        "Fix_Dns"

        "_Apt_Update"
        "_Install_Missing_Apt_Packages"
        "_Install_Python"
        "_Install_Python_Libs"
        "_Install_Go"
        "_Fix_Old_Python"
    )

    # Array for FullSetup tasks
    SETUP_MENU_ITEMS=(
        "Setup Environment"
        "Edit Config Files"
        "Install Tools"
        "Test Tool Installs"
        "Pentest Menu"
    )

    CONFIG_MENU_ITEMS=(
        "Edit config.sh"
        "Edit pentest.env"
        "Edit pentest.keys"
        "Edit pentest.alias"
    )

    # Array for Install_Tools functions
    INSTALL_TOOLS_MENU_ITEMS=(
        # INSTALL ANY IN-HOUSE TOOLS
        "_Install_Inhouse_Tools"

        # INSTALL PIPX TOOLS FROM LIST
        "_Install_Pipx_Tools"

        # INSTALL GO TOOLS FROM LIST
        "_Install_Go_Tools"

        # INSTALL RUBY GEMS
        "_Install_Ruby_Gems"
    )

#    PENTEST_MENU_ITEMS=(
#        "run_recon.sh"
#        "run_get_dns.sh"
#        "run_dehashed.sh"
#        "run_pre2k_unauth.sh"
#
#        "run_spoonmap.sh"
#        "parse_spoonmap.sh"
#        "find_spoonmap_exploits.sh"
#
#        "run_udp_nmap.sh"
#        "run_nfs_scan.sh"
#        "run_smb.sh"
#        "run_defaultcreds.sh"
#        "run_ciscophones.sh"
#
#        "run_aquatone.sh"
#        "run_gowitness.sh"
#        "run_httpx.sh"
#        "run_nuclei.sh"
#        "run_gobuster.sh"
#
#        "run_msf_scripts.sh"
#        "run_jexboss.sh"
#    )
fi
