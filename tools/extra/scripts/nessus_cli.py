#!/usr/bin/env python3
"""
nessus_cli.py

Interact with a local Nessus install via its REST API:
- List scans
- Start a scan
- Pause a scan
- Resume a scan
- Stop a scan
- Export scan results (.nessus or .csv)

Author: Adam Compton
"""

import requests
import time
import argparse
import urllib3

# Disable SSL warnings for Nessus's self-signed cert
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# === Configuration ===
NESSUS_HOST = "https://localhost:8834"
USERNAME = "pentest"
PASSWORD = "pentest1!"
VERIFY_SSL = False  # Set to True if using a valid certificate

# === Global Header ===
HEADERS = {"Content-Type": "application/json"}


def login():
    url = f"{NESSUS_HOST}/session"
    payload = {"username": USERNAME, "password": PASSWORD}
    response = requests.post(url, json=payload, verify=VERIFY_SSL)
    response.raise_for_status()
    token = response.json()["token"]
    HEADERS["X-Cookie"] = f"token={token}"


def list_scans():
    url = f"{NESSUS_HOST}/scans"
    response = requests.get(url, headers=HEADERS, verify=VERIFY_SSL)
    response.raise_for_status()
    scans = response.json()["scans"]

    if not scans:
        print("[-] No scans found.")
        return

    print("[+] Available Scans:")
    print(f"{'ID':>4} | {'Status':<10} | Name")
    print("-" * 50)
    for scan in scans:
        scan_id = scan["id"]
        scan_name = scan["name"]
        scan_status = scan.get("status", "unknown")
        print(f"{scan_id:>4} | {scan_status:<10} | {scan_name}")


def get_scan_id(scan_name):
    url = f"{NESSUS_HOST}/scans"
    response = requests.get(url, headers=HEADERS, verify=VERIFY_SSL)
    response.raise_for_status()
    scans = response.json()["scans"]
    for scan in scans:
        if scan["name"].lower() == scan_name.lower():
            return scan["id"]
    raise ValueError(f"Scan '{scan_name}' not found.")


def start_scan(scan_id):
    url = f"{NESSUS_HOST}/scans/{scan_id}/launch"
    response = requests.post(url, headers=HEADERS, verify=VERIFY_SSL)
    response.raise_for_status()
    print(f"[+] Started scan ID {scan_id}")


def pause_scan(scan_id):
    url = f"{NESSUS_HOST}/scans/{scan_id}/pause"
    response = requests.post(url, headers=HEADERS, verify=VERIFY_SSL)
    response.raise_for_status()
    print(f"[+] Paused scan ID {scan_id}")


def resume_scan(scan_id):
    url = f"{NESSUS_HOST}/scans/{scan_id}/resume"
    response = requests.post(url, headers=HEADERS, verify=VERIFY_SSL)
    response.raise_for_status()
    print(f"[+] Resumed scan ID {scan_id}")


def stop_scan(scan_id):
    url = f"{NESSUS_HOST}/scans/{scan_id}/stop"
    response = requests.post(url, headers=HEADERS, verify=VERIFY_SSL)
    response.raise_for_status()
    print(f"[+] Stopped scan ID {scan_id}")


def export_scan(scan_id, file_format):
    url = f"{NESSUS_HOST}/scans/{scan_id}/export"
    payload = {"format": file_format}
    response = requests.post(url, headers=HEADERS, json=payload, verify=VERIFY_SSL)
    response.raise_for_status()
    file_id = response.json()["file"]

    # Wait for export to be ready
    status_url = f"{NESSUS_HOST}/scans/{scan_id}/export/{file_id}/status"
    while True:
        status = requests.get(status_url, headers=HEADERS, verify=VERIFY_SSL).json()["status"]
        if status == "ready":
            break
        print("[*] Waiting for export to complete...")
        time.sleep(2)

    download_url = f"{NESSUS_HOST}/scans/{scan_id}/export/{file_id}/download"
    download = requests.get(download_url, headers=HEADERS, verify=VERIFY_SSL)
    ext = "nessus" if file_format == "nessus" else "csv"
    filename = f"scan_{scan_id}.{ext}"
    with open(filename, "wb") as f:
        f.write(download.content)
    print(f"[+] Export complete: {filename}")


def main():
    parser = argparse.ArgumentParser(description="Nessus Scan Controller")
    parser.add_argument("action", choices=["list", "start", "pause", "resume", "stop", "download"],
                        help="Action to perform")
    parser.add_argument("scan_name", nargs="?", help="Name of the scan (not needed for 'list'")
    parser.add_argument("--format", choices=["nessus", "csv"], default="nessus", help="Export format for 'download'")

    args = parser.parse_args()

    try:
        login()

        if args.action == "list":
            list_scans()
            return

        if not args.scan_name:
            print("[-] Error: scan_name is required for this action.")
            return

        scan_id = get_scan_id(args.scan_name)

        if args.action == "start":
            start_scan(scan_id)
        elif args.action == "pause":
            pause_scan(scan_id)
        elif args.action == "resume":
            resume_scan(scan_id)
        elif args.action == "stop":
            stop_scan(scan_id)
        elif args.action == "download":
            export_scan(scan_id, args.format)

    except requests.exceptions.RequestException as e:
        print(f"[-] HTTP error: {e}")
    except Exception as e:
        print(f"[-] Error: {e}")


if __name__ == "__main__":
    main()