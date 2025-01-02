[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Build Status](https://github.com/tatanus/BASH/actions/workflows/main.yml/badge.svg)
![ShellCheck](https://github.com/tatanus/BASH/actions/workflows/shellcheck.yml/badge.svg)

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
- Provide a structured and organized Bash environment.
- Automate common tasks and workflows.
- Include configurations and scripts tailored for penetration testing, development, and system administration.
- Ensure easy customization, modularity, and maintainability.

---

## Features

- Modular configuration system:
  - `tools/` where install scripts for various tools reside.
  - `pentest_menu/modules/` where task specific shell scripts reside that are called via the pentest_menu script
- Automation scripts for pentesting and system tasks.
- FZF-powered dynamic menus for streamlined workflows.
- Logging and error-handling utilities.
- Predefined aliases and prompts to improve command-line efficiency.
- Customized BASH [prompt](https://github.com/tatanus/BASH/docs/BASH_PROMPT_README.md)
- [Logging](https://github.com/tatanus/BASH/docs/LOGGINGREADME.md) functionality that adds timestamp, source of log, and unified across GNU screen, tmux, and ttys.

---

## Requirements

- **Operating System**: Ubuntu or similar Linux distribution.
- **Tools and Dependencies**:
  - `bash` (>=4.0)
  - `fzf` (for interactive menus)

---

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
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
├── SetupBashAuto.sh           # Main setup script
├── dot/                       # Environment-specific configurations
│   ├── bashrc
│   ├── bash_aliases
│   ├── tmux.conf
│   └── ...
├── config/                    # User-specific configurations
│   ├── config.sh
│   ├── pentest.env
│   └── ...
├── lib/                       # Utility scripts for common functions
│   ├── utils.sh
│   ├── menu.sh
│   └── ...
├── tools/                     # Scripts and modules for various tools
│   ├── modules/
│   │   ├── run_aquatone.sh    # Script to run Aquatone
│   │   ├── run_nuclei.sh      # Script to run Nuclei
│   │   └── ...
│   └── other_tool.sh          # Placeholder for other tool scripts
├── pentest_menu/              # Pentesting-related menus and scripts
│   ├── modules/
│   │   ├── recon_menu.sh      # Recon menu script
│   │   ├── exploit_menu.sh    # Exploit menu script
│   │   └── ...
│   └── pentest_menu.sh        # Main pentest menu entry script
└── tests/                     # Automated test scripts
    ├── bats/                  # Tests using BATS framework
    │   ├── run_tests.sh       # Test runner
    │   └── example_test.bats  # Example test
    └── shellcheck_test.sh     # ShellCheck linting script

```

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork this repository.
2. Create a branch for your feature or fix.
3. Commit your changes and push to your fork.
4. Submit a pull request.

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## Notes

For any questions, feature requests, or bug reports, feel free to open an issue or contact the repository owner.

Enjoy using BASH - "Bash Automation for Simple Hacking"!
