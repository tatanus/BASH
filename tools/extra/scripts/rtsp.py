#!/usr/bin/env python3
"""
Concurrent RTSP Deep Scanner with Optional Credentials and
No Output for Refused/Timeout Connections (Python 3)

Features:
1) Parallel scanning of RTSP targets using ThreadPoolExecutor.
2) DESCRIBE request for each target (200 OK, 401, etc.).
3) Optional Basic auth via --username/--password.
4) Skips printing if connection fails or times out.
5) Parses minimal SDP if DESCRIBE is successful (200 OK).
6) Prints results after all scans are complete (excluding refused/timeout).

Usage Examples:
  python rtsp_deep_scanner.py --target 192.168.1.100
  python rtsp_deep_scanner.py --target 192.168.1.0/24 --username admin --password secret
  python rtsp_deep_scanner.py --workers 50
"""

import argparse
import base64
import concurrent.futures
import ipaddress
import re
import socket
import sys
import threading
import time
from typing import List, Dict, Optional


def dot_spinner(stop_event: threading.Event, interval: float = 0.5) -> None:
    """
    Displays a simple spinner (dots) in the console to indicate ongoing scans.

    :param stop_event: A threading.Event that signals when to stop spinning.
    :param interval: Interval in seconds between each dot.
    """
    print()
    print("Scanning", end='', flush=True)
    while not stop_event.is_set():
        print(".", end='', flush=True)
        time.sleep(interval)
    # Print a newline once we're done, so subsequent output is on a fresh line.
    print()


def build_basic_auth_header(username: str, password: str) -> str:
    """
    Construct the 'Authorization: Basic <base64>' header for RTSP requests.

    :param username: RTSP username.
    :param password: RTSP password.
    :return: Authorization header string for Basic authentication.
    """
    userpass = f"{username}:{password}"
    encoded = base64.b64encode(userpass.encode()).decode()
    return f"Authorization: Basic {encoded}"


def send_rtsp_describe(
    ip: str,
    port: int,
    path: str,
    timeout: float = 2.0,
    username: Optional[str] = None,
    password: Optional[str] = None
) -> Dict[str, Optional[str]]:
    """
    Connect to an RTSP server and issue a DESCRIBE request.

    :param ip: Target IP address.
    :param port: RTSP port.
    :param path: The RTSP path/endpoint (e.g., '/live.sdp').
    :param timeout: Socket timeout in seconds.
    :param username: Optional username for Basic auth.
    :param password: Optional password for Basic auth.
    :return: A dictionary containing:
        "status_line" (str or None): The first line of the RTSP response.
        "status_code" (int or None): The parsed status code (e.g. 200, 401).
        "headers" (dict): Dictionary of HTTP/RTSP headers.
        "body" (str or None): The RTSP response body (likely SDP).
        "error" (str or None): If set, indicates an error occurred (e.g. timeout, connection refused).
    """
    result = {
        "status_line": None,
        "status_code": None,
        "headers": {},
        "body": None,
        "error": None
    }

    # Construct the RTSP DESCRIBE request
    lines = [
        f"DESCRIBE rtsp://{ip}:{port}{path} RTSP/1.0",
        "CSeq: 2",
        "User-Agent: RTSPDeepScanner/1.0",
        "Accept: application/sdp"
    ]
    if username and password:
        lines.append(build_basic_auth_header(username, password))
    lines.append("")  # Blank line to end headers
    describe_req = "\r\n".join(lines) + "\r\n"

    # Perform the socket connection and send the request
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.settimeout(timeout)
            s.connect((ip, port))
            s.sendall(describe_req.encode("utf-8"))

            response_chunks = []
            start_time = time.time()

            # Read available data until we either time out or no more data arrives.
            while True:
                if time.time() - start_time > timeout:
                    # We reached our timeout.
                    break
                try:
                    chunk = s.recv(4096)
                    if not chunk:
                        break
                    response_chunks.append(chunk)

                    # If we've got the headers and a bit of the body, break after a short pause
                    if b"\r\n\r\n" in b"".join(response_chunks):
                        time.sleep(0.2)  # Short extra wait to gather any remaining SDP body
                except socket.timeout:
                    # We can exit if we hit a socket timeout while receiving
                    break

            raw_resp = b"".join(response_chunks).decode("utf-8", errors="replace")

    except (socket.error, OSError) as e:
        result["error"] = f"Socket error: {e}"
        return result

    if not raw_resp:
        result["error"] = "No response or empty response."
        return result

    # Split headers from body
    parts = raw_resp.split("\r\n\r\n", 1)
    header_part = parts[0]
    body_part = parts[1] if len(parts) > 1 else ""

    # Parse status line and headers
    lines = header_part.split("\r\n")
    if lines:
        result["status_line"] = lines[0].strip()
        # Try to parse e.g. "RTSP/1.0 200 OK"
        match = re.match(r"RTSP/\d.\d\s+(\d+)\s+(.*)", lines[0])
        if match:
            result["status_code"] = int(match.group(1))

        # Parse headers
        for line in lines[1:]:
            if ":" in line:
                header_name, header_value = line.split(":", 1)
                result["headers"][header_name.strip()] = header_value.strip()

    result["body"] = body_part
    return result


def parse_sdp(sdp_data: str) -> List[Dict[str, str]]:
    """
    Minimal parser for SDP data. Returns a list of track info found in 'm=' lines.

    Example 'm=' lines in SDP:
      m=video 0 RTP/AVP 96
      m=audio 0 RTP/AVP 0

    :param sdp_data: The SDP data as a string.
    :return: A list of dictionaries, each containing:
        "media" (str): Media type (video, audio, etc.).
        "port" (str): Port number (often 0 in this case).
        "proto" (str): Protocol (RTP/AVP, etc.).
        "fmt" (str): Format (e.g., "96" or "0").
    """
    tracks = []
    for line in sdp_data.splitlines():
        line = line.strip()
        if line.lower().startswith("m="):
            parts = line.split()
            # e.g., ["m=video", "0", "RTP/AVP", "96"]
            if len(parts) >= 4:
                media_type = parts[0][2:]  # remove 'm='
                port = parts[1]
                proto = parts[2]
                fmt = " ".join(parts[3:])
                tracks.append({
                    "media": media_type,
                    "port": port,
                    "proto": proto,
                    "fmt": fmt
                })
    return tracks


def scan_rtsp_target(
    ip: str,
    port: int,
    path: str,
    timeout: float,
    username: Optional[str] = None,
    password: Optional[str] = None
) -> Dict:
    """
    Perform an RTSP DESCRIBE scan on a single target (IP + port + path).

    :param ip: IP address of the target.
    :param port: RTSP port.
    :param path: The RTSP path/endpoint (e.g. '/live.sdp').
    :param timeout: Socket timeout in seconds.
    :param username: Optional username for Basic auth.
    :param password: Optional password for Basic auth.
    :return: A summary dictionary with keys:
        "ip", "port", "path", "status_line", "status_code", "error",
        "headers", "sdp_tracks", "message".
    """
    response = send_rtsp_describe(
        ip=ip,
        port=port,
        path=path,
        timeout=timeout,
        username=username,
        password=password
    )
    code = response.get("status_code")

    summary = {
        "ip": ip,
        "port": port,
        "path": path,
        "status_line": response["status_line"],
        "status_code": code,
        "error": response["error"],
        "headers": response["headers"],
        "sdp_tracks": [],
        "message": ""
    }

    # If there's an error (e.g., connection refused, timeout, etc.), return as-is.
    # We'll skip printing these in the final results.
    if response["error"]:
        summary["message"] = f"Error: {response['error']}"
        return summary

    # Interpret valid responses
    if code == 200:
        # Parse SDP for media track info if available
        sdp_tracks = parse_sdp(response["body"] or "")
        summary["sdp_tracks"] = sdp_tracks
        if sdp_tracks:
            summary["message"] = "RTSP OK, SDP parsed"
        else:
            summary["message"] = "RTSP OK but no media tracks found"
    elif code == 401:
        summary["message"] = "401 Unauthorized - check credentials or server auth method"
    elif code is not None:
        summary["message"] = f"Unexpected status code {code}"
    else:
        summary["message"] = "Could not parse status code"

    return summary


def expand_targets(target_str: str) -> List[str]:
    """
    Given a target string (IP or CIDR), return a list of IP addresses to scan.

    :param target_str: A single IP address or a CIDR range (e.g., '192.168.0.0/24').
    :return: A list of IP addresses (as strings).
    """
    try:
        net = ipaddress.ip_network(target_str, strict=False)
        return [str(ip) for ip in net.hosts()]
    except ValueError:
        # Not a valid CIDR; assume it's a single IP or hostname
        return [target_str]


def main() -> None:
    """
    Main entry point for the RTSP Deep Scanner.

    - Parses command-line arguments.
    - Expands the target(s) if CIDR notation is used.
    - Starts a spinner thread to indicate scanning progress.
    - Uses ThreadPoolExecutor to scan multiple targets concurrently.
    - Collects the results and prints only successful RTSP responses
      (skipping any connection-refused or timeout errors).
    """
    parser = argparse.ArgumentParser(
        description="Concurrent RTSP Deep Scanner (No output on refused/timeout)"
    )
    parser.add_argument(
        "--target", "-t", default="127.0.0.1",
        help="IP or CIDR for RTSP scanning (default=127.0.0.1)"
    )
    parser.add_argument(
        "--port", "-p", type=int, default=554,
        help="RTSP port (default=554)"
    )
    parser.add_argument(
        "--path", default="/",
        help="RTSP path (default='/'); e.g. '/live.sdp'"
    )
    parser.add_argument(
        "--timeout", "-o", type=float, default=2.0,
        help="Socket timeout in seconds (default=2.0)"
    )
    parser.add_argument(
        "--workers", type=int, default=20,
        help="Number of worker threads (default=20)"
    )
    parser.add_argument(
        "--username", help="Optional RTSP username for Basic auth"
    )
    parser.add_argument(
        "--password", help="Optional RTSP password for Basic auth"
    )

    args = parser.parse_args()

    print("[*] Concurrent RTSP Deep Scanner (No output for refused/timeout)")
    print(f"    Target(s): {args.target}")
    print(f"    Port:      {args.port}")
    print(f"    Path:      {args.path}")
    print(f"    Timeout:   {args.timeout}s")
    print(f"    Workers:   {args.workers}")
    if args.username or args.password:
        print(f"    Username:  {args.username}")
        print(f"    Password:  {'<hidden>' if args.password else None}")

    # Expand potential CIDR to a list of IPs
    targets = expand_targets(args.target)
    if not targets:
        print("[!] No valid IP addresses to scan.")
        sys.exit(1)

    # Create and start the dot-spinner thread
    stop_event = threading.Event()
    spinner_thread = threading.Thread(target=dot_spinner, args=(stop_event,), daemon=True)
    spinner_thread.start()

    results = []
    # Use a ThreadPoolExecutor for parallel scans
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as executor:
        future_to_ip = {
            executor.submit(
                scan_rtsp_target,
                ip,
                args.port,
                args.path,
                args.timeout,
                username=args.username,
                password=args.password
            ): ip
            for ip in targets
        }

        for future in concurrent.futures.as_completed(future_to_ip):
            ip = future_to_ip[future]
            try:
                data = future.result()
                results.append(data)
            except Exception as e:
                # Catch unexpected exceptions from the worker function
                results.append({
                    "ip": ip,
                    "port": args.port,
                    "path": args.path,
                    "status_line": None,
                    "status_code": None,
                    "error": str(e),
                    "headers": {},
                    "sdp_tracks": [],
                    "message": "Exception during scan"
                })

    # Signal the spinner to stop and wait for the thread to finish
    stop_event.set()
    spinner_thread.join()

    # Filter out results with connection errors (refused/timeout), keeping only valid RTSP responses
    valid_results = [r for r in results if r["error"] is None]

    if not valid_results:
        print("\n[*] Scan complete. No valid RTSP connections found (or all refused/timed-out).")
        return

    print("\n[*] Scan Complete. Valid RTSP Results:\n")
    for res in valid_results:
        ip = res["ip"]
        port = res["port"]
        path = res["path"]
        code = res["status_code"]
        status_line = res["status_line"]
        message = res["message"]
        sdp_tracks = res["sdp_tracks"]

        print(f"IP: {ip}, Port: {port}, Path: {path}")
        print(f"  Status Line: {status_line}")
        print(f"  Status Code: {code}")
        print(f"  Message:     {message}")
        if sdp_tracks:
            print("  SDP Tracks:")
            for t in sdp_tracks:
                print(f"    - media={t['media']}, port={t['port']}, "
                      f"proto={t['proto']}, fmt={t['fmt']}")
        print("")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[!] Scan interrupted by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\n[ERROR] Unexpected exception: {e}")
        sys.exit(1)
