
# SSH Functions Script (`ssh_funcs.sh`)

## Overview

`ssh_funcs.sh` is a Bash script designed to simplify the management and use of SSH configurations. It provides an interactive menu system for connecting to SSH hosts, managing SSH configuration entries, and automating common SSH-related tasks. 

The script utilizes `fzf` for an intuitive and efficient user interface, making SSH operations seamless and user-friendly.

## Features

- **Interactive Menus**: Navigate options using `fzf` to streamline SSH host selection and management.
- **SSH Host Connection**: Quickly connect to SSH hosts listed in your `~/.ssh/config` file.
- **Add New SSH Hosts**: Easily append new `TAP_*` host entries to your SSH configuration file.
- **Validation**: Input validation for hostnames, proxy jumps, and ports to ensure data integrity.
- **Pause Between Actions**: Ensures users can review output before moving to the next step.
- **Customizable**: Default paths and configurations can be adjusted to fit individual requirements.

## Requirements

- **Bash** (v4.0 or later)
- **fzf**: A command-line fuzzy finder
- An existing SSH configuration file (`~/.ssh/config` or as defined in `SSH_CONFIG_FILE`).

## Installation

1. Clone or download this repository.
2. Ensure the script is executable:
   ```bash
   chmod +x ssh_funcs.sh
   ```
3. Install `fzf` if not already installed:
   ```bash
   sudo apt install fzf
   ```
4. Update the `SSH_CONFIG_FILE` variable in the script if your SSH configuration file is not located at `~/.ssh/config`.

## Usage

Run the script directly:
```bash
./ssh_funcs.sh
```

### Main Menu Options

1. **SSH to Host**:
   - Displays a list of hosts from the SSH configuration file.
   - Select a host to initiate an SSH session.

2. **Add New SSH Host**:
   - Prompts for details to add a new `TAP_*` host entry to the SSH configuration file.
   - Validates inputs for correctness before appending them to the file.

## Configuration

The default path to the SSH configuration file is `../ssh_config`. Update the `SSH_CONFIG_FILE` variable to point to the correct location, if necessary:
```bash
SSH_CONFIG_FILE="$HOME/.ssh/config"
```

## Error Handling

- Ensures the SSH configuration file exists before proceeding.
- Validates all user inputs (hostnames, ports, proxy jumps) to prevent errors.
- Displays appropriate error messages when validation fails.

## Customization

You can extend or modify the script by adding new menu options or functionality. Use the provided function structure as a template for your custom additions.

## Troubleshooting

- **Error: SSH config file ... does not exist**: Ensure the SSH configuration file exists at the specified path in `SSH_CONFIG_FILE`.
- **fzf not found**: Install `fzf` using your package manager (e.g., `sudo apt install fzf`).

## Contributing

Feel free to fork this repository and submit pull requests for enhancements or bug fixes.

## License

This script is open-source and available under the MIT License.

---

**Author**: Adam Compton  
**Date Created**: 2024-12-08
