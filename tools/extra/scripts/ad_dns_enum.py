#!/usr/bin/env python3
"""
ad_dns_enum.py

Enumerate Unicast DNS-SD/SRV records for a domain (AD-specific + general services).
Provides lowercase, sorted, unique output in text, JSON, or CSV formats.
Supports custom DNS resolvers, alternate service lists, and robust error handling.

Usage examples:
  python3 ad_dns_enum.py example.com
  python3 ad_dns_enum.py -s 8.8.8.8,1.1.1.1 -f json example.com
  python3 ad_dns_enum.py -S _http._tcp,_ssh._tcp -f csv -o services.csv example.com
"""
import argparse
import sys
import json
import csv
import logging
import dns.resolver
import dns.exception

# Configure basic logging
logging.basicConfig(
    level=logging.INFO,
    format="[%(levelname)s] %(message)s"
)

# -----------------------------
# Service Prefix Definitions
# -----------------------------
# Each entry: prefix string and inline comment describing its purpose.
AD_SRV_PREFIXES = [
    "_ldap._tcp",                  # LDAP over TCP (port 389) for domain controller discovery
    "_ldap._tcp.dc._msdcs",        # LDAP over TCP in _msdcs zone for DC records
    "_ldap._tcp.pdc._msdcs",       # LDAP pointing at the PDC Emulator FSMO role holder
    "_kerberos._tcp",              # Kerberos KDC over TCP (port 88)
    "_kerberos._tcp.dc._msdcs",    # Kerberos KDC in _msdcs zone
    "_kerberos._udp",              # Kerberos KDC over UDP (port 88)
    "_kerberos-master._tcp",       # Master KDC for password changes/admin tasks
    "_kerberos-master._tcp.dc._msdcs",  # Master KDC in _msdcs zone
    "_kpasswd._tcp",               # Kerberos password-change over TCP (port 464)
    "_kpasswd._udp",               # Kerberos password-change over UDP
    "_gc._tcp",                    # Global Catalog LDAP over TCP (port 3268)
    "_gc._tcp.dc._msdcs"           # Global Catalog in _msdcs zone
]

GENERAL_SRV_PREFIXES = [
    "_http._tcp",                  # HTTP service discovery (port 80)
    "_https._tcp",                 # HTTPS service discovery (port 443)
    "_ssh._tcp",                   # SSH service discovery (port 22)
    "_ftp._tcp",                   # FTP service discovery (port 21)
    "_sip._tcp",                   # SIP over TCP
    "_sip._udp",                   # SIP over UDP
    "_printers._tcp",              # Printer service via mDNS
    "_ipp._tcp"                    # Internet Printing Protocol
]

# Combined default list
DEFAULT_PREFIXES = AD_SRV_PREFIXES + GENERAL_SRV_PREFIXES

# -----------------------------
# Argument Parsing
# -----------------------------
def parse_args():
    """
    Parse and validate command-line arguments.
    """
    parser = argparse.ArgumentParser(
        description="Enumerate DNS-SD/SRV records (AD + general)."
    )
    parser.add_argument(
        "domain", help="Target DNS domain (e.g. example.com)"
    )
    parser.add_argument(
        "-s", "--dns-server", dest="dns_servers",
        help="Comma-separated list of DNS servers to query (overrides system defaults)"
    )
    parser.add_argument(
        "-f", "--format", dest="fmt",
        choices=["text", "json", "csv"], default="text",
        help="Output format: text, json, or csv"
    )
    parser.add_argument(
        "-S", "--services", dest="services",
        help="Comma-separated SRV prefixes to query (overrides built-in list)"
    )
    parser.add_argument(
        "-o", "--output", dest="output",
        help="Write output to file instead of stdout"
    )
    args = parser.parse_args()

    # Basic validation
    if "." not in args.domain:
        parser.error("Invalid domain format; expected a DNS-style domain (e.g., example.com)")
    return args

# -----------------------------
# DNS Resolver Setup
# -----------------------------
def get_resolver(dns_servers):
    """
    Configure and return a dnspython Resolver.
    Applies custom nameservers and reasonable timeouts.

    :param dns_servers: comma-separated DNS server IPs or None
    :return: configured dns.resolver.Resolver
    """
    resolver = dns.resolver.Resolver()
    # Set timeouts for responsiveness
    resolver.timeout = 3
    resolver.lifetime = 5

    # Override nameservers if provided
    if dns_servers:
        resolver.nameservers = []
        for ip in dns_servers.split(","):
            ip = ip.strip()
            if not ip:
                continue
            resolver.nameservers.append(ip)
    return resolver

# -----------------------------
# SRV Query & Resolution
# -----------------------------
def query_srv(fqdn, resolver):
    """
    Query a single SRV record and return structured results.

    :param fqdn: fully-qualified SRV name
    :param resolver: dns.resolver.Resolver
    :return: list of dicts with keys 'service', 'priority', 'weight', 'port', 'target'
    """
    try:
        answers = resolver.resolve(fqdn, 'SRV')
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
        return []
    except dns.exception.Timeout:
        logging.error(f"Timeout querying SRV record: {fqdn}")
        return []
    except dns.exception.DNSException as exc:
        logging.error(f"DNS error querying {fqdn}: {exc}")
        return []

    records = []
    for r in answers:
        records.append({
            'service': fqdn,
            'priority': r.priority,
            'weight': r.weight,
            'port': r.port,
            'target': str(r.target).rstrip('.')
        })
    return records


def resolve_host(hostname, resolver):
    """
    Resolve A and AAAA records for a hostname.

    :param hostname: domain name to resolve
    :param resolver: dns.resolver.Resolver
    :return: list of IP strings
    """
    ips = []
    for record_type in ('A', 'AAAA'):
        try:
            answers = resolver.resolve(hostname, record_type)
            for r in answers:
                ips.append(str(r))
        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
            continue
        except dns.exception.DNSException as exc:
            logging.warning(f"Error resolving {record_type} for {hostname}: {exc}")
    return ips

# -----------------------------
# Enumeration, Normalization, and Output
# -----------------------------

def enumerate_services(domain, prefixes, resolver):
    """
    Query and collect SRV records for all prefixes under the domain.

    :return: list of raw record dicts (no normalization)
    """
    records = []
    for prefix in prefixes:
        fqdn = f"{prefix}.{domain}".lower()
        srv_recs = query_srv(fqdn, resolver)
        for rec in srv_recs:
            rec['ips'] = resolve_host(rec['target'], resolver)
            records.append(rec)
    return records


def normalize_sort_unique(records):
    """
    Lowercase all fields, dedupe, and sort the records.

    :param records: list of record dicts
    :return: cleaned, unique, sorted list
    """
    # Lowercase fields and uniquify IP lists
    for rec in records:
        rec['service'] = rec['service'].lower()
        rec['target'] = rec['target'].lower()
        rec['ips'] = sorted({ip.lower() for ip in rec['ips']})

    # Deduplicate full records
    seen = set()
    unique = []
    for rec in records:
        key = (
            rec['service'], rec['priority'], rec['weight'],
            rec['port'], rec['target'], tuple(rec['ips'])
        )
        if key not in seen:
            seen.add(key)
            unique.append(rec)

    # Sort by service name, then target, then port
    unique.sort(key=lambda r: (r['service'], r['target'], r['port']))
    return unique


def output_text(records, domain):
    """
    Print human-readable, lowercase text output.
    """
    if not records:
        print(f"no srv records for {domain}")
        return
    for r in records:
        ips = ", ".join(r['ips']) if r['ips'] else '<none>'
        print(f"[{r['service']}] -> {r['target']}:{r['port']} "
              f"(prio={r['priority']}, weight={r['weight']}) ips: {ips}")


def output_json(records):
    """
    Print JSON-formatted output.
    """
    print(json.dumps(records, indent=2))


def output_csv(records, out_stream):
    """
    Write CSV-formatted output to given stream.
    """
    writer = csv.writer(out_stream)
    writer.writerow(['service','priority','weight','port','target','ips'])
    for r in records:
        writer.writerow([
            r['service'], r['priority'], r['weight'],
            r['port'], r['target'], ';'.join(r['ips'])
        ])

# -----------------------------
# Main Execution Flow
# -----------------------------
def main():
    try:
        args = parse_args()
        resolver = get_resolver(args.dns_servers)

        # Determine prefixes to use
        if args.services:
            prefixes = [s.strip() for s in args.services.split(',') if s.strip()]
        else:
            prefixes = DEFAULT_PREFIXES

        # Collect and process records
        raw_records = enumerate_services(args.domain, prefixes, resolver)
        records = normalize_sort_unique(raw_records)

        # Output handling
        out_stream = open(args.output, 'w') if args.output else sys.stdout
        try:
            if args.fmt == 'json':
                output_json(records)
            elif args.fmt == 'csv':
                output_csv(records, out_stream)
            else:
                output_text(records, args.domain)
        finally:
            if args.output:
                out_stream.close()

    except Exception as e:
        logging.exception(f"Unexpected error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
