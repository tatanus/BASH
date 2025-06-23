#!/usr/bin/env python3
# =============================================================================
# NAME        : ad_dns_enum.py
# DESCRIPTION : Enumerate DNS-SD/SRV records for AD and general services.
#               Outputs results in text, JSON, or CSV format, with support for
#               custom DNS resolvers and SRV prefix sets.
# AUTHOR      : Adam Compton
# DATE CREATED: 2025-06-06 23:30:00
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2025-06-06 23:30:00  | Adam Compton | Initial creation.
# =============================================================================

import argparse
import sys
import json
import csv
import logging
from typing import Optional, List, Dict
import dns.resolver
import dns.exception

# -----------------------------
# Logging Configuration
# -----------------------------
logging.basicConfig(
    level=logging.INFO,
    format="[%(levelname)s] %(message)s"
)

# -----------------------------
# Service Prefix Definitions
# -----------------------------
AD_SRV_PREFIXES = [
    "_ldap._tcp",
    "_ldap._tcp.dc._msdcs",
    "_ldap._tcp.pdc._msdcs",
    "_kerberos._tcp",
    "_kerberos._tcp.dc._msdcs",
    "_kerberos._udp",
    "_kerberos-master._tcp",
    "_kerberos-master._tcp.dc._msdcs",
    "_kpasswd._tcp",
    "_kpasswd._udp",
    "_gc._tcp",
    "_gc._tcp.dc._msdcs"
]

GENERAL_SRV_PREFIXES = [
    "_http._tcp",
    "_https._tcp",
    "_ssh._tcp",
    "_ftp._tcp",
    "_sip._tcp",
    "_sip._udp",
    "_printers._tcp",
    "_ipp._tcp"
]

DEFAULT_PREFIXES = AD_SRV_PREFIXES + GENERAL_SRV_PREFIXES

# -----------------------------
# Argument Parsing
# -----------------------------
def parse_args() -> argparse.Namespace:
    """Parse and validate command-line arguments.

    Returns:
        argparse.Namespace: Parsed arguments.
    """
    parser = argparse.ArgumentParser(
        description="Enumerate DNS-SD/SRV records (Active Directory + general)"
    )
    parser.add_argument(
        "domain", help="Target domain (e.g. example.com)"
    )
    parser.add_argument(
        "-s", "--dns-server", dest="dns_servers",
        help="Comma-separated DNS server IPs to use"
    )
    parser.add_argument(
        "-f", "--format", dest="fmt", choices=["text", "json", "csv"],
        default="text", help="Output format"
    )
    parser.add_argument(
        "-S", "--services", dest="services",
        help="Comma-separated list of SRV prefixes to query"
    )
    parser.add_argument(
        "-o", "--output", dest="output",
        help="Output file path (default: stdout)"
    )
    args = parser.parse_args()

    if "." not in args.domain:
        parser.error("Invalid domain format (e.g. example.com)")

    return args

# -----------------------------
# DNS Setup
# -----------------------------
def get_resolver(dns_servers: Optional[str]) -> dns.resolver.Resolver:
    """Create a configured DNS resolver.

    Args:
        dns_servers (Optional[str]): Comma-separated DNS IPs.

    Returns:
        dns.resolver.Resolver: Configured resolver instance.
    """
    resolver = dns.resolver.Resolver()
    resolver.timeout = 3
    resolver.lifetime = 5

    if dns_servers:
        resolver.nameservers = [ip.strip() for ip in dns_servers.split(",") if ip.strip()]
    return resolver

# -----------------------------
# DNS Query Functions
# -----------------------------
def query_srv(fqdn: str, resolver: dns.resolver.Resolver) -> List[Dict]:
    """Query an SRV record.

    Args:
        fqdn (str): Full SRV name.
        resolver (dns.resolver.Resolver): Resolver to use.

    Returns:
        List[Dict]: List of SRV record dictionaries.
    """
    try:
        answers = resolver.resolve(fqdn, "SRV")
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
        return []
    except dns.exception.Timeout:
        logging.error(f"Timeout querying {fqdn}")
        return []
    except dns.exception.DNSException as e:
        logging.error(f"DNS error querying {fqdn}: {e}")
        return []

    return [
        {
            "service": fqdn,
            "priority": r.priority,
            "weight": r.weight,
            "port": r.port,
            "target": str(r.target).rstrip(".")
        }
        for r in answers
    ]

def resolve_host(hostname: str, resolver: dns.resolver.Resolver) -> List[str]:
    """Resolve A and AAAA records for hostname.

    Args:
        hostname (str): Hostname to resolve.
        resolver (dns.resolver.Resolver): Resolver to use.

    Returns:
        List[str]: List of IPs.
    """
    ips = []
    for rtype in ("A", "AAAA"):
        try:
            answers = resolver.resolve(hostname, rtype)
            ips.extend(str(r) for r in answers)
        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
            continue
        except dns.exception.DNSException as e:
            logging.warning(f"Failed {rtype} lookup for {hostname}: {e}")
    return ips

# -----------------------------
# Core Enumeration Logic
# -----------------------------
def enumerate_services(domain: str, prefixes: List[str], resolver: dns.resolver.Resolver) -> List[Dict]:
    """Enumerate services using SRV queries.

    Args:
        domain (str): Target domain.
        prefixes (List[str]): List of SRV prefixes.
        resolver (dns.resolver.Resolver): Configured resolver.

    Returns:
        List[Dict]: Raw SRV results.
    """
    records = []
    for prefix in prefixes:
        fqdn = f"{prefix}.{domain}".lower()
        for rec in query_srv(fqdn, resolver):
            rec["ips"] = resolve_host(rec["target"], resolver)
            records.append(rec)
    return records

def normalize_sort_unique(records: List[Dict]) -> List[Dict]:
    """Deduplicate and sort SRV records.

    Args:
        records (List[Dict]): Raw records.

    Returns:
        List[Dict]: Cleaned, sorted list.
    """
    for rec in records:
        rec["service"] = rec["service"].lower()
        rec["target"] = rec["target"].lower()
        rec["ips"] = sorted(set(ip.lower() for ip in rec["ips"]))

    seen = set()
    unique = []
    for rec in records:
        key = (
            rec["service"], rec["priority"], rec["weight"],
            rec["port"], rec["target"], tuple(rec["ips"])
        )
        if key not in seen:
            seen.add(key)
            unique.append(rec)

    unique.sort(key=lambda r: (r["service"], r["target"], r["port"]))
    return unique

# -----------------------------
# Output Handlers
# -----------------------------
def output_text(records: List[Dict], domain: str) -> None:
    """Display records in readable text.

    Args:
        records (List[Dict]): Record list.
        domain (str): Domain name.
    """
    if not records:
        print(f"No SRV records found for {domain}")
        return
    for r in records:
        print(f"[{r['service']}] -> {r['target']}:{r['port']} "
              f"(prio={r['priority']}, weight={r['weight']}) ips: {', '.join(r['ips']) or '<none>'}")

def output_json(records: List[Dict]) -> None:
    """Print JSON output.

    Args:
        records (List[Dict]): Record list.
    """
    print(json.dumps(records, indent=2))

def output_csv(records: List[Dict], out_stream) -> None:
    """Write records as CSV.

    Args:
        records (List[Dict]): Record list.
        out_stream: File-like object to write to.
    """
    writer = csv.writer(out_stream)
    writer.writerow(["service", "priority", "weight", "port", "target", "ips"])
    for r in records:
        writer.writerow([
            r["service"], r["priority"], r["weight"],
            r["port"], r["target"], ";".join(r["ips"])
        ])

# -----------------------------
# Main Entry Point
# -----------------------------
def main() -> None:
    """Main execution flow."""
    try:
        args = parse_args()
        resolver = get_resolver(args.dns_servers)

        prefixes = (
            [s.strip() for s in args.services.split(",") if s.strip()]
            if args.services else DEFAULT_PREFIXES
        )

        raw_records = enumerate_services(args.domain, prefixes, resolver)
        records = normalize_sort_unique(raw_records)

        if args.output:
            with open(args.output, "w", encoding="utf-8", newline='') as f:
                if args.fmt == "json":
                    json.dump(records, f, indent=2)
                elif args.fmt == "csv":
                    output_csv(records, f)
                else:
                    sys.stdout = f  # fallback: redirect print
                    output_text(records, args.domain)
        else:
            if args.fmt == "json":
                output_json(records)
            elif args.fmt == "csv":
                output_csv(records, sys.stdout)
            else:
                output_text(records, args.domain)

    except Exception as e:
        logging.exception(f"Fatal error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()