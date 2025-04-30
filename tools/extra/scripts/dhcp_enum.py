#!/usr/bin/env python3
"""
Name: dhcp_enum.py
Description: Enumerate DHCPv4 (discover, bogus-request probe, inform) and DHCPv6 (solicit) servers on the LAN.
Author: ChatGPT (adapted for Adam Compton)
Date Created: 2025-04-30

Requirements:
  - Python 3.6+
  - scapy (`pip install scapy`)
  - Run as root (CAP_NET_RAW + pcap)

Usage:
  sudo ./dhcp_enum.py -i enp89s0 -t 5        # just print to console
  sudo ./dhcp_enum.py -i enp89s0 -t 5 -j out.json
"""

import argparse, json, sys
from scapy.all import (
    Ether, IP, IPv6, UDP,
    BOOTP, DHCP,
    sniff, sendp, conf,
    get_if_hwaddr, get_if_addr
)
from scapy.layers.dhcp6 import (
    DHCP6_Solicit, DHCP6_Advertise,
    DHCP6OptClientId, DHCP6OptServerId,
    DHCP6OptIA_NA, DHCP6OptIAAddress,
    DHCP6OptDNSServers
)

def dhcp_option(opts, key):
    """Helper to pull DHCPv4 option `key` from options list."""
    for opt in opts:
        if isinstance(opt, tuple) and opt[0] == key:
            return opt[1]
    return None

def send_discover_and_sniff(iface, timeout):
    """Broadcast DHCPDISCOVER, sniff for DHCPOFFERs for `timeout` seconds."""
    mac = get_if_hwaddr(iface)
    pkt = (
        Ether(dst="ff:ff:ff:ff:ff:ff", src=mac) /
        IP(src="0.0.0.0",       dst="255.255.255.255") /
        UDP(sport=68, dport=67) /
        BOOTP(chaddr=bytes.fromhex(mac.replace(":", ""))) /
        DHCP(options=[
            ("message-type","discover"),
            ("param_req_list",[1,3,6,15,42,51,54]),
            "end"
        ])
    )
    sendp(pkt, iface=iface, verbose=False)
    replies = sniff(
        iface=iface,
        filter="udp and src port 67 and dst port 68",
        timeout=timeout
    )
    offers = []
    for p in replies:
        if p.haslayer(DHCP) and dhcp_option(p[DHCP].options,"message-type")==2:
            opts = p[DHCP].options
            o = {
                "server_id":   dhcp_option(opts,"server_id"),
                "your_ip":     p[BOOTP].yiaddr,
                "lease_time":  dhcp_option(opts,"lease_time"),
            }
            for f in ("subnet_mask","router","name_server","name_servers","domain","ntp_server","ntp_servers"):
                v = dhcp_option(opts,f)
                if v:
                    if not isinstance(v, list):
                        v = [v]
                    o[f] = v
            offers.append(o)
    return offers

def send_request_probe_and_sniff(iface, timeout, server_id, bogus="1.2.3.4"):
    """Send bogus DHCPREQUEST → sniff for NAKs (msg-type 6)."""
    mac = get_if_hwaddr(iface)
    pkt = (
        Ether(dst="ff:ff:ff:ff:ff:ff", src=mac) /
        IP(src="0.0.0.0",       dst="255.255.255.255") /
        UDP(sport=68, dport=67) /
        BOOTP(chaddr=bytes.fromhex(mac.replace(":", ""))) /
        DHCP(options=[
            ("message-type","request"),
            ("server_id", server_id),
            ("requested_addr", bogus),
            ("param_req_list",[1,3,6,15,42,51,54]),
            "end"
        ])
    )
    sendp(pkt, iface=iface, verbose=False)
    replies = sniff(
        iface=iface,
        filter="udp and src port 67 and dst port 68",
        timeout=timeout
    )
    naks = []
    for p in replies:
        if p.haslayer(DHCP) and dhcp_option(p[DHCP].options,"message-type")==6:
            n = {"server_id": dhcp_option(p[DHCP].options,"server_id")}
            naks.append(n)
    return naks

def send_inform_and_sniff(iface, timeout):
    """Send DHCPINFORM → sniff for ACKs (msg-type 5)."""
    client_ip = get_if_addr(iface)
    if client_ip == "0.0.0.0":
        return []
    mac = get_if_hwaddr(iface)
    pkt = (
        Ether(dst="ff:ff:ff:ff:ff:ff", src=mac) /
        IP(src=client_ip,      dst="255.255.255.255") /
        UDP(sport=68, dport=67) /
        BOOTP(ciaddr=client_ip, chaddr=bytes.fromhex(mac.replace(":", ""))) /
        DHCP(options=[
            ("message-type","inform"),
            ("param_req_list",[1,3,6,15,42,51,54]),
            "end"
        ])
    )
    sendp(pkt, iface=iface, verbose=False)
    replies = sniff(
        iface=iface,
        filter="udp and src port 67 and dst port 68",
        timeout=timeout
    )
    acks = []
    for p in replies:
        if p.haslayer(DHCP) and dhcp_option(p[DHCP].options,"message-type")==5:
            info = {"server_id": dhcp_option(p[DHCP].options,"server_id")}

            opts = p[DHCP].options
            for f in ("subnet_mask","router","name_server","name_servers","domain","ntp_server","ntp_servers"):
                v = dhcp_option(opts,f)
                if v:
                    if not isinstance(v, list):
                        v = [v]
                    info[f] = v
            acks.append(info)
    return acks

def send_solicit_and_sniff_v6(iface, timeout):
    """Send DHCPv6 Solicit, sniff for Advertisements."""
    pkt = (
        Ether(dst="33:33:00:01:00:02") /
        IPv6(dst="ff02::1:2") /
        UDP(sport=546, dport=547) /
        DHCP6_Solicit() /
        DHCP6OptClientId() /
        DHCP6OptIA_NA()
    )
    sendp(pkt, iface=iface, verbose=False)
    replies = sniff(
        iface=iface,
        filter="udp and src port 547 and dst port 546",
        timeout=timeout
    )
    ads = []
    for p in replies:
        if p.haslayer(DHCP6_Advertise):
            info = {}
            if p.haslayer(DHCP6OptServerId):
                info["server_duid"] = p[DHCP6OptServerId].duid
            if p.haslayer(DHCP6OptClientId):
                info["client_duid"] = p[DHCP6OptClientId].duid
            if p.haslayer(DHCP6OptIA_NA):
                na = p[DHCP6OptIA_NA]
                info["iana_id"] = na.iaid
                addrs = []
                for opt in na.ianaopts:
                    if isinstance(opt, DHCP6OptIAAddress):
                        addrs.append({
                            "address":        opt.addr,
                            "pref_lifetime":  opt.preflft,
                            "valid_lifetime": opt.validlft
                        })
                if addrs:
                    info["addresses"] = addrs
            if p.haslayer(DHCP6OptDNSServers):
                info["dns_servers"] = p[DHCP6OptDNSServers].dnsservers
            ads.append(info)
    return ads

def print_summary(off, naks, acks, v6):
    print("\n=== DHCPv4 Offers ===")
    if not off:        print("  (none)")
    for i,o in enumerate(off,1):
        print(f"\n  Offer #{i}:")
        for k,v in o.items():
            print(f"    {k:12s}: {v}")

    print("\n=== DHCPv4 NAKs (bogus-request probe) ===")
    if not naks:       print("  (none)")
    for i,n in enumerate(naks,1):
        print(f"  NAK #{i}: server_id={n['server_id']}")

    print("\n=== DHCPv4 INFORM ACKs ===")
    if not acks:       print("  (none)")
    for i,a in enumerate(acks,1):
        print(f"\n  ACK #{i}:")
        for k,v in a.items():
            print(f"    {k:12s}: {v}")

    print("\n=== DHCPv6 Advertisements ===")
    if not v6:         print("  (none)")
    for i,a in enumerate(v6,1):
        print(f"\n  Advert #{i}:")
        for k,v in a.items():
            print(f"    {k:12s}: {v}")

def main():
    p = argparse.ArgumentParser()
    p.add_argument("-i","--interface", help="Interface to use")
    p.add_argument("-t","--timeout", type=int, default=5, help="Seconds to sniff")
    p.add_argument("-j","--json-output", help="Write results to JSON file")
    args = p.parse_args()

    iface = args.interface or conf.iface
    if not iface:
        print("ERROR: specify -i", file=sys.stderr)
        sys.exit(1)

    print(f"[*] Using interface: {iface}")
    offers = send_discover_and_sniff(iface, args.timeout)

    # probe with bogus REQUEST → NAK
    naks = []
    for o in offers:
        sid = o.get("server_id")
        if sid:
            naks += send_request_probe_and_sniff(iface, args.timeout, sid)

    # DHCPINFORM → ACK (if client already has an IP)
    acks = send_inform_and_sniff(iface, args.timeout)

    # DHCPv6 Solicit → Advertisements
    v6_ads = send_solicit_and_sniff_v6(iface, args.timeout)

    print_summary(offers, naks, acks, v6_ads)

    if args.json_output:
        out = {
            "dhcp4_offers": offers,
            "dhcp4_naks":   naks,
            "dhcp4_acks":   acks,
            "dhcp6_ads":    v6_ads
        }
        with open(args.json-output, "w") as f:
            json.dump(out, f, indent=2)
        print(f"\n[+] JSON written to {args.json_output}")

if __name__=="__main__":
    try:
        main()
    except PermissionError:
        print("ERROR: must run as root.", file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nInterrupted; exiting.", file=sys.stderr)
        sys.exit(0)