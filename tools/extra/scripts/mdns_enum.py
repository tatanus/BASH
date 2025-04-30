#!/usr/bin/env python3
###############################################################################
# mdns_enum.py
# =============================================================================
# NAME: mdns_enum.py
#
# DESCRIPTION:
#   Discover mDNS service types and/or instances on the local network,
#   and emit results in text, JSON or CSV formats, with human‐readable
#   descriptions for common service TXT‐record fields.
#
# USAGE:
#   ./mdns_enum.py [options]
#
# OPTIONS:
#   -l, --list-types       Just list service types
#   -s TYPE, --service-type TYPE
#                          Browse a single service type (e.g. _http._tcp.local.)
#   -A, --all-services     Browse every discovered service type
#   -t SECONDS, --timeout SECONDS
#                          Seconds to listen per browse (default: 5)
#   -f FORMAT, --format FORMAT
#                          Output format: text (default), json, csv
#
# REQUIREMENTS:
#   pip3 install zeroconf
#   Python ≥ 3.6
#
# AUTHOR:
#   Adam Compton
# DATE CREATED:
#   2025-04-30
###############################################################################

import argparse
import socket
import time
import json
import csv
import sys
from zeroconf import ServiceBrowser, ServiceListener, Zeroconf

# Map common TXT‐record keys to human-readable labels
PROPERTY_DESCRIPTIONS = {
    "deviceid":     "Device ID (MAC address)",
    "features":     "Supported features",
    "flags":        "Status flags",
    "model":        "Device model",
    "pi":           "Pairing ID",
    "pk":           "Public key fingerprint",
    "rmodel":       "Receiver model",
    "rfv":          "Receiver firmware version",
    "srcvers":      "Source version",
    "vv":           "AirPlay version",
    "rpBA":         "Remote peer Bluetooth address",
    "rpAD":         "Remote peer AD identifier",
    "rpFl":         "Remote peer flags",
    "rpHN":         "Remote peer host name",
    "rpMac":        "Remote peer MAC count",
    "rpVr":         "Remote peer version",
    "id":           "Device ID",
    "ve":           "Vendor extension version",
    "md":           "Model description",
    "ic":           "Icon path",
    "fn":           "Friendly name",
    "ca":           "Capabilities",
    "st":           "Status code",
    "txtvers":      "TXT record version",
    "vendor":       "Vendor name",
    "prodrange":    "Product range",
    "prodname":     "Product name",
    "prodvers":     "Product version",
    "os":           "Operating system",
    "guid":         "Device GUID",
    "serialnumber": "Serial number",
    "protovers":    "Protocol version",
    "modules":      "Supported modules",
    "":             "No TXT records available",
    "am":           "Device model",
    "ch":           "Audio channels",
    "cn":           "Audio codecs",
    "da":           "Digest authentication supported",
    "et":           "Supported encryption types",
    "ft":           "Supported features",
    "sf":           "Status flags",
    "sr":           "Audio sample rate (Hz)",
    "ss":           "Audio sample size (bits)",
    "sv":           "Password protected",
    "tp":           "Transport protocols",
    "vn":           "Protocol version number",
    "vs":           "Server version",
    "DyngateID":    "TeamViewer ID",
    "Token":        "Access token",
    "UUID":         "Device UUID",
    "uuid":         "Device UUID",
}

class TypeListener(ServiceListener):
    def __init__(self):
        self.types = set()
    def add_service(self, zeroconf, type_, name):
        self.types.add(name)
    def remove_service(self, *args):
        pass
    def update_service(self, *args):
        pass

class InstanceListener(ServiceListener):
    def __init__(self, collector):
        self.collector = collector

    def add_service(self, zeroconf, type_, name):
        info = zeroconf.get_service_info(type_, name)
        if not info:
            return
        addresses = [socket.inet_ntoa(addr) for addr in info.addresses]
        props = {}
        for k, v in info.properties.items():
            try:
                key = k.decode()
                val = v.decode()
            except:
                key, val = k, v
            props[key] = val
        record = {
            "name": name,
            "type": type_,
            "host": info.server,
            "addresses": addresses,
            "port": info.port,
            "properties": props
        }
        self.collector.append(record)

    def remove_service(self, *args):
        pass
    def update_service(self, *args):
        pass

def browse_types(timeout):
    zc = Zeroconf()
    listener = TypeListener()
    ServiceBrowser(zc, "_services._dns-sd._udp.local.", listener)
    time.sleep(timeout)
    zc.close()
    return listener.types

def browse_instances(service_type, timeout, collector):
    zc = Zeroconf()
    ServiceBrowser(zc, service_type, InstanceListener(collector))
    time.sleep(timeout)
    zc.close()

def output_text(grouped):
    for svc_type, records in grouped.items():
        print(f"===== {svc_type} =====")
        for r in records:
            print(f"->  {r['name']}")
            print(f"    Host: {r['host']} ({', '.join(r['addresses'])})")
            print(f"    Port: {r['port']}")
            if r["properties"]:
                print("    TXT:")
                for key, val in r["properties"].items():
                    label = PROPERTY_DESCRIPTIONS.get(key, key)
                    print(f"      • {label}: {val}")
            print()

def output_json(all_records):
    json.dump(all_records, sys.stdout, indent=2, sort_keys=True)
    print()

def output_csv(all_records):
    writer = csv.writer(sys.stdout)
    writer.writerow(["type","name","host","addresses","port","properties"])
    for r in all_records:
        addrs = ",".join(r["addresses"])
        props = ";".join(f"{k}={v}" for k,v in r["properties"].items())
        writer.writerow([r["type"], r["name"], r["host"], addrs, r["port"], props])

def main():
    parser = argparse.ArgumentParser(description="Discover mDNS services")
    parser.add_argument("-l", "--list-types", action="store_true",
                        help="Just list service types")
    parser.add_argument("-s", "--service-type", metavar="TYPE",
                        help="Browse a single service type (e.g. _http._tcp.local.)")
    parser.add_argument("-A", "--all-services", action="store_true",
                        help="Browse every discovered service type")
    parser.add_argument("-t", "--timeout", type=int, default=5,
                        help="Seconds to listen per browse (default: 5)")
    parser.add_argument("-f", "--format", choices=["text","json","csv"],
                        default="text", help="Output format")
    args = parser.parse_args()

    if not (args.list_types or args.service_type or args.all_services):
        parser.print_usage()
        return

    if args.list_types:
        types = browse_types(args.timeout)
        for t in sorted(types):
            print(t)
        return

    all_records = []
    grouped = {}

    if args.all_services:
        targets = sorted(browse_types(args.timeout))
    else:
        targets = [args.service_type]

    for t in targets:
        grouped[t] = []
        browse_instances(t, args.timeout, collector=grouped[t])
        all_records.extend(grouped[t])

    if args.format == "text":
        output_text(grouped)
    elif args.format == "json":
        output_json(all_records)
    else:
        output_csv(all_records)

if __name__ == "__main__":
    main()