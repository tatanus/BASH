# Project Badges

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Build Status](https://github.com/tatanus/BASH/actions/workflows/main.yml/badge.svg)](https://github.com/tatanus/BASH/actions/workflows/main.yml)
[![Last Commit](https://img.shields.io/github/last-commit/tatanus/BASH)](https://github.com/tatanus/BASH/commits/main)


# BASH - "Bash Automation for Simple Hacking"

This repository offers a modular and extensible configuration for establishing and managing a robust Bash environment, tailored for penetration testers but also useful to developers and system administrators. It encompasses a setup script to configure a customized BASH environment, utility scripts to assit in daily activities, environment configurations, and tools designed to enhance productivity and streamline workflows.

---

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Directory Structure](#directory-structure)
- [Contributing](#contributing)
- [License](#license)


---

## Overview

The **BASH_SETUP Environment** is designed to:
- Establish a structured, organized Bash environment.
- Automate penetration testing workflows.
- Provide utility scripts for system administration and development tasks.
- Enable dynamic, interactive menus for streamlined operations.
- Facilitate modular customization with extensive logging and error handling.

---

## Features

- **Dynamic Menus**:
  - FZF-powered menus for quick access to tools and scripts.
  - Persistent tracking of menu selections and timestamps.

- **Predefined Utilities**:
  - [Logging](docs/LOGGING_README.md) and error-handling utilities.
  - Modular scripts for common pentesting tasks.

- **Custom Environment Setup**:
  - Configurable `.bashrc`, `.bash_aliases`, and `.tmux.conf`.
  - Tailored prompts, aliases, and environment variables.

- **Modular Configuration System**:
  - `dot/`: Environment-specific configurations that get copied into the user's environment, primarily into `~/` or `~/.config/bash` directories. Files are renamed from `filename` to `.filename`.
  - `config/`: Additional configurations used by `SetupBashEnv.sh`. The `pentest.*` files are moved to `~/.config/pentest/` for use during penetration tests.
  - `lib/`: Utility scripts facilitating specific functionalities based on tasks such as apt, fzf, python, ruby, files, etc.

- **Tool Integrations**:
  - Scripts for popular tools like Aquatone, Nuclei, and more.
  - Preconfigured modules for reconnaissance, exploitation, and credential testing.

- **Automation Scripts**:
  - `tools/`: Modules for external tools installed in `${TOOLS_DIR}` (typically `~/DATA/TOOLS/`).
    - `config/`: Custom config files for specific tools, copied into appropriate directories during installation.
    - `modules/`: Scripts designed to install individual tools, ensuring proper setup, necessary aliases, and virtual environments if needed.
    - `extra/`: Miscellaneous additional tools.
      - `msf/`: Various `.rc` files for Metasploit, each executing a specific module and logging output.
      - `scripts/`: Custom in-house standalone tools.

- **Pentest Menu**:
  - `pentest_menu/`: Pentest menu scripts (currently a work in progress and subject to change).

- **Documentation**:
  - `docs/`: Documentation for various scripts, primarily those in the `lib/` directory.

- **Testing**:
  - `tests/`: Automated tests to ensure code quality and functionality.

---

## Requirements

- **Operating System**: Ubuntu or a similar Linux distribution.
- **Dependencies**:
  - `bash` (>=4.0)
  - `fzf` (for interactive menus)
  - Standard Linux utilities (`curl`, `git`, `tmux`, etc.)
  -
  - Misc tools that make your life easier: ncat eza bat/batcat proxychains4

---

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/tatanus/BASH.git
   cd BASH
   ```

2. Run the setup script:
   ```bash
   ./SetupBashEnv.sh
   ```

3. Restart your shell or source the environment:
   ```bash
   # if your system does not automatically source ~/.bashrc you will need to do it manually
   source ~/.bashrc
   ```

---

## Directory Structure

```
BASH/
├── README.md                  # Project documentation
├── SetupBashEnv.sh            # Main setup script
├── dot/                       # Environment configurations
│   ├── bashrc
│   ├── tmux.conf
│   ├── logging.sh
│   └── ...
├── config/                    # Additional configuration
│   ├── pentest.env
│   ├── pentest.keys
│   └── ...
├── lib/                       # Utility scripts
│   ├── utils.sh
│   ├── menu.sh
│   ├── utils_tools.sh
│   ├── lists.sh
│   └── ...
├── tools/                     # Modules for external tools
│   ├── config/                # Custom config files for specific tools
│   ├── modules/               # Scripts to install individual tools
│   │   ├── aquatone.sh
│   │   └── ...
│   ├── extra/                 # Miscellaneous additional tools
│   │   ├── msf/               # Metasploit .rc files
│   │   ├── scripts/           # Custom standalone tools
│   └── ...
├── pentest_menu/              # Pentest menu scripts
├── docs/                      # Documentation
│   ├── BASH_PROMPT_README.md
│   ├── LOGGING_README.md
│   └── ...
├── tests/                     # Automated tests
│   ├── shellcheck_test.sh
│   ├── unit/
│   │   └── example_unit_test.sh
│   └── ...

```

---

# Project Directory Structure

This document provides an overview of the directory structure used in this project. It includes environment variable mappings for key directories and a hierarchical breakdown of all relevant subdirectories.

---

## **Environment Variable Mappings**
The following environment variables are used to reference key directories within the project. This allows for flexible configuration and easier management of paths.

| Environment Variable  | Directory Path |
|----------------------|-------------------------|
| `${DATA_DIR}`       | `DATA/`                 |
| `${TOOLS_DIR}`      | `DATA/TOOLS/`           |
| `${BACKUP_DIR}`     | `DATA/BACKUP/`          |
| `${LOGS_DIR}`       | `DATA/LOGS/`            |
| `${LOOT_DIR}`       | `DATA/LOOT/`            |
| `${CREDS_DIR}`      | `DATA/LOOT/CREDENTIALS/` |
| `${RECON_DIR}`      | `DATA/RECON/`           |
| `${OUTPUT_DIR}`     | `DATA/OUTPUT/`          |
| `${PORTSCAN_DIR}`   | `DATA/OUTPUT/PORTSCAN/` |
| `${TEE_DIR}`        | `DATA/OUTPUT/TEE/`      |
| `${SHARES_DIR}`     | `DATA/SHARES/`          |

---

## 📂 **Directory Breakdown**

Below is a structured breakdown of the directories and their purpose:

```
DATA/                        # Root data directory
│── TOOLS/                    # Tool storage
│   ├── SCRIPTS/              # Custom scripts used for automation
│   ├── MSF/                  # Metasploit-related files
│
│── BACKUP/                   # Backups of important data
│
│── LOGS/                     # Log files and reports
│
│── LOOT/                     # Data collected from assessments
│   ├── CREDENTIALS/          # Harvested credentials
│   │   ├── CCACHE/           # Kerberos ticket caches
│   ├── SCREENSHOTS/          # Captured images from engagements
│   ├── FILES/                # Miscellaneous collected files
│
│── RECON/                    # Reconnaissance-related files
│
│── OUTPUT/                   # Processed or generated output
│   ├── PORTSCAN/             # Port scanning results
│   │   ├── NMAP/             # Nmap scan results
│   │   ├── SPOONMAP/         # Spoonmap scan results
│   ├── TEE/                  # Stored tee command outputs
│   ├── MITM/                 # Man-in-the-Middle attack logs
│   ├── MSF/                  # Metasploit framework outputs
│   ├── BLOODHOUND/           # BloodHound AD mapping data
│   ├── CISCO/                # Cisco network assessment data
│   ├── SMB/                  # SMB-related logs and data
│   ├── WEB/                  # Web application assessment data
│   ├── LDAP/                 # LDAP reconnaissance data
│   ├── COERSION/             # Coercion attack-related files
│   ├── ADCS/                 # Active Directory Certificate Services data
│   ├── PCAP/                 # Network packet capture files
│
│── SHARES/                   # Network share enumeration data
│   ├── NFS/                  # NFS shares
│   ├── SMB/                  # SMB shares
```
---

## 💡 **Usage Notes**
- Environment variables should be set dynamically in scripts to avoid hardcoding paths.
- Subdirectories are logically grouped to improve organization and efficiency during assessments.
- The `OUTPUT/` directory is used to store pre/post-processing results from tools and automated scripts.
- The `LOOT/` directory is strictly for collected artifacts, while `RECON/` is for analyzed and colleded data.

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork this repository.
2. Create a branch for your feature or fix.
3. Commit your changes and push to your fork.
4. Submit a pull request.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Notes

For any questions, feature requests, or bug reports, feel free to open an issue or contact the repository owner.

Enjoy using **BASH - "Bash Automation for Simple Hacking"!**
