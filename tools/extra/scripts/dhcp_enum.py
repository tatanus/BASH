#!/usr/bin/env python3
# =============================================================================
# NAME        : dhcp_enum.py
# DESCRIPTION : Enumerate DHCPv4 and DHCPv6 servers on the LAN via
#               DISCOVER, INFORM, bogus REQUEST, and SOLICIT messages.
# AUTHOR      : Adam Compton
# DATE CREATED: 2025-04-30 12:00:00
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2025-04-30 12:00:00  | Adam Compton | Initial creation.
# =============================================================================

import argparse
import json
import logging
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

from scapy.all import (
    BOOTP,
    DHCP,
    DHCP6_Advertise,
    DHCP6OptClientId,
    DHCP6OptDNSServers,
    DHCP6OptIAAddress,
    DHCP6OptIA_NA,
    DHCP6OptServerId,
    DHCP6_Solicit,
    Ether,
    IP,
    IPv6,
    UDP,
    conf,
    get_if_addr,
    get_if_hwaddr,
    sendp,
    sniff,
)

# Configure logging
logging.basicConfig(
    format="%(asctime)s [%(levelname)s] %(message)s",
    level=logging.INFO
)
log = logging.getLogger(__name__)


def dhcp_option(opts: list, key: str) -> Optional[Any]:
    """Extract a DHCPv4 option from a list of options.

    Args:
        opts: List of DHCP options.
        key: Option name to extract.

    Returns:
        The value of the matching option, or None.
    """
    for opt in opts:
        if isinstance(opt, tuple) and len(opt) == 2 and opt[0] == key:
            return opt[1]
    return None

def send_discover_and_sniff(iface: str, timeout: int) -> List[Dict[str, Any]]:
    """Send DHCPDISCOVER and sniff for DHCPOFFER responses.

    Args:
        iface: Network interface name.
        timeout: Duration to sniff for responses.

    Returns:
        List of dictionaries containing DHCPOFFER data.
    """
    mac = get_if_hwaddr(iface)
    pkt = (
        Ether(dst="ff:ff:ff:ff:ff:ff", src=mac) /
        IP(src="0.0.0.0", dst="255.255.255.255") /
        UDP(sport=68, dport=67) /
        BOOTP(chaddr=bytes.fromhex(mac.replace(":", ""))) /
        DHCP(options=[
            ("message-type", "discover"),
            ("param_req_list", [1, 3, 6, 15, 42, 51, 54]),
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
        if p.haslayer(DHCP) and dhcp_option(p[DHCP].options, "message-type") == 2:
            opts = p[DHCP].options
            offer = {
                "server_id": dhcp_option(opts, "server_id"),
                "your_ip": p[BOOTP].yiaddr,
                "lease_time": dhcp_option(opts, "lease_time")
            }
            for field in ("subnet_mask", "router", "name_server", "name_servers", "domain", "ntp_server", "ntp_servers"):
                val = dhcp_option(opts, field)
                if val:
                    offer[field] = val if isinstance(val, list) else [val]
            offers.append(offer)
    return offers


def send_request_probe_and_sniff(iface: str, timeout: int, server_id: str, bogus: str = "1.2.3.4") -> List[Dict[str, str]]:
    """Send DHCPREQUEST with bogus IP and sniff for NAKs.

    Args:
        iface: Interface to send packet from.
        timeout: Sniff timeout.
        server_id: Server identifier to target.
        bogus: Bogus IP address to request.

    Returns:
        List of servers that responded with NAK.
    """
    mac = get_if_hwaddr(iface)
    pkt = (
        Ether(dst="ff:ff:ff:ff:ff:ff", src=mac) /
        IP(src="0.0.0.0", dst="255.255.255.255") /
        UDP(sport=68, dport=67) /
        BOOTP(chaddr=bytes.fromhex(mac.replace(":", ""))) /
        DHCP(options=[
            ("message-type", "request"),
            ("server_id", server_id),
            ("requested_addr", bogus),
            ("param_req_list", [1, 3, 6, 15, 42, 51, 54]),
            "end"
        ])
    )
    sendp(pkt, iface=iface, verbose=False)
    replies = sniff(
        iface=iface,
        filter="udp and src port 67 and dst port 68",
        timeout=timeout
    )

    return [
        {"server_id": dhcp_option(p[DHCP].options, "server_id")}
        for p in replies
        if p.haslayer(DHCP) and dhcp_option(p[DHCP].options, "message-type") == 6
    ]


def send_inform_and_sniff(iface: str, timeout: int) -> List[Dict[str, Any]]:
    """Send DHCPINFORM and sniff for DHCPACKs.

    Args:
        iface: Interface to use.
        timeout: Sniff timeout.

    Returns:
        List of ACK response data dictionaries.
    """
    client_ip = get_if_addr(iface)
    if client_ip == "0.0.0.0":
        return []

    mac = get_if_hwaddr(iface)
    pkt = (
        Ether(dst="ff:ff:ff:ff:ff:ff", src=mac) /
        IP(src=client_ip, dst="255.255.255.255") /
        UDP(sport=68, dport=67) /
        BOOTP(ciaddr=client_ip, chaddr=bytes.fromhex(mac.replace(":", ""))) /
        DHCP(options=[
            ("message-type", "inform"),
            ("param_req_list", [1, 3, 6, 15, 42, 51, 54]),
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
        if p.haslayer(DHCP) and dhcp_option(p[DHCP].options, "message-type") == 5:
            opts = p[DHCP].options
            ack = {"server_id": dhcp_option(opts, "server_id")}
            for field in ("subnet_mask", "router", "name_server", "name_servers", "domain", "ntp_server", "ntp_servers"):
                val = dhcp_option(opts, field)
                if val:
                    ack[field] = val if isinstance(val, list) else [val]
            acks.append(ack)
    return acks


def send_solicit_and_sniff_v6(iface: str, timeout: int) -> List[Dict[str, Any]]:
    """Send DHCPv6 Solicit message and sniff for Advertisements.

    Args:
        iface: Interface to use.
        timeout: Sniff timeout.

    Returns:
        List of dictionaries with advertisement data.
    """
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

    advertisements = []
    for p in replies:
        if p.haslayer(DHCP6_Advertise):
            advert: Dict[str, Any] = {}
            if p.haslayer(DHCP6OptServerId):
                advert["server_duid"] = p[DHCP6OptServerId].duid
            if p.haslayer(DHCP6OptClientId):
                advert["client_duid"] = p[DHCP6OptClientId].duid
            if p.haslayer(DHCP6OptIA_NA):
                iana = p[DHCP6OptIA_NA]
                advert["iana_id"] = iana.iaid
                advert["addresses"] = [
                    {
                        "address": opt.addr,
                        "pref_lifetime": opt.preflft,
                        "valid_lifetime": opt.validlft
                    }
                    for opt in iana.ianaopts if isinstance(opt, DHCP6OptIAAddress)
                ]
            if p.haslayer(DHCP6OptDNSServers):
                advert["dns_servers"] = p[DHCP6OptDNSServers].dnsservers
            advertisements.append(advert)
    return advertisements


def print_summary(offers: list, naks: list, acks: list, v6: list) -> None:
    """Display collected DHCPv4 and DHCPv6 data in readable format."""
    sections = [
        ("DHCPv4 Offers", offers),
        ("DHCPv4 NAKs (bogus-request probe)", naks),
        ("DHCPv4 INFORM ACKs", acks),
        ("DHCPv6 Advertisements", v6),
    ]
    for title, items in sections:
        print(f"\n=== {title} ===")
        if not items:
            print("  (none)")
        for i, item in enumerate(items, 1):
            print(f"\n  Entry #{i}:")
            for k, v in item.items():
                print(f"    {k:12s}: {v}")


def main() -> None:
    """Main entry point for DHCP enumeration script."""
    parser = argparse.ArgumentParser(
        description="Enumerate DHCPv4/DHCPv6 servers on the LAN."
    )
    parser.add_argument("-i", "--interface", help="Interface to use (e.g., eth0)", required=False)
    parser.add_argument("-t", "--timeout", type=int, default=5, help="Sniffing timeout in seconds")
    parser.add_argument("-j", "--json-output", help="Path to save JSON output")
    args = parser.parse_args()

    iface = args.interface or conf.iface
    if not iface:
        log.error("No interface specified or detected. Use -i to specify one.")
        sys.exit(1)

    log.info(f"Using interface: {iface}")

    offers = send_discover_and_sniff(iface, args.timeout)
    naks = [nak for o in offers if (sid := o.get("server_id")) for nak in send_request_probe_and_sniff(iface, args.timeout, sid)]
    acks = send_inform_and_sniff(iface, args.timeout)
    v6_ads = send_solicit_and_sniff_v6(iface, args.timeout)

    print_summary(offers, naks, acks, v6_ads)

    if args.json_output:
        out_path = Path(args.json_output)
        result = {
            "dhcp4_offers": offers,
            "dhcp4_naks": naks,
            "dhcp4_acks": acks,
            "dhcp6_ads": v6_ads
        }
        out_path.write_text(json.dumps(result, indent=2))
        log.info(f"JSON results saved to {out_path}")


if __name__ == "__main__":
    try:
        main()
    except PermissionError:
        log.error("Must be run with root privileges.")
        sys.exit(1)
    except KeyboardInterrupt:
        log.warning("Interrupted by user.")
        sys.exit(0)