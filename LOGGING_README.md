
# Logging Script

`logging.sh` is a Bash script designed to log all executed Bash commands in the current session to a secure log file. It is useful for auditing, debugging, or keeping track of command history in various terminal environments.

---

## Features

- **Session-Aware Logging**:
  - Logs commands executed in `screen`, `tmux`, or standard TTY sessions.
- **Secure Log File**:
  - Ensures the log file has restrictive permissions (`600`) for privacy.
- **Real-Time Logging**:
  - Captures and logs commands in real-time using the `DEBUG` trap.
- **Duplicate Prevention**:
  - Prevents duplicate entries for repeated commands.
- **Error Handling**:
  - Checks for and resolves issues related to log file creation and permissions.

---

## Requirements

- **Dependencies**:
  - Standard Unix utilities: `mkdir`, `chmod`, `sed`, `tty`, `flock`, `date`.
- **Permissions**:
  - Sufficient permissions to create and modify the log file at `$HOME/.bash_commands.log`.

---

## Usage

### Setup

1. Source the script in your Bash session or configuration file:
   ```bash
   source /path/to/logging.sh
   ```

2. The script will automatically initialize and begin logging all executed commands to the log file.

### Log File Location

The default log file is located at:
```
$HOME/.bash_commands.log
```

### Output Format

Each logged entry includes:
1. **Timestamp**: Date and time of execution.
2. **Session Information**: Whether the command was executed in `screen`, `tmux`, or a TTY session.
3. **Command**: The exact command that was executed.

### Example Log Entry

```plaintext
[2024-12-21 15:02:30] screen:mysession:(0) # ls -alh
[2024-12-21 15:02:31] tmux:mysession[1:1] # cd /home/user
[2024-12-21 15:02:32] tty(pid):tty1(12345) # echo "Hello, World!"
```

---

## Error Handling

1. **Log File Issues**:
   - If the script fails to create or modify the log file, it will display an error message and exit.
2. **Environment Detection**:
   - Fallbacks to `tty` and `pid` if `screen` or `tmux` information is unavailable.
3. **Duplicate Prevention**:
   - Prevents the same command from being logged multiple times consecutively.

---

## Development

### File Structure

- **Script**: `logging.sh`
- **README**: `LOGGING_README.md` (this file)

### License

This script is open-source. Feel free to use and modify it as needed.

---

## Author

**Adam Compton**  
Date Created: December 8, 2024