
# bash_prompt and bash_prompt_funcs

## Overview
This consists of two primary Bash scripts:

1. **bash_prompt**: A script to dynamically generate a customized Bash prompt with various features, including IP address display, session information, and more.
2. **bash_prompt_funcs**: A supplementary script containing reusable functions for retrieving system information, managing network configurations, and enhancing the prompt functionality.

## Features

### bash_prompt
- Dynamically updates the Bash prompt to include:
  - **Internal IP Address**: Displays the local IP address, excluding specific interfaces.
  - **External IP Address**: Displays the external IP address, fetched from an online service.
  - **Kerberos Cache**: Displays the Kerberos credentials cache (if available).
  - **Python Virtual Environment**: Indicates the active Python virtual environment.
  - **Date and Time**: Shows the current date and time.
  - **User and Host**: Displays the current user and host information.
  - **Working Directory**: Highlights the current working directory.

- Leverages customizable colors for better readability.
- Periodically updates IP address information to ensure accuracy.
- Integrates preexec functionality to log commands before execution.

### bash_prompt_funcs
- **Session Information**:
  - Identifies active TMUX or Screen sessions.
  - Displays session names in the prompt.

- **Network Configuration**:
  - Identifies whether network interfaces use DHCP or static IP configurations.
  - Retrieves and caches local and external IP addresses, filtering specific interfaces.

- **System Information**:
  - Detects the operating system type (Linux, macOS, or Windows).
  - Provides reusable functions for checking Python virtual environments and Kerberos credentials.

- **Utilities**:
  - Caches IP addresses for improved performance.
  - Handles errors gracefully and ensures compatibility across different systems.

## Configuration

- **Customizing Colors**:
  The colors used in the prompt are defined using `tput` commands for broad compatibility. Modify these variables in `bash_prompt` to change the color scheme.

- **Excluded Network Interfaces**:
  To exclude specific interfaces from the local IP display, edit the `excluded_interfaces` array in the `get_local_ip` function.

- **Proxy Support**:
  If you need to use a proxy for fetching external IP addresses, set the `PROXY` environment variable.

## Troubleshooting

- Ensure that all required dependencies (`tput`, `curl`, `wget`, etc.) are installed on your system.
- If the prompt does not update correctly, check for missing configurations in `~/.bashrc`.

## License
This project is released under the MIT License.

---

## Contact
**Author**: Adam Compton  
Feel free to reach out for questions, feedback, or contributions.
