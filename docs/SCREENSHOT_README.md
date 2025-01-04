
# Screenshot Script

`screenshot.sh` is a Bash script designed to capture the output of a command or input text and save it as a PNG image. It ensures the preservation of formatting and colors in the output.

---

## Features

- **Command Output Capture**: Captures the output of any shell command and saves it as a PNG.
- **Text Input Capture**: Processes plain text input and saves it as a PNG.
- **Formatting and Colors**: Retains the formatting and colors of the command output or text.
- **Error Handling**: Checks for missing dependencies and invalid inputs.

---

## Requirements

- **Dependencies**:
  - `ansifilter`: Converts ANSI-colored text to HTML.
  - `a2ps`: Converts text to PostScript.
  - `ImageMagick` (`convert`): Converts PostScript to PNG.
- **Permissions**:
  - Ensure the user has permissions to run these tools.

---

## Usage

### Syntax

For capturing command output:
```bash
screenshot_command '<command>' [output_file]
```

For capturing plain text:
```bash
screenshot_text '<text>' [output_file]
```

### Options

| Parameter       | Description                                  | Default           |
|-----------------|----------------------------------------------|-------------------|
| `<command>`     | The shell command to execute and capture.    | N/A               |
| `<text>`        | The plain text to process.                   | N/A               |
| `[output_file]` | Name of the output PNG file.                 | `output.png`      |

### Examples

#### Example 1: Capture Command Output
```bash
screenshot_command 'ls --color' command_output.png
```

#### Example 2: Capture Text Input
```bash
screenshot_text 'Hello World' text_output.png
```

---

## Error Handling

- **Missing Dependencies**: The script checks for the availability of required tools (`ansifilter`, `a2ps`, `convert`) and exits with an error message if they are missing.
- **Invalid Inputs**: If the command or text input is empty, the script provides usage instructions.
- **Command Execution Failures**: If the provided command fails to execute, the script displays an error message.

---

## Development

### File Structure

- **Script**: `screenshot.sh`
- **README**: `SCREENSHOT_README.md` (this file)

### License

This script is open-source. Feel free to use and modify it as needed.

---

## Author

**Adam Compton**  
Date Created: December 8, 2024