#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : lists.sh
# DESCRIPTION : Contains predefined lists and mappings used in the Bash
#               automation framework.
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

    # =============================================================================
    # VALIDATION
    # =============================================================================
    # Validate essential environment variables
    : "${DATA_DIR:?Environment variable DATA_DIR is not set or empty.}"
    : "${ENGAGEMENT_DIR:?Environment variable ENGAGEMENT_DIR is not set or empty.}"
    : "${TOOLS_DIR:?Environment variable TOOLS_DIR is not set or empty.}"

    # =============================================================================
    # REQUIRED DIRECTORIES
    # =============================================================================

    # Directories used for pentest workflows
    PENTEST_REQUIRED_DIRECTORIES=(
        "${DATA_DIR}/TOOLS"
        "${DATA_DIR}/TOOLS/SCRIPTS"
        "${DATA_DIR}/LOGS"
    )

    # Engagement-specific directories
    ENGAGEMENT_REQUIRED_DIRECTORIES=(
        "${ENGAGEMENT_DIR}/BACKUP"
        "${ENGAGEMENT_DIR}/LOOT/CREDENTIALS"
        "${ENGAGEMENT_DIR}/LOOT/CREDENTIALS/CCACHE"
        "${ENGAGEMENT_DIR}/LOOT/CREDENTIALS/FILES"
        "${ENGAGEMENT_DIR}/LOOT/SCREENSHOTS"
        "${ENGAGEMENT_DIR}/LOOT/FILES"
        "${ENGAGEMENT_DIR}/RECON"
        "${ENGAGEMENT_DIR}/OUTPUT"
        "${ENGAGEMENT_DIR}/OUTPUT/TEE"
        "${ENGAGEMENT_DIR}/OUTPUT/PCAP"
        "${ENGAGEMENT_DIR}/OUTPUT/PORTSCAN"
        "${ENGAGEMENT_DIR}/OUTPUT/PORTSCAN/NMAP"
        "${ENGAGEMENT_DIR}/OUTPUT/PORTSCAN/SPOONMAP"
        "${ENGAGEMENT_DIR}/OUTPUT/MITM"
        "${ENGAGEMENT_DIR}/OUTPUT/ADCS"
        "${ENGAGEMENT_DIR}/OUTPUT/COERCION"
        "${ENGAGEMENT_DIR}/OUTPUT/LDAP"
        "${ENGAGEMENT_DIR}/OUTPUT/WEB"
        "${ENGAGEMENT_DIR}/OUTPUT/SMB"
        "${ENGAGEMENT_DIR}/OUTPUT/CISCO"
        "${ENGAGEMENT_DIR}/OUTPUT/BLOODHOUND"
        "${ENGAGEMENT_DIR}/OUTPUT/MSF"
        "${ENGAGEMENT_DIR}/SHARES"
        "${ENGAGEMENT_DIR}/SHARES/NFS"
        "${ENGAGEMENT_DIR}/SHARES/SMB"
    )

    # Necessary engagement files
    NECESSARY_ENGAGEMENT_FILES=(
        "${ENGAGEMENT_DIR}/targets.txt"
        "${ENGAGEMENT_DIR}/excludes.txt"
    )

    # =============================================================================
    # CONFIGURATION FILES
    # =============================================================================

    TOOL_CONFIG_FILES=(
        "tools/config/msfconsole.rc:${HOME}/.msf4/config"
        "tools/config/cme.conf:${HOME}/.cme/cme.conf"
        "tools/config/nxc.conf:${HOME}/.nxc/nxc.conf"
        "tools/config/Responder.conf:${TOOLS_DIR}/Responder/Responder.conf"
        "tools/config/spoonmap.config.json:${TOOLS_DIR}/spoonmap/config.json"
    )

    # =============================================================================
    # DOT FILES
    # =============================================================================

    COMMON_DOT_FILES=(
        "bashrc"
        "profile"
        "bash_profile"
        "tmux.conf"
        "screenrc"
        "inputrc"
        "vimrc"
        "wgetrc"
        "curlrc"
    )

    BASH_DOT_FILES=(
        "bash.path.sh"
        "bash.env.sh"
        "path.env.sh"
        "bash.funcs.sh"
        "bash.aliases.sh"
        "screen.aliases.sh"
        "tmux.aliases.sh"
        "bash.prompt.sh"
        "bash.prompt_funcs.sh"
        "bash-preexec.sh"
        "logging.sh"
        "ssh.aliases.sh"
    )

    # Pentest-specific files
    PENTEST_FILES=(
        "pentest.sh"
        "pentest.alias.sh"
        "pentest.env.sh"
        "pentest.keys"
        "pentest.path.sh"
        "tgt.aliases.sh"
        "screenshot.sh"
        "capture_traffic.sh"
    )

    # =============================================================================
    # PACKAGES AND TOOLS
    # =============================================================================

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
        "certbot"
        "chromium-browser"
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
        "jq"
        "kismet"
        "krb5-config"
        "krb5-user"
        "lcov"
        "ldap-utils"
        "letsencrypt"
        "libasound2t64"
        "libasound2-dev"
        "libblas3"
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
        "liblinear4"
        "libltdl7"
        "libltdl-dev"
        "liblua5.3-0"
        "liblzma-dev"
        "libncurses5-dev"
        "libnetfilter-queue-dev"
        "libnl-genl-3-dev"
        "libnss3-dev"
        "libpcap-dev"
        "libpq5"
        "libpq-dev"
        "libreadline-dev"
        "libsasl2-dev"
        "libserf-1-1"
        "libsmbclient-dev"
        "libsqlite3-dev"
        "libssh2-1"
        "libssl-dev"
        "libtool"
        "libtypes-serialiser-perl"
        "libusb-1.0-0-dev"
        "libutf8proc2"
        "libxml2-dev"
        "libxml2-utils"
        "libxslt1-dev"
        "libyaml-dev"
        "lua-lpeg"
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
        "pkg-config"
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
        "termcolor"
        "tmux"
        "tox"
        "traceroute"
        "tree"
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
        "git+https://github.com/dirkjanm/adidnsdump#egg=adidnsdump" # error
        "git+https://github.com/zer1t0/certi" # error
        "git+https://github.com/ly4k/Certipy" # error
        "coercer"
        "lsassy"
        "git+https://github.com/blacklanternsecurity/MANSPIDER" # error
        "mitm6"
        "git+https://github.com/Pennyw0rth/NetExec" # error
        "pypykatz"
        #"https://github.com/ShawnDEvans/smbmap" # error
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

    # =============================================================================
    # TOOL APP TEST MAPPINGS
    # =============================================================================

    ## TOOLS to APP TEST
    declare -A APP_TESTS
    APP_TESTS["bettercap"]="bettercap -h"
    APP_TESTS["certi"]="certi.py -h"
    APP_TESTS["certipy"]="certipy -h"
    APP_TESTS["Chromium_Browser"]="chromium --version"
    APP_TESTS["gowitness"]="gowitness -h"
    APP_TESTS["ldapdomaindump"]="ldapdomaindump -h"
    APP_TESTS["ldapnomnom"]="ldapnomnom -h"
    APP_TESTS["lsassy"]="lsassy -h"
    APP_TESTS["masscan"]="masscan --ping 127.0.0.1"
    APP_TESTS["mitm6"]="mitm6 -h"
    APP_TESTS["nmap"]="nmap --version"
    APP_TESTS["pypykatz"]="pypykatz -h"
    APP_TESTS["secretsdump"]="secretsdump.py -h"
    APP_TESTS["tshark"]="tshark -h"

    # =============================================================================
    # TOOL CATEGORIES AND MAPPINGS
    # =============================================================================

    # List of tool categories
    TOOL_CATEGORIES=(
        "ALL"
        "intelligence-gathering"
        "vulnerability-analysis"
        "password-recovery"
        "exploitation"
        "post-exploitation"
        "wireless"
    )

    declare -A TOOL_CATEGORY_MAP
    TOOL_CATEGORY_MAP["adidnsdump"]="post-exploitation"
    TOOL_CATEGORY_MAP["aircrack-ng"]="wireless exploitation"
    TOOL_CATEGORY_MAP["bettercap"]="exploitation post-exploitation"
    TOOL_CATEGORY_MAP["certipy"]="post-exploitation"
    TOOL_CATEGORY_MAP["certi"]="post-exploitation"
    TOOL_CATEGORY_MAP["dirb"]="intelligence-gathering"
    TOOL_CATEGORY_MAP["dnsenum"]="intelligence-gathering exploitation"
    TOOL_CATEGORY_MAP["dnsrecon"]="intelligence-gathering exploitation"
    TOOL_CATEGORY_MAP["gowitness"]="intelligence-gathering"
    TOOL_CATEGORY_MAP["hcxdumptool"]="wireless exploitation"
    TOOL_CATEGORY_MAP["hcxtools"]="wireless"
    TOOL_CATEGORY_MAP["hydra"]="password-recovery"
    TOOL_CATEGORY_MAP["kismet"]="wireless"
    TOOL_CATEGORY_MAP["ldapdomaindump"]="intelligence-gathering exploitation"
    TOOL_CATEGORY_MAP["ldapnomnom"]="vulnerability-analysis"
    TOOL_CATEGORY_MAP["lsassy"]="post-exploitation intelligence-gathering"
    TOOL_CATEGORY_MAP["manspider"]="intelligence-gathering post-exploitation"
    TOOL_CATEGORY_MAP["masscan"]="intelligence-gathering exploitation"
    TOOL_CATEGORY_MAP["medusa"]="password-recovery"
    TOOL_CATEGORY_MAP["minidump"]="post-exploitation"
    TOOL_CATEGORY_MAP["minikerberos"]="post-exploitation"
    TOOL_CATEGORY_MAP["mitm6"]="exploitation"
    TOOL_CATEGORY_MAP["nmap"]="vulnerability-analysis"
    TOOL_CATEGORY_MAP["nori"]="post-exploitation"
    TOOL_CATEGORY_MAP["pypykatz"]="post-exploitation"
    TOOL_CATEGORY_MAP["wifite"]="wireless exploitation"

    # =============================================================================
    # MENU ITEMS
    # =============================================================================

    # Array for Setup_Environment functions
    BASH_ENVIRONMENT_MENU_ITEMS=(
        "Undo_Setup_Dot_Files"
        "Setup_Dot_Files"
    )

    # Array for Setup_Environment functions
    PENTEST_ENVIRONMENT_MENU_ITEMS=(
        "Setup_Directories"
        "Setup_Necessary_Files"
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
        "Edit Config Files"
        "Setup BASH Environment"
        "Setup PENTEST Environment"
        "Install Tools"
        #"Install Tools Categories"
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
        "_Install_All_Tools"
        "_Install_Inhouse_Tools"
        "_Install_Pipx_Tools"
        "_Install_Go_Tools"
        "_Install_Ruby_Gems"
    )
fi
