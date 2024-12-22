#!/usr/bin/env bash

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
        "$BASE_DIR"
        "$TOOL_DIR"
        "$LOG_DIR"
    )

    ENGAGEMENT_DIRECTORIES=(
        "$BASE_DIR/ADCS"
        "$BASE_DIR/BACKUP"
        "$BASE_DIR/BACKUP/CME"
        "$BASE_DIR/BACKUP/MSF"
        "$BASE_DIR/BACKUP/NXC"
        "$BASE_DIR/CISCO"
        "$BASE_DIR/CISCO/PHONES"
        "$BASE_DIR/CISCO/SIET"
        "$BASE_DIR/COERCION"
        "$BASE_DIR/CREDS"
        "$BASE_DIR/CREDS/KERBEROAST"
        "$BASE_DIR/CREDS/KERBRUTE"
        "$BASE_DIR/CREDS/PRE2K"
        "$BASE_DIR/CREDS/TIMEROAST"
        "$BASE_DIR/JAVA"
        "$BASE_DIR/LDAP"
        "$BASE_DIR/LDAP/BLOODHOUND"
        "$BASE_DIR/LOGS"
        "$BASE_DIR/MITM"
        "$BASE_DIR/MITM/BETTERCAP"
        "$BASE_DIR/MITM/MITM6"
        "$BASE_DIR/MITM/PCREDS"
        "$BASE_DIR/MITM/PRETENDER"
        "$BASE_DIR/MITM/RESPONDER"
        "$BASE_DIR/MSF"
        "$BASE_DIR/NMAP"
        "$BASE_DIR/NMAP/SCANS"
        "$BASE_DIR/RECON"
        "$BASE_DIR/SHARES"
        "$BASE_DIR/SHARES/NFS"
        "$BASE_DIR/SHARES/NFS/FILES"
        "$BASE_DIR/SHARES/NFS/mnt"
        "$BASE_DIR/SHARES/SMB"
        "$BASE_DIR/SHARES/SMB/FILES"
        "$BASE_DIR/SHARES/SMB/mnt"
        "$BASE_DIR/SMB"
        "$BASE_DIR/SMB/CME"
        "$BASE_DIR/SMB/E4L"
        "$BASE_DIR/SMB/KERBEROAST"
        "$BASE_DIR/SMB/KERBRUTE"
        "$BASE_DIR/SMB/NXC"
        "$BASE_DIR/TEE"
        "$BASE_DIR/TOOLS"
        "$BASE_DIR/WEB"
    )

    NECESSARY_ENGAGEMENT_FILES=(
        "$BASE_DIR/targets.txt"
        "$BASE_DIR/excludes.txt"
    )

    ## DOT FILES
    DOT_FILES=(
        "bashrc"
        "bash_env"
        "path_env"
        "bash_aliases"
        "screen_aliases"
        "tmux_aliases"
        "tgt_aliases"
        "tmux.conf"
        "screenrc"
        "bash_path"
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
        "tools/config/msf.config:$MY_HOME/.msf4/config"
        "tools/config/cme.conf:$MY_HOME/.cme/cme.conf"
        "tools/config/nxc.conf:$MY_HOME/.nxc/nxc.conf"
        "tools/config/Responder.conf:$TOOL_DIR/Responder/Responder.conf"
        "tools/config/spoonmap.config.json:$TOOL_DIR/spoonmap/config.json"
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
        "Setup_Environment"
        "Edit Config Files"
        "Install_Tools"
        "Test_Tool_Installs"
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
fi