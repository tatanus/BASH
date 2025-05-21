#!/usr/bin/env python3
"""
nessus_parser.py: Parse .nessus XML files and query hosts, ports, and findings.

Usage examples:
  # List all live hosts
  python nessus_parser.py report.nessus live-hosts

  # Show open ports for a specific IP
  python nessus_parser.py report.nessus open-ports --ip 192.168.1.10

  # List all IPs that had port 443 open
  python nessus_parser.py report.nessus ips-with-port --port 443

  # List all IP:port pairs
  python nessus_parser.py report.nessus list-ip-ports

  # Unified findings output: IP:port:severity:finding_name
  # Optional filters: --severity and/or --regex
  python nessus_parser.py report.nessus findings --severity high --regex "SSL"
"""

import argparse
import sys
import re
import xml.etree.ElementTree as ET


def parse_args():
    parser = argparse.ArgumentParser(
        description="Parse .nessus file and query hosts, ports, and findings"
    )
    parser.add_argument(
        'file', metavar='FILE', help='Path to .nessus XML file'
    )
    sub = parser.add_subparsers(dest='cmd', required=True)

    sub.add_parser('live-hosts', help='List all live host IPs')

    sp = sub.add_parser('open-ports', help='Show open ports for an IP')
    sp.add_argument('--ip', required=True, help='IP address to query')

    sp = sub.add_parser('ips-with-port', help='List IPs that had a specific port open')
    sp.add_argument('--port', type=int, required=True, help='Port number to query')

    sub.add_parser('list-ip-ports', help='List all IP:port pairs')

    sp = sub.add_parser('findings', help='List IP:port:severity:finding_name entries')
    sp.add_argument(
        '--severity',
        help='Filter by severity (numeric 0-3 or info/low/medium/high)'
    )
    sp.add_argument(
        '--regex',
        help='Filter finding_name by regex'
    )

    return parser.parse_args()


def load_tree(path):
    try:
        return ET.parse(path)
    except (ET.ParseError, OSError) as e:
        print(f"ERROR parsing '{path}': {e}", file=sys.stderr)
        sys.exit(1)


def get_hosts(tree):
    root = tree.getroot()
    return root.findall('.//ReportHost')


def cmd_live_hosts(tree, args):
    for host in get_hosts(tree):
        print(host.get('name'))


def cmd_open_ports(tree, args):
    target = args.ip
    for host in get_hosts(tree):
        if host.get('name') == target:
            ports = {ri.get('port') for ri in host.findall('ReportItem')}
            if ports:
                for p in sorted(ports, key=lambda x: int(x)):
                    print(p)
            else:
                print(f'No open ports found for {target}', file=sys.stderr)
            return
    print(f'IP not found: {target}', file=sys.stderr)


def cmd_ips_with_port(tree, args):
    port = str(args.port)
    ips = {
        host.get('name')
        for host in get_hosts(tree)
        for ri in host.findall('ReportItem')
        if ri.get('port') == port
    }
    for ip in sorted(ips):
        print(ip)


def cmd_list_ip_ports(tree, args):
    results = {
        f"{host.get('name')}:{ri.get('port')}"
        for host in get_hosts(tree)
        for ri in host.findall('ReportItem')
    }
    for r in sorted(results):
        print(r)


def cmd_findings(tree, args):
    # Prepare severity filter
    sev_filter = None
    if args.severity:
        sev = args.severity.lower()
        sev_map = {'info': '0', 'low': '1', 'medium': '2', 'high': '3'}
        sev_filter = sev_map.get(sev, sev)

    # Prepare regex filter
    regex = re.compile(args.regex) if args.regex else None

    # Map numeric to text
    num2txt = {'0': 'info', '1': 'low', '2': 'medium', '3': 'high'}

    output = set()
    for host in get_hosts(tree):
        ip = host.get('name')
        for ri in host.findall('ReportItem'):
            port = ri.get('port')
            sev_val = ri.get('severity')
            name = ri.get('pluginName') or ''
            if sev_filter and sev_val != sev_filter:
                continue
            if regex and not regex.search(name):
                continue
            sev_txt = num2txt.get(sev_val, sev_val)
            output.add(f"{ip}:{port}:{sev_txt}:{name}")
    for entry in sorted(output):
        print(entry)


def main():
    args = parse_args()
    tree = load_tree(args.file)
    commands = {
        'live-hosts': cmd_live_hosts,
        'open-ports': cmd_open_ports,
        'ips-with-port': cmd_ips_with_port,
        'list-ip-ports': cmd_list_ip_ports,
        'findings': cmd_findings,
    }
    commands[args.cmd](tree, args)


if __name__ == '__main__':
    main()