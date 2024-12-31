
# Capture Traffic Script

`capture_traffic.sh` is a Bash script designed to capture and analyze bidirectional communication between two IP addresses and ports using `tshark`. It filters, formats, and displays the captured traffic in a human-readable format.

---

## Features

- **Bidirectional Traffic Capture**: Captures traffic between specified source and destination IPs and ports.
- **Flexible Options**:
  - Specify capture duration (in seconds).
  - Limit the number of messages to capture.
  - Choose the network interface for capturing traffic.
- **Readable Output**: Displays timestamps, source and destination information, and payloads.
- **Robust Error Handling**: Ensures dependencies are installed and arguments are valid.

---

## Requirements

- **Dependencies**:
  - `tshark` (part of the Wireshark suite)
- **Permissions**:
  - Ensure the user has permissions to run `tshark` (e.g., using `sudo` if necessary).

---

## Usage

### Syntax

```bash
./capture_traffic.sh <src_ip> <dst_ip> <src_port> <dst_port> [options]
```

### Options

| Option            | Description                                         | Default          |
|-------------------|-----------------------------------------------------|------------------|
| `-t`, `--time`    | Duration of the capture in seconds                  | `10`             |
| `-m`, `--messages`| Maximum number of messages to capture               | `100`            |
| `--interface`     | Network interface to capture traffic                | `any`            |
| `--help`          | Display help and usage information                  | N/A              |

### Examples

#### Example 1: Capture for 10 Seconds
```bash
./capture_traffic.sh 192.168.1.1 192.168.1.2 5000 5001 -t 10
```

#### Example 2: Capture up to 50 Messages
```bash
./capture_traffic.sh 192.168.1.1 192.168.1.2 5000 5001 -m 50
```

#### Example 3: Specify Network Interface
```bash
./capture_traffic.sh 192.168.1.1 192.168.1.2 5000 5001 --interface eth0
```

---

## Output Format

The script outputs captured traffic in the following format:

```
[Timestamp] <src_ip>:<src_port> -> <dst_ip>:<dst_port>: <payload>
```

### Example Output

```plaintext
[2024-12-21 15:02:30.123456] 192.168.1.1:5000 -> 192.168.1.2:23: telnet 192.168.1.2
[2024-12-21 15:02:30.223456] 192.168.1.2:23 -> 192.168.1.1:5000: Welcome to Telnet Server
[2024-12-21 15:02:30.323456] 192.168.1.1:5000 -> 192.168.1.2:23: login: user1
[2024-12-21 15:02:30.423456] 192.168.1.2:23 -> 192.168.1.1:5000: Password:
[2024-12-21 15:02:31.123456] 192.168.1.1:5000 -> 192.168.1.2:23: *****
[2024-12-21 15:02:31.223456] 192.168.1.2:23 -> 192.168.1.1:5000: Login successful!
```

---

## Error Handling

- **Missing Dependencies**: If `tshark` is not installed, the script will exit with an error message.
- **Invalid Arguments**: If required arguments are missing or invalid, the script will display usage instructions.
- **No Traffic Captured**: If no packets match the specified criteria, a warning is displayed.

---

## Development

### File Structure

- **Script**: `capture_traffic.sh`
- **README**: `CAPTURE_TRAFFIC_README.md` (this file)

### License

This script is open-source. Feel free to use and modify it as needed.

---

## Author

**Adam Compton**  
Date Created: December 8, 2024
