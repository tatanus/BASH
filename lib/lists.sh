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
        "bash.history.sh"
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
        "aircrack-ng"               # Wireless network cracking tool
        "apache2"                   # Web server, often used for test hosting
        "autoconf"                  # Tool for generating configure scripts
        "automake"                  # Generates Makefile.in from Makefile.am
        "autotools-dev"             # Infrastructure for building GNU packages
        "bat"                       # Enhanced `cat` with syntax highlighting
        "bison"                     # Parser generator (like yacc)
        "build-essential"           # Compiler tools including gcc/g++
        "cargo"                     # Rust package manager
        "certbot"                   # Let's Encrypt client for SSL certificates
        "chromium-browser"          # Web browser for recon or automation
        "cifs-utils"                # Mounting and managing SMB shares
        "curl"                      # Data transfer tool for HTTP, FTP, etc.
        "dirb"                      # Web content scanner
        "dirmngr"                   # Manages and downloads GPG keys
        "dnsenum"                   # DNS enumeration script
        "dnsrecon"                  # DNS enumeration and zone transfer tool
        "dos2unix"                  # Converts DOS line endings to UNIX
        "ethtool"                   # Configure/control Ethernet devices
        "fzf"                       # Fuzzy finder for terminal navigation
        "gcc"                       # GNU C compiler
        "gcc-x86-64-linux-gnux32"   # Cross-compiler for x86_64-gnux32
        "gdebi-core"                # Installs .deb packages with dependencies
        "git"                       # Version control system
        "gnupg2"                    # GPG encryption/signing tool
        "grepcidr"                  # CIDR-aware grep for IP filtering
        "g++"                       # GNU C++ compiler
        "hcxdumptool"               # Captures wireless traffic for cracking
        "hcxtools"                  # Converts captured wireless traffic
        "hydra"                     # Password brute-forcer
        "icu-devtools"              # International Components for Unicode dev tools
        "jq"                        # JSON processor
        "kismet"                    # Wireless network detector/sniffer
        "krb5-config"               # Kerberos configuration utility
        "krb5-user"                 # Kerberos user utilities
        "lcov"                      # Code coverage tool for C/C++
        "ldap-utils"                # LDAP search and query tools
        "letsencrypt"               # Meta-package for SSL certificate setup
        "libasound2t64"             # ALSA sound library
        "libasound2-dev"            # ALSA sound development files
        "libblas3"                  # Linear algebra library
        "libbz2-dev"                # Bzip2 compression library (dev)
        "libcommon-sense-perl"      # Boosts Perl script performance
        "libffi-dev"                # Foreign function interface library
        "libgdbm-dev"               # GNU dbm database library (dev)
        "libgmpxx4ldbl"             # GMP C++ library for large numbers
        "libgmp-dev"                # Multiple precision arithmetic library
        "libicu-dev"                # Unicode and globalization support
        "libjson-perl"              # JSON parser for Perl
        "libjson-xs-perl"           # Fast and compact JSON parser
        "libkrb5-dev"               # Kerberos development files
        "libldap2-dev"              # LDAP dev libraries
        "liblinear4"                # Linear classification library
        "libltdl7"                  # Dynamic loading of libraries
        "libltdl-dev"               # Development files for libltdl
        "liblua5.3-0"               # Lua scripting language runtime
        "liblzma-dev"               # XZ compression development library
        "libncurses5-dev"           # Terminal handling library (legacy)
        "libnetfilter-queue-dev"    # Netfilter queue manipulation dev files
        "libnl-genl-3-dev"          # Netlink sockets library (generic)
        "libnss3-dev"               # Network security services (NSS) dev files
        "libpcap-dev"               # Packet capture library (dev)
        "libpq5"                    # PostgreSQL database client library
        "libpq-dev"                 # PostgreSQL development headers
        "libreadline-dev"           # GNU Readline support for CLI tools
        "libsasl2-dev"              # SASL authentication development files
        "libserf-1-1"               # Apache Serf HTTP client
        "libsmbclient-dev"          # SMB client library (dev)
        "libsqlite3-dev"            # SQLite3 development files
        "libssh2-1"                 # SSH2 protocol client
        "libssl-dev"                # SSL/TLS library (development files)
        "libtool"                   # Tool for managing shared libraries
        "libtypes-serialiser-perl"  # Perl serialization support
        "libusb-1.0-0-dev"          # USB device development files
        "libutf8proc2"              # Unicode processing library
        "libxml2-dev"               # XML processing (dev files)
        "libxml2-utils"             # CLI utilities for XML parsing
        "libxslt1-dev"              # XSLT (XML stylesheet) development files
        "libyaml-dev"               # YAML processing (dev files)
        "lua-lpeg"                  # Parsing Expression Grammar for Lua
        "m4"                        # Macro processor used in autoconf
        "macchanger"                # Changes MAC addresses
        "make"                      # Build automation tool
        "masscan"                   # Fast TCP port scanner
        "maven"                     # Java project build tool
        "medusa"                    # Parallel login brute-forcer
        "mingw-w64"                 # Cross-compilers for Windows targets
        "mlocate"                   # File search tool
        "mono-mcs"                  # C# compiler from Mono
        "nbtscan"                   # Scans for NetBIOS name info
        "ncat"                      # Netcat clone with more features
        "net-tools"                 # Legacy tools like `ifconfig`
        "nmap"                      # Network scanner
        "phantomjs"                 # Headless browser for scripting/recon
        "pkg-config"                # Helps with compiling software
        "postgresql"                # PostgreSQL DBMS
        "postgresql-contrib"        # Extra tools for PostgreSQL
        "proxychains4"              # Run commands through proxy servers
        "python3-dev"               # Python headers for C extensions
        "python3-pip"               # Python 3 package installer
        "python3-venv"              # Python virtual environment support
        "readline-common"           # Common files for readline
        "redis"                     # In-memory key-value store
        "ruby-full"                 # Ruby language environment
        "rustc"                     # Rust compiler
        "samba"                     # SMB file sharing service
        "screen"                    # Terminal multiplexer
        "silversearcher-ag"         # Code searching tool like `ack`, much faster (ag = 'The Silver Searcher')
        "smbclient"                 # SMB/CIFS file access client
        "snmp"                      # SNMP protocol tools
        "sqlite3"                   # SQLite command-line interface
        "ssl-cert"                  # SSL certificate management utilities
        "sysstat"                   # Performance monitoring tools
        "termcolor"                 # ANSI color formatting for terminal output
        "tmux"                      # Terminal multiplexer like screen
        "tox"                       # Python test automation tool
        "traceroute"                # Network route discovery tool
        "tree"                      # Directory tree visualizer
        "tshark"                    # CLI version of Wireshark
        "unzip"                     # ZIP file extractor
        "valgrind"                  # Memory debugging/profiling
        "vim"                       # Text editor
        "wifite"                    # Wireless audit tool with automation
        "zlib1g-dev"                # Compression library (dev files)
    )

    ## PYTHON LIBRARIES
    PIP_PACKAGES=(
        "netifaces"         # Interface address/network detection
        "aiowinreg"         # Async Windows Registry access
        "ldapdomaindump"    # Dumps Active Directory LDAP information
        "minidump"          # Parses Windows minidump files
        "minikerberos"      # Kerberos manipulation and exploitation
        "msldap"            # Lightweight LDAP client for Windows environments
        "setuptools"        # Python packaging/building tools
        "setuptools_rust"   # Support for building Rust extensions for Python
        "twisted"           # Event-driven networking engine
        "winacl"            # Windows ACL access for Python
        "mdv"               # Markdown viewer for terminal
    )

    ## PIPX PACKAGES
    PIPX_PACKAGES=(
        "git+https://github.com/dirkjanm/adidnsdump#egg=adidnsdump"  # Dumps DNS entries from Active Directory (error prone)
        "git+https://github.com/zer1t0/certi"                        # ADCS attack tool (error prone)
        "git+https://github.com/ly4k/Certipy"                        # Active Directory Certificate Services exploitation (error prone)
        #pipx inject --force certipy-ad git+https://github.com/ly4k/ldap3
        "coercer"                                                    # Coerces authentication via SMB/RPC
        "lsassy"                                                     # Dumps LSASS remotely using various methods
        "git+https://github.com/blacklanternsecurity/MANSPIDER"      # Finds sensitive data in SMB shares (error prone)
        "mitm6"                                                      # IPv6-based MitM attack tool
        "git+https://github.com/Pennyw0rth/NetExec"                  # CrackMapExec fork for pentesting (error prone)
        "pypykatz"                                                   # LSASS parsing and credential dumping
        #"https://github.com/ShawnDEvans/smbmap"                     # SMB enumeration tool (commented, install manually)
    )

    ## GO TOOLS
    GO_TOOLS=(
        "github.com/bettercap/bettercap@latest"                     # Modular network attack tool
        "github.com/sensepost/gowitness@latest"                     # Web screenshot and recon tool
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"        # Fast and configurable HTTP probing tool
        "github.com/ropnop/kerbrute@latest"                         # Kerberos user enumeration and brute-forcing
        "github.com/lkarlslund/ldapnomnom@latest"                   # LDAP enumeration tool
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"   # Vulnerability scanner with templating
        "github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest"    # Subnet mapper and IP range processor
    )

    ## RUBY GEMS
    RUBY_GEMS=(
        "nori -v 2.6.0"       # XML parsing gem with version pinned (needed for compatibility)
        "evil-winrm"          # WinRM shell for red teaming
    )

    ## FIXES TO TOOLS POST INSTALL
    declare -A TOOL_FIXES
    TOOL_FIXES["certipy"]="${PROXY} pipx inject --force certipy-ad git+https://github.com/ly4k/ldap3" # Fix LDAP3 library for certipy-ad

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
        "Apply Post Install Tool Fixes"
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
