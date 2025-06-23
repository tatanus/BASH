#!/usr/bin/env python3
# =============================================================================
# NAME        : nessus_parser.py
# DESCRIPTION : Parses .nessus XML files to extract structured data about hosts,
#               ports, and findings. Supports filtering by severity, regex, and
#               extracting resolved reference URLs.
# AUTHOR      : Adam Compton
# DATE CREATED: 2025-06-05 15:45:00
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2025-06-05 15:45:00  | Adam Compton | Initial creation.
# =============================================================================

import argparse
import logging
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Optional, List, Dict, Set, Tuple

import requests

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------
logging.basicConfig(
    format="%(asctime)s [%(levelname)s] %(message)s",
    level=logging.INFO
)

# -----------------------------------------------------------------------------
# Severity Mapping
# -----------------------------------------------------------------------------
SEVERITY_LEVELS = {'info': 0, 'low': 1, 'medium': 2, 'high': 3, 'critical': 4}
NUM_TO_SEVERITY = {v: k for k, v in SEVERITY_LEVELS.items()}


def resolve_redirects(reference_urls: Set[str]) -> Dict[str, str]:
    """
    Resolve each reference URL by following redirects.

    Args:
        reference_urls (Set[str]): Set of reference URLs to resolve.

    Returns:
        Dict[str, str]: Mapping of original to final resolved URLs.
    """
    resolved = {}
    headers = {'User-Agent': 'Mozilla/5.0 (compatible; NessusParser/1.0)'}
    for url in reference_urls:
        try:
            resp = requests.get(url, allow_redirects=True, timeout=10, headers=headers, stream=True)
            resolved[url] = resp.url
            resp.close()
        except requests.RequestException as e:
            logging.warning(f"Failed to resolve {url}: {e}")
            resolved[url] = url
    return resolved


def get_severity_int(val: Optional[str]) -> Optional[int]:
    """
    Convert severity string to integer.

    Args:
        val (Optional[str]): Severity string.

    Returns:
        Optional[int]: Corresponding severity level.
    """
    if val is None:
        return None
    return SEVERITY_LEVELS.get(val.lower())


def matches_severity(severity_str: str, min_level: Optional[int] = None, exact_level: Optional[int] = None) -> bool:
    """
    Check if a severity string matches a filter level.

    Args:
        severity_str (str): Severity as string (number).
        min_level (Optional[int]): Minimum level.
        exact_level (Optional[int]): Required exact level.

    Returns:
        bool: Whether the severity matches the criteria.
    """
    sev_int = int(severity_str)
    if exact_level is not None:
        return sev_int == exact_level
    if min_level is not None:
        return sev_int >= min_level
    return True


def parse_args() -> Tuple[argparse.ArgumentParser, argparse.Namespace]:
    """
    Define and parse CLI arguments.

    Returns:
        Tuple[argparse.ArgumentParser, argparse.Namespace]: Parser and parsed arguments.
    """
    parser = argparse.ArgumentParser(
        description="Parse .nessus XML reports for host, port, and vulnerability data."
    )
    parser.add_argument('file', type=Path, help='Path to .nessus XML file')
    parser.add_argument('--severity-min', '-m', help='Minimum severity to include (e.g. low, medium, high)')
    parser.add_argument('--severity-exact', '-e', help='Only include findings of exact severity')

    sub = parser.add_subparsers(dest='cmd', title='Commands', required=True)

    sub.add_parser('live-hosts', help='List all live host IPs')

    sp = sub.add_parser('open-ports', help='Show open ports for an IP')
    sp.add_argument('--ip', '-i', required=True, help='IP address to query')

    sp = sub.add_parser('ips-with-port', help='List IPs with a specific open port')
    sp.add_argument('--port', '-p', type=int, required=True, help='Port number')

    sub.add_parser('list-ip-ports', help='List all IP:port pairs')

    sp = sub.add_parser('findings', help='List findings or references')
    sp.add_argument('--severity', help='Exact severity filter (numeric or name)')
    sp.add_argument('--regex', '-r', help='Regex pattern to match plugin name')
    sp.add_argument('--search', '-s', help='Search string in plugin name or description')
    sp.add_argument('--references', '-R', action='store_true', help='Output resolved references only')

    return parser, parser.parse_args()


def load_tree(path: Path) -> ET.ElementTree:
    """
    Load and parse XML file.

    Args:
        path (Path): Path to .nessus file.

    Returns:
        ET.ElementTree: Parsed XML tree.

    Raises:
        SystemExit: On parsing error.
    """
    try:
        return ET.parse(path)
    except (ET.ParseError, OSError) as e:
        logging.error(f"Error parsing '{path}': {e}")
        sys.exit(1)


def get_hosts(tree: ET.ElementTree) -> List[ET.Element]:
    """
    Get all ReportHost elements.

    Args:
        tree (ET.ElementTree): XML tree.

    Returns:
        List[ET.Element]: List of host elements.
    """
    return tree.getroot().findall('.//ReportHost')


def cmd_live_hosts(tree: ET.ElementTree, args: argparse.Namespace) -> None:
    """List all IPs with at least one finding matching severity filter."""
    ips = set()
    for host in get_hosts(tree):
        for ri in host.findall('ReportItem'):
            if matches_severity(ri.get('severity'), get_severity_int(args.severity_min), get_severity_int(args.severity_exact)):
                ips.add(host.get('name'))
                break
    for ip in sorted(ips):
        print(ip)


def cmd_open_ports(tree: ET.ElementTree, args: argparse.Namespace) -> None:
    """Show all open ports for a specific IP, filtered by severity."""
    found = False
    for host in get_hosts(tree):
        if host.get('name') == args.ip:
            found = True
            ports = {
                ri.get('port')
                for ri in host.findall('ReportItem')
                if matches_severity(ri.get('severity'), get_severity_int(args.severity_min), get_severity_int(args.severity_exact))
            }
            for p in sorted(ports, key=int):
                print(p)
    if not found:
        logging.warning(f"IP not found: {args.ip}")


def cmd_ips_with_port(tree: ET.ElementTree, args: argparse.Namespace) -> None:
    """List IPs with a specific open port."""
    ips = {
        host.get('name')
        for host in get_hosts(tree)
        for ri in host.findall('ReportItem')
        if ri.get('port') == str(args.port)
        and matches_severity(ri.get('severity'), get_severity_int(args.severity_min), get_severity_int(args.severity_exact))
    }
    for ip in sorted(ips):
        print(ip)


def cmd_list_ip_ports(tree: ET.ElementTree, args: argparse.Namespace) -> None:
    """List all IP:port pairs matching severity filter."""
    pairs = {
        f"{host.get('name')}:{ri.get('port')}"
        for host in get_hosts(tree)
        for ri in host.findall('ReportItem')
        if matches_severity(ri.get('severity'), get_severity_int(args.severity_min), get_severity_int(args.severity_exact))
    }
    for pair in sorted(pairs):
        print(pair)


def cmd_findings(tree: ET.ElementTree, args: argparse.Namespace) -> None:
    """List findings or their references based on filters."""
    sev_filter = str(SEVERITY_LEVELS.get(args.severity.lower(), args.severity)) if args.severity else None
    regex = re.compile(args.regex) if args.regex else None
    search = args.search.lower() if args.search else None
    min_level = get_severity_int(args.severity_min)
    exact_level = get_severity_int(args.severity_exact)

    findings = []
    for host in get_hosts(tree):
        ip = host.get('name')
        for ri in host.findall('ReportItem'):
            port = ri.get('port')
            sev_val = ri.get('severity')
            name = ri.get('pluginName') or ''
            desc = ri.findtext('description') or ''

            if sev_filter and sev_val != sev_filter:
                continue
            if not matches_severity(sev_val, min_level, exact_level):
                continue
            if regex and not regex.search(name):
                continue
            if search and search not in name.lower() and search not in desc.lower():
                continue

            findings.append((ip, port, sev_val, name, ri))

    if args.references:
        ref_set = set()
        for _, _, _, _, ri in findings:
            for ref in ri.findall('see_also'):
                if ref.text:
                    for line in ref.text.strip().splitlines():
                        cleaned = line.strip()
                        if cleaned:
                            ref_set.add(cleaned)
        resolved_refs = resolve_redirects(ref_set)
        for original in sorted(resolved_refs):
            print(f"{original} -> {resolved_refs[original].strip()}")
    else:
        for ip, port, sev_val, name, _ in sorted(findings):
            sev_txt = NUM_TO_SEVERITY.get(int(sev_val), sev_val)
            print(f"{ip}:{port}:{sev_txt}:{name}")


def main() -> None:
    """Main script logic and dispatch."""
    parser, args = parse_args()
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