#!/usr/bin/env python3
"""
UPnP Enumeration & Management Tool
--------------------------------------------------------------

Sections:
1) Global Defaults & Imports
2) SSDP Discovery
3) Device Descriptor Parsing
4) SCPD & SOAP
5) IGD Port Mapping
6) Event Subscription (CallStranger)
7) Additional Enumerations (ContentDirectory / WPS)
8) Main Enumeration Workflow
9) Output Formatting (JSON/XML) to file
10) Command-Line Entry Point
"""

import argparse
import base64
import datetime
import json
import os
import re
import socket
import struct
import sys
import time
import urllib.parse
import xml.etree.ElementTree as ET
from typing import Dict, List, Optional, Tuple, Union

import requests


###############################################################################
#                     (1) GLOBAL DEFAULTS & IMPORTS                           #
###############################################################################

SSDP_MCAST_ADDR = "239.255.255.250"
SSDP_PORT = 1900

# A typical default list of ST (Search Target) values
ST_LIST = [
    # =============================================================================
    # 1. Generic / Universal
    # =============================================================================
    "ssdp:all",                    # Discover ALL UPnP devices/services
    "upnp:rootdevice",             # Discover only root (top-level) devices
    "uuid:<Device-UUID>",          # Placeholder to discover a device by a known UUID (replace <Device-UUID>)

    # =============================================================================
    # 2. Core UPnP Device Types
    # (Basic, Manageable, etc. - sometimes also used for simple IoT devices)
    # =============================================================================
    "urn:schemas-upnp-org:device:Basic:1",            # Generic 'Basic' device type
    "urn:schemas-upnp-org:device:ManageableDevice:1", # Device supporting remote management
    "urn:schemas-upnp-org:device:ManageableDevice:2", # Newer version of ManageableDevice

    # =============================================================================
    # 3. Routers / Gateways / Networking (UPnP Internet Gateway Device)
    # =============================================================================
    "urn:schemas-upnp-org:device:InternetGatewayDevice:1",  # IGD v1 (home router / gateway)
    "urn:schemas-upnp-org:device:InternetGatewayDevice:2",  # IGD v2 (newer router/gateway)
    "urn:schemas-upnp-org:device:WANDevice:1",              # WAN device (IGD v1 sub-device)
    "urn:schemas-upnp-org:device:WANDevice:2",              # WAN device (IGD v2 sub-device)
    "urn:schemas-upnp-org:device:WANConnectionDevice:1",    # WAN connection device (IGD v1)
    "urn:schemas-upnp-org:device:WANConnectionDevice:2",    # WAN connection device (IGD v2)
    "urn:schemas-upnp-org:device:LANDevice:1",              # LAN device (often embedded under IGD)
    "urn:schemas-upnp-org:device:WLANAccessPointDevice:1",  # Wi-Fi access point device

    # =============================================================================
    # 4. UPnP WAN/Networking Service Types
    # (Sometimes devices only respond if you query their service URN)
    # =============================================================================
    "urn:schemas-upnp-org:service:WANIPConnection:1",       # WAN IP Connection v1 (port forwarding, etc.)
    "urn:schemas-upnp-org:service:WANIPConnection:2",       # WAN IP Connection v2
    "urn:schemas-upnp-org:service:WANPPPConnection:1",      # WAN PPP Connection v1
    "urn:schemas-upnp-org:service:WANPPPConnection:2",      # WAN PPP Connection v2
    "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1", # WAN interface info (link status, etc.)
    "urn:schemas-upnp-org:service:Layer3Forwarding:1",      # Layer 3 Forwarding (routing)
    
    # =============================================================================
    # 5. Media & Entertainment Devices (Servers, Renderers, etc.)
    # =============================================================================
    "urn:schemas-upnp-org:device:MediaServer:1",     # UPnP/DLNA Media Server v1
    "urn:schemas-upnp-org:device:MediaServer:2",     # Media Server v2
    "urn:schemas-upnp-org:device:MediaServer:3",     # Media Server v3
    "urn:schemas-upnp-org:device:MediaServer:4",     # Media Server v4
    "urn:schemas-upnp-org:device:MediaRenderer:1",   # UPnP/DLNA Media Renderer v1
    "urn:schemas-upnp-org:device:MediaRenderer:2",   # Media Renderer v2
    "urn:schemas-upnp-org:device:MediaRenderer:3",   # Media Renderer v3
    "urn:schemas-upnp-org:device:MediaPlayer:1",     # Legacy or combined 'MediaPlayer'
    "urn:schemas-upnp-org:device:MediaAdapter:1",    # Media adapter/extender
    "urn:schemas-upnp-org:device:TVDevice:1",        # TV device template (used by some smart TVs)
    "urn:microsoft-com:device:MediaCenterExtender:1",# Windows Media Center Extender (e.g., Xbox)

    # =============================================================================
    # 6. Media/Content Services
    # =============================================================================
    "urn:schemas-upnp-org:service:ContentDirectory:1",  # Content listing (part of media server)
    "urn:schemas-upnp-org:service:ConnectionManager:1", # Manages streaming connections

    # =============================================================================
    # 7. Casting / Streaming Protocols (DIAL, Roku, etc.)
    # =============================================================================
    "urn:dial-multiscreen-org:device:dial:1",       # DIAL device discovery (Chromecast, certain smart TVs)
    "urn:dial-multiscreen-org:service:dial:1",      # DIAL service
    "roku:ecp",                                     # Roku External Control Protocol
    "udap:rootservice",                             # LG UDAP (legacy LG Smart TV)

    # =============================================================================
    # 8. Sonos & Other Multiroom Audio Vendors
    # =============================================================================
    "urn:schemas-upnp-org:device:ZonePlayer:1",           # Sonos ZonePlayer
    "urn:schemas-denon-com:device:ACT-Denon:1",           # Older Denon AVR
    "urn:schemas-denon-com:device:AiosDevice:1",          # Denon/Marantz HEOS
    "urn:schemas-denon-com:device:AiosServices:1",        # Denon/Marantz HEOS service container
    "urn:schemas-nuvotechnologies-com:device:Zone:1",     # Nuvo multiroom audio
    "urn:schemas-raumfeld-com:device:RaumfeldDevice:1",   # Raumfeld (Teufel) speaker
    "urn:schemas-raumfeld-com:device:ConfigDevice:1",     # Raumfeld config

    # =============================================================================
    # 9. Printers & Imaging Devices
    # =============================================================================
    "urn:schemas-upnp-org:device:Printer:1",         # Network printer
    "urn:schemas-upnp-org:device:Scanner:1",         # Network scanner
    "urn:schemas-upnp-org:device:NAS:1",             # Some devices label themselves as 'NAS'
    "urn:schemas-upnp-org:device:NetworkStorageDevice:1", # Network storage device
    "urn:schemas-cipa-jp:device:DPSPrinter:1",       # CIPA Digital Photo Print

    # =============================================================================
    # 10. Cameras & Security
    # =============================================================================
    "urn:schemas-upnp-org:device:DigitalSecurityCamera:1",       # Single IP camera
    "urn:schemas-upnp-org:device:DigitalSecurityCameraSystem:1", # Multiple cameras / DVR
    "urn:schemas-upnp-org:device:WirelessNetworkCamera:1",       # Wireless IP camera
    "urn:upnp-logitech-com:device:SecurityDevice:1",             # Logitech security device

    # =============================================================================
    # 11. Smart Home / IoT (Lights, Thermostats, DoorLocks, etc.)
    # =============================================================================
    "urn:schemas-upnp-org:device:BinaryLight:1",        # Simple On/Off light or switch
    "urn:schemas-upnp-org:device:DimmableLight:1",      # Light supporting dimming
    "urn:schemas-upnp-org:device:HVAC_System:1",        # HVAC system (heating/cooling)
    "urn:schemas-upnp-org:device:HVAC_ZoneThermostat:1",# Thermostat for a zone
    "urn:schemas-upnp-org:device:DoorLock:1",           # Smart door lock
    "urn:schemas-upnp-org:device:SolarProtectionBlind:1", # Motorized/automated blinds

    # =============================================================================
    # 12. Belkin WeMo Devices
    # =============================================================================
    "urn:Belkin:device:controllee:1",  # WeMo Switch (generic on/off)
    "urn:Belkin:device:lightswitch:1", # WeMo wall light switch
    "urn:Belkin:device:insight:1",     # WeMo Insight Switch (power monitoring)
    "urn:Belkin:device:sensor:1",      # WeMo Motion Sensor
    "urn:Belkin:device:dimmer:1",      # WeMo Dimmer Switch
    "urn:Belkin:device:bridge:1",      # WeMo Link/Bridge (for WeMo LED bulbs)
    "urn:Belkin:device:netcamsensor:1",# WeMo NetCam
    "urn:Belkin:device:Maker:1",       # WeMo Maker (DIY relay+sensor)
    "urn:Belkin:device:CoffeeMaker:1", # WeMo Coffee Maker
    "urn:Belkin:device:controller1",   # WeMo Controller (rare/proprietary device type)

    # =============================================================================
    # 13. Remote UI & Misc. Devices
    # =============================================================================
    "urn:schemas-upnp-org:device:RemoteUIServerDevice:1",  # Remote UI Server
    "urn:schemas-upnp-org:device:RemoteUIClientDevice:1",  # Remote UI Client
    "urn:microsoft-com:device:ProductAgent:1",             # Windows Media Player / ProductAgent
    "urn:microsoft-com:device:DimmerDevice:1",             # Microsoft sample Dimmer Device (SDK)
    "urn:schemas-bmlinks-jp:device:BMLinks:1",             # Japan BML standard
    "urn:www-seagate-com:device:NASOS:1",                  # Seagate NAS OS
    "urn:www-seagate-com:device:BANAS:2",                  # Seagate Business NAS
    "urn:bouygues-telecom-com:device:BboxTV:1",            # Bouygues Telecom Bbox TV (IPTV set-top box)
    "urn:schemas-wifialliance-org:device:WFADevice:1",     # Wi-Fi Alliance device (Wi-Fi Direct, Miracast)
]


###############################################################################
#                      (2) SSDP DISCOVERY FUNCTIONS                           #
###############################################################################

def build_msearch_request(st: str, mx: int = 2, verbose: bool = False, quiet: bool = False) -> str:
    if verbose and not quiet:
        print(f"[VERBOSE] Building M-SEARCH request for ST={st}, MX={mx}")
    return (
        "M-SEARCH * HTTP/1.1\r\n"
        f"HOST: {SSDP_MCAST_ADDR}:{SSDP_PORT}\r\n"
        'MAN: "ssdp:discover"\r\n'
        f"ST: {st}\r\n"
        f"MX: {mx}\r\n"
        "\r\n"
    )


def send_msearch(
    st: str,
    target: Optional[str],
    timeout: float = 2.0,
    mx: int = 2,
    verbose: bool = False,
    quiet: bool = False
) -> List[Tuple[str, Tuple[str, int]]]:
    responses = []
    msearch_data = build_msearch_request(st, mx=mx, verbose=verbose, quiet=quiet).encode("utf-8")

    if verbose and not quiet and target:
        print(f"[VERBOSE] Sending unicast M-SEARCH (ST={st}) to {target}:{SSDP_PORT}")
    elif verbose and not quiet:
        print(f"[VERBOSE] Sending multicast M-SEARCH (ST={st}) to {SSDP_MCAST_ADDR}:{SSDP_PORT}")

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.settimeout(timeout)
        destination = (target or SSDP_MCAST_ADDR, SSDP_PORT)

        try:
            sock.sendto(msearch_data, destination)
        except socket.error as e:
            if not quiet:
                print(f"[ERROR] Unable to send M-SEARCH (ST={st}): {e}")
            return responses

        start_time = time.time()
        while True:
            if time.time() - start_time > timeout:
                break
            try:
                data, addr = sock.recvfrom(65507)
                resp_str = data.decode("utf-8", errors="replace")
                responses.append((resp_str, addr))
            except socket.timeout:
                break
            except Exception as e:
                if not quiet:
                    print(f"[ERROR] Exception receiving SSDP response: {e}")
                break

    if verbose and not quiet:
        print(f"[VERBOSE] Received {len(responses)} responses for ST={st}")
    return responses


def parse_ssdp_responses(
    responses: List[Tuple[str, Tuple[str, int]]],
    verbose: bool = False,
    quiet: bool = False
) -> Dict[str, Dict[str, Union[str, Tuple[str, int]]]]:
    discovered = {}
    for resp, (ip, port) in responses:
        lines = resp.split("\r\n")
        location = None
        server = None
        usn = None
        st = None

        for line in lines:
            lower = line.lower()
            if lower.startswith("location:"):
                location = line.split(":", 1)[1].strip()
            elif lower.startswith("server:"):
                server = line.split(":", 1)[1].strip()
            elif lower.startswith("usn:"):
                usn = line.split(":", 1)[1].strip()
            elif lower.startswith("st:"):
                st = line.split(":", 1)[1].strip()

        if location:
            discovered[location] = {
                "LOCATION": location,
                "SERVER": server if server else "",
                "ST": st if st else "",
                "USN": usn if usn else "",
                "addr": (ip, port)
            }

    if verbose and not quiet and discovered:
        print(f"[VERBOSE] parse_ssdp_responses discovered {len(discovered)} unique LOCATION entries.")
    return discovered


###############################################################################
#                  (3) DEVICE DESCRIPTOR PARSING FUNCTIONS                    #
###############################################################################

def store_malformed_xml(raw_data: str, location: str, verbose: bool = False, quiet: bool = False) -> str:
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_loc = location.replace(":", "_").replace("/", "_").replace("\\", "_")
    filename = f"malformed_{safe_loc}_{timestamp}.xml"

    with open(filename, "w", encoding="utf-8") as f:
        f.write(raw_data)

    if verbose and not quiet:
        print(f"[VERBOSE] Malformed XML stored at {os.path.abspath(filename)}")

    return os.path.abspath(filename)


def fetch_device_description(url: str, verbose: bool = False, quiet: bool = False) -> Optional[str]:
    try:
        if verbose and not quiet:
            print(f"[VERBOSE] Fetching device description from {url}")
        resp = requests.get(url, timeout=5)
        resp.raise_for_status()

        ctype = resp.headers.get("Content-Type", "").lower()
        if "xml" not in ctype and verbose and not quiet:
            print(f"[WARNING] Content-Type '{ctype}' from {url} might not be valid XML.")

        return resp.text
    except requests.exceptions.RequestException as e:
        if not quiet:
            print(f"[ERROR] Could not fetch device description from {url}: {e}")
        return None


def derive_base_url(location: str, url_base: str) -> str:
    url_base = (url_base or "").strip()
    if url_base.lower().startswith("http"):
        return url_base

    if url_base:
        return urllib.parse.urljoin(location, url_base)

    parsed = urllib.parse.urlparse(location)
    return f"{parsed.scheme}://{parsed.netloc}"


def parse_all_devices(
    xml_data: str,
    device_location: str,
    verbose: bool = False,
    quiet: bool = False
) -> List[Dict[str, Union[str, List]]]:
    devices_info = []
    try:
        root = ET.fromstring(xml_data)
    except ET.ParseError as e:
        if not quiet:
            print(f"[WARNING] Malformed device descriptor at {device_location}: {e}")
        path = store_malformed_xml(xml_data, device_location, verbose=verbose, quiet=quiet)
        if not quiet:
            print(f"    [!] Stored invalid XML at {path}")
        return []

    url_base_elem = root.find("{*}URLBase")
    url_base = url_base_elem.text if (url_base_elem is not None and url_base_elem.text) else ""
    resolved_base = derive_base_url(device_location, url_base)

    device_elems = root.findall(".//{*}device")
    if not device_elems:
        return devices_info

    for dev_elem in device_elems:
        info = {
            "deviceType": "",
            "friendlyName": "",
            "manufacturer": "",
            "manufacturerURL": "",
            "modelDescription": "",
            "modelName": "",
            "modelNumber": "",
            "serialNumber": "",
            "UDN": "",
            "presentationURL": "",
            "iconList": [],
            "services": [],
            "resolvedBase": resolved_base
        }

        fields = [
            "deviceType", "friendlyName", "manufacturer", "manufacturerURL",
            "modelDescription", "modelName", "modelNumber", "serialNumber",
            "UDN", "presentationURL"
        ]
        for tag in fields:
            elem = dev_elem.find(f".//{{*}}{tag}")
            if elem is not None and elem.text:
                info[tag] = elem.text.strip()

        icon_list = dev_elem.find(".//{*}iconList")
        if icon_list is not None:
            for icon in icon_list.findall("{*}icon"):
                icon_dict = {
                    "mimetype": icon.findtext("{*}mimetype", "").strip(),
                    "width": icon.findtext("{*}width", "").strip(),
                    "height": icon.findtext("{*}height", "").strip(),
                    "depth": icon.findtext("{*}depth", "").strip(),
                    "url": icon.findtext("{*}url", "").strip(),
                }
                info["iconList"].append(icon_dict)

        service_list = dev_elem.find(".//{*}serviceList")
        if service_list is not None:
            for svc in service_list.findall("{*}service"):
                svc_data = {
                    "serviceType": svc.findtext("{*}serviceType", default="").strip(),
                    "serviceId": svc.findtext("{*}serviceId", default="").strip(),
                    "controlURL": svc.findtext("{*}controlURL", default="").strip(),
                    "eventSubURL": svc.findtext("{*}eventSubURL", default="").strip(),
                    "SCPDURL": svc.findtext("{*}SCPDURL", default="").strip(),
                    "actions": [],
                    "portMappings": [],
                    "contentDirectory": [],
                    "wpsDeviceInfo": []
                }
                info["services"].append(svc_data)

        devices_info.append(info)

    if verbose and not quiet:
        print(f"[VERBOSE] parse_all_devices found {len(devices_info)} device block(s) in {device_location}")

    return devices_info


###############################################################################
#                        (4) SCPD & SOAP FUNCTIONS                            #
###############################################################################

def fetch_scpd(scpd_url: str, base_url: str, verbose: bool = False, quiet: bool = False) -> Optional[str]:
    if not scpd_url:
        return None

    if not scpd_url.lower().startswith("http"):
        if base_url:
            scpd_url = urllib.parse.urljoin(base_url + "/", scpd_url)
        else:
            if not quiet:
                print(f"[WARNING] Unable to resolve relative SCPD URL: {scpd_url}")
            return None

    if verbose and not quiet:
        print(f"[VERBOSE] Fetching SCPD from {scpd_url}")

    try:
        resp = requests.get(scpd_url, timeout=5)
        resp.raise_for_status()
        ctype = resp.headers.get("Content-Type", "").lower()
        if "xml" not in ctype and verbose and not quiet:
            print(f"[WARNING] SCPD at {scpd_url} might not be valid XML.")
        return resp.text
    except requests.exceptions.RequestException as e:
        if not quiet:
            print(f"[WARNING] Failed to fetch SCPD from {scpd_url}: {e}")
        return None


def parse_scpd_actions(scpd_xml: str, verbose: bool = False, quiet: bool = False) -> List[Dict[str, Union[str, List]]]:
    actions = []
    if not scpd_xml:
        return actions

    try:
        root = ET.fromstring(scpd_xml)
    except ET.ParseError as e:
        if not quiet:
            print(f"[WARNING] Parse error in SCPD: {e}")
        return actions

    action_list = root.find(".//{*}actionList")
    if not action_list:
        return actions

    for action_elem in action_list.findall("{*}action"):
        name_elem = action_elem.find("{*}name")
        action_name = name_elem.text.strip() if (name_elem is not None and name_elem.text) else "UnnamedAction"
        arg_list = []

        argument_list_elem = action_elem.find("{*}argumentList")
        if argument_list_elem:
            for arg_elem in argument_list_elem.findall("{*}argument"):
                arg_name = arg_elem.findtext("{*}name", "").strip()
                arg_dir = arg_elem.findtext("{*}direction", "").strip()
                arg_var = arg_elem.findtext("{*}relatedStateVariable", "").strip()
                arg_list.append({
                    "name": arg_name,
                    "direction": arg_dir,
                    "relatedStateVariable": arg_var
                })

        actions.append({
            "name": action_name,
            "arguments": arg_list
        })

    if verbose and not quiet:
        print(f"[VERBOSE] Found {len(actions)} actions in SCPD.")
    return actions


def soap_call(control_url: str, service_type: str, action_name: str, body_xml: str,
              verbose: bool = False, quiet: bool = False) -> Optional[str]:
    soap_action = f"{service_type}#{action_name}"
    envelope = f"""<?xml version="1.0"?>
<s:Envelope
    xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
    s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:{action_name} xmlns:u="{service_type}">
      {body_xml}
    </u:{action_name}>
  </s:Body>
</s:Envelope>"""

    headers = {
        "Content-Type": "text/xml; charset=utf-8",
        "SOAPAction": soap_action
    }

    if verbose and not quiet:
        print(f"[VERBOSE] SOAP POST to {control_url}, Action={soap_action}")

    try:
        resp = requests.post(control_url, data=envelope, headers=headers, timeout=5)
        if resp.status_code == 200:
            return resp.text
        else:
            if not quiet:
                print(f"      [!] SOAP action '{action_name}' returned status {resp.status_code}")
            return None
    except requests.exceptions.RequestException as e:
        if not quiet:
            print(f"      [!] SOAP action '{action_name}' failed: {e}")
        return None


###############################################################################
#                     (5) IGD (PORT MAPPING) FUNCTIONS                        #
###############################################################################

def get_external_ip(service_info: Dict[str, Union[str, list]], base_url: str, verbose: bool = False, quiet: bool = False) -> None:
    st = service_info["serviceType"]
    if not any(x in st for x in ("WANIPConnection", "WANPPPConnection")):
        return

    control_url = service_info["controlURL"]
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    if not quiet:
        print(f"      [*] Trying GetExternalIPAddress on {control_url}")
    resp = soap_call(control_url, st, "GetExternalIPAddress", "", verbose=verbose, quiet=quiet)
    if resp:
        try:
            root = ET.fromstring(resp)
            ip_elem = root.find(".//{*}NewExternalIPAddress")
            if ip_elem is not None and ip_elem.text:
                if not quiet:
                    print(f"      [+] External IP: {ip_elem.text}")
            else:
                if not quiet:
                    print("      [!] No IP found in SOAP response.")
        except ET.ParseError as e:
            if not quiet:
                print(f"      [!] SOAP parse error: {e}")


def enumerate_port_mappings(
    service_info: Dict[str, Union[str, list]],
    base_url: str,
    max_mappings: int = 1,
    verbose: bool = False,
    quiet: bool = False
) -> List[Dict[str, str]]:
    st = service_info["serviceType"]
    if not any(x in st for x in ("WANIPConnection", "WANPPPConnection")):
        return []

    control_url = service_info["controlURL"]
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    mappings = []
    index = 0
    while True:
        if max_mappings != -1 and index >= max_mappings:
            break

        if not quiet:
            print(f"      [*] GetGenericPortMappingEntry(index={index}) -> {control_url}")
        resp = soap_call(control_url, st, "GetGenericPortMappingEntry",
                         f"<NewPortMappingIndex>{index}</NewPortMappingIndex>",
                         verbose=verbose, quiet=quiet)
        if not resp:
            break

        try:
            root = ET.fromstring(resp)
            new_ext_port = root.find(".//{*}NewExternalPort")
            new_int_port = root.find(".//{*}NewInternalPort")
            new_int_client = root.find(".//{*}NewInternalClient")
            new_proto = root.find(".//{*}NewProtocol")
            new_desc = root.find(".//{*}NewPortMappingDescription")
            new_host = root.find(".//{*}NewRemoteHost")

            if (not new_ext_port) and (not new_int_client):
                if not quiet:
                    print("      [!] No port mapping found at this index.")
                break

            ext_port_val = new_ext_port.text if new_ext_port is not None else ""
            int_port_val = new_int_port.text if new_int_port is not None else ""
            int_host_val = new_int_client.text if new_int_client is not None else ""
            proto_val = new_proto.text if new_proto is not None else ""
            desc_val = new_desc.text if new_desc is not None else ""
            host_val = new_host.text if (new_host is not None and new_host.text) else "*"

            if not quiet:
                print(f"      [+] Port Mapping #{index}:")
                print(f"          External Port: {ext_port_val}")
                print(f"          Internal Port: {int_port_val}")
                print(f"          Internal Host: {int_host_val}")
                print(f"          Protocol:      {proto_val}")
                print(f"          Description:   {desc_val}")

            mappings.append({
                "index": str(index),
                "externalHost": host_val,
                "externalPort": ext_port_val,
                "internalHost": int_host_val,
                "internalPort": int_port_val,
                "protocol": proto_val,
                "description": desc_val
            })

        except ET.ParseError as e:
            if not quiet:
                print(f"      [!] SOAP parse error enumerating mappings: {e}")
            break

        index += 1

    return mappings


def add_port_mapping(
    service_info: Dict[str, Union[str, list]],
    base_url: str,
    ext_port: int,
    int_port: int,
    int_client: str,
    protocol: str,
    description: str,
    lease: int,
    verbose: bool = False,
    quiet: bool = False
) -> None:
    st = service_info["serviceType"]
    if not any(x in st for x in ("WANIPConnection", "WANPPPConnection")):
        return

    control_url = service_info["controlURL"]
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    if not quiet:
        print(f"      [*] Attempting AddPortMapping on {control_url}")
    resp = soap_call(control_url, st, "AddPortMapping", f"""
<NewRemoteHost></NewRemoteHost>
<NewExternalPort>{ext_port}</NewExternalPort>
<NewProtocol>{protocol}</NewProtocol>
<NewInternalPort>{int_port}</NewInternalPort>
<NewInternalClient>{int_client}</NewInternalClient>
<NewEnabled>1</NewEnabled>
<NewPortMappingDescription>{description}</NewPortMappingDescription>
<NewLeaseDuration>{lease}</NewLeaseDuration>
""".strip(), verbose=verbose, quiet=quiet)
    if resp:
        if not quiet:
            print("      [+] Port mapping added successfully.")
    else:
        if not quiet:
            print("      [!] Failed to add port mapping.")


def remove_port_mapping(
    service_info: Dict[str, Union[str, list]],
    base_url: str,
    ext_port: int,
    protocol: str,
    verbose: bool = False,
    quiet: bool = False
) -> None:
    st = service_info["serviceType"]
    if not any(x in st for x in ("WANIPConnection", "WANPPPConnection")):
        return

    control_url = service_info["controlURL"]
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    if not quiet:
        print(f"      [*] Attempting DeletePortMapping on {control_url}")
    resp = soap_call(control_url, st, "DeletePortMapping", f"""
<NewRemoteHost></NewRemoteHost>
<NewExternalPort>{ext_port}</NewExternalPort>
<NewProtocol>{protocol}</NewProtocol>
""".strip(), verbose=verbose, quiet=quiet)
    if resp:
        if not quiet:
            print("      [+] Port mapping removed successfully.")
    else:
        if not quiet:
            print("      [!] Failed to remove port mapping.")


###############################################################################
#                 (6) EVENT SUBSCRIPTION (CALLSTRANGER)                      #
###############################################################################

def subscribe_event(
    event_sub_url: str,
    base_url: str,
    callback_url: str,
    subscribe_timeout: int = 1800,
    verbose: bool = False,
    quiet: bool = False
) -> None:
    if not event_sub_url:
        return

    if not event_sub_url.lower().startswith("http"):
        event_sub_url = urllib.parse.urljoin(base_url + "/", event_sub_url)

    if verbose and not quiet:
        print(f"[VERBOSE] Sending SUBSCRIBE to {event_sub_url} with callback={callback_url}")

    headers = {
        "CALLBACK": f"<{callback_url}>",
        "NT": "upnp:event",
        "TIMEOUT": f"Second-{subscribe_timeout}"
    }

    try:
        resp = requests.request("SUBSCRIBE", event_sub_url, headers=headers, timeout=5)
        if 200 <= resp.status_code < 300:
            sid = resp.headers.get("SID", "")
            if not quiet:
                print(f"         [+] SUBSCRIBE success! SID={sid} (status {resp.status_code})")
        else:
            if not quiet:
                print(f"         [!] SUBSCRIBE returned {resp.status_code} {resp.reason}")
    except requests.exceptions.RequestException as e:
        if not quiet:
            print(f"         [!] SUBSCRIBE failed: {e}")


###############################################################################
#          (7) ADDITIONAL ENUMERATIONS (ContentDirectory / WPS)               #
###############################################################################

def browse_content_directory(
    control_url: str,
    service_type: str,
    verbose: bool = False,
    quiet: bool = False
) -> List[str]:
    folders = []
    resp_xml = soap_call(control_url, service_type, "Browse", """<ObjectID>0</ObjectID>
<BrowseFlag>BrowseDirectChildren</BrowseFlag>
<Filter>*</Filter>
<StartingIndex>0</StartingIndex>
<RequestedCount>10</RequestedCount>
<SortCriteria></SortCriteria>""", verbose=verbose, quiet=quiet)
    if not resp_xml:
        if not quiet:
            print("         [!] ContentDirectory Browse request failed or returned no data.")
        return folders

    try:
        root = ET.fromstring(resp_xml)
        result_elem = root.find(".//{*}Result")
        if result_elem is None or not result_elem.text:
            if not quiet:
                print("         [!] No <Result> found in Browse response.")
            return folders

        didl_root = ET.fromstring(result_elem.text)
        containers = didl_root.findall(".//{urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/}container")
        for c in containers:
            title_elem = c.find("{http://purl.org/dc/elements/1.1/}title")
            upnp_class_elem = c.find("{urn:schemas-upnp-org:metadata-1-0/upnp/}class")
            if title_elem is not None and upnp_class_elem is not None:
                if "object.container" in upnp_class_elem.text:
                    title_str = title_elem.text
                    folders.append(title_str)
                    if not quiet:
                        print(f"         -> Storage Folder: {title_str}")
    except ET.ParseError as e:
        if not quiet:
            print(f"         [!] XML parse error from Browse response: {e}")

    return folders


def wps_get_device_info(
    control_url: str,
    service_type: str,
    verbose: bool = False,
    quiet: bool = False
) -> List[Dict[str, str]]:
    parsed_info = []
    resp_xml = soap_call(control_url, service_type, "GetDeviceInfo", "", verbose=verbose, quiet=quiet)
    if not resp_xml:
        if not quiet:
            print("         [!] WPS GetDeviceInfo request failed.")
        return parsed_info

    match = re.search(r"<NewDeviceInfo>(.+)</NewDeviceInfo>", resp_xml, flags=re.IGNORECASE)
    if not match:
        if not quiet:
            print("         [!] Failed to locate <NewDeviceInfo> in the SOAP response.")
        return parsed_info

    encoded_info = match.group(1)
    try:
        info_data = base64.b64decode(encoded_info)
    except Exception as e:
        if not quiet:
            print(f"         [!] Base64 decode error: {e}")
        return parsed_info

    while info_data:
        if len(info_data) < 4:
            break
        try:
            tlv_type, tlv_length = struct.unpack("!HH", info_data[:4])
            raw_value = info_data[4 : 4 + tlv_length]
            info_data = info_data[4 + tlv_length:]

            if tlv_type == 0x1023:
                val = raw_value.decode(errors='ignore')
                if not quiet:
                    print(f"         -> Model Name: {val}")
                parsed_info.append({"type": "Model Name", "value": val})
            elif tlv_type == 0x1021:
                val = raw_value.decode(errors='ignore')
                if not quiet:
                    print(f"         -> Manufacturer: {val}")
                parsed_info.append({"type": "Manufacturer", "value": val})
            elif tlv_type == 0x1011:
                val = raw_value.decode(errors='ignore')
                if not quiet:
                    print(f"         -> Device Name: {val}")
                parsed_info.append({"type": "Device Name", "value": val})
            elif tlv_type == 0x1020:
                mac_str = ":".join(f"{b:02x}" for b in raw_value)
                if not quiet:
                    print(f"         -> MAC Address: {mac_str}")
                parsed_info.append({"type": "MAC Address", "value": mac_str})
            elif tlv_type == 0x1032:
                b64_pk = base64.b64encode(raw_value).decode()
                if not quiet:
                    print(f"         -> Public Key (base64): {b64_pk}")
                parsed_info.append({"type": "Public Key", "value": b64_pk})
            elif tlv_type == 0x101a:
                b64_nonce = base64.b64encode(raw_value).decode()
                if not quiet:
                    print(f"         -> Nonce (base64): {b64_nonce}")
                parsed_info.append({"type": "Nonce", "value": b64_nonce})
        except Exception:
            if not quiet:
                print("         [!] Failed to parse WPS M1 TLV data chunk.")
            break

    return parsed_info


###############################################################################
#                (8) MAIN ENUMERATION WORKFLOW FUNCTIONS                      #
###############################################################################

def handle_igd_action(
    svc: Dict[str, Union[str, list]],
    base_url: str,
    action: str,
    max_mappings: int,
    ext_port: int,
    int_port: int,
    int_client: str,
    protocol: str,
    description: str,
    lease: int,
    verbose: bool = False,
    quiet: bool = False
):
    st = svc["serviceType"]
    if not any(x in st for x in ("WANIPConnection", "WANPPPConnection")):
        return

    if action == "enum":
        get_external_ip(svc, base_url, verbose=verbose, quiet=quiet)
        found_mappings = enumerate_port_mappings(svc, base_url, max_mappings, verbose=verbose, quiet=quiet)
        svc["portMappings"].extend(found_mappings)
    elif action == "add":
        add_port_mapping(svc, base_url, ext_port, int_port, int_client,
                         protocol, description, lease, verbose=verbose, quiet=quiet)
    elif action == "remove":
        remove_port_mapping(svc, base_url, ext_port, protocol, verbose=verbose, quiet=quiet)


def maybe_handle_content_directory_or_wps(
    svc: Dict[str, Union[str, list]],
    base_url: str,
    verbose: bool = False,
    quiet: bool = False
) -> None:
    st = svc["serviceType"]
    control_url = svc["controlURL"]
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    if "ContentDirectory" in st:
        if not quiet:
            print("         [*] Attempting to Browse ContentDirectory (top-level).")
        folders = browse_content_directory(control_url, st, verbose=verbose, quiet=quiet)
        svc["contentDirectory"].extend(folders)

    if "WPS" in st:
        if not quiet:
            print("         [*] Attempting WPS GetDeviceInfo.")
        wps_data = wps_get_device_info(control_url, st, verbose=verbose, quiet=quiet)
        svc["wpsDeviceInfo"].extend(wps_data)


def enumerate_upnp_devices(
    target: Optional[str],
    timeout: float,
    st_list: List[str],
    mx: int,
    repeats: int,
    action: str,
    max_mappings: int,
    ext_port: int,
    int_port: int,
    int_client: str,
    protocol: str,
    description: str,
    lease: int,
    subscribe: bool,
    callback_url: str,
    subscribe_timeout: int,
    verbose: bool,
    quiet: bool
) -> List[Dict[str, Union[str, list]]]:
    combined_discovered = {}

    # 1) Cycle through ST values
    for st_value in st_list:
        if not quiet:
            print(f"\n[*] Sending M-SEARCH for ST={st_value}")
        resp_list = send_msearch(st_value, target=target, timeout=timeout, mx=mx,
                                 verbose=verbose, quiet=quiet)
        if not resp_list and not quiet:
            print(f"    [!] No responses for ST={st_value}")
            continue

        discovered_for_st = parse_ssdp_responses(resp_list, verbose=verbose, quiet=quiet)
        for loc, dev_info in discovered_for_st.items():
            if loc not in combined_discovered:
                combined_discovered[loc] = dev_info

    if not combined_discovered:
        if not quiet:
            print("\n[!] No UPnP devices discovered across all ST values.")
        return []

    if not quiet:
        print(f"\n[+] Total unique devices discovered: {len(combined_discovered)}")
    results = []

    # 2) Process each discovered device descriptor
    for location, ssdp_data in combined_discovered.items():
        ip, port = ssdp_data["addr"]
        if not quiet:
            print(f"\n[+] Device from {ip}:{port}")
            print(f"    LOCATION: {ssdp_data['LOCATION']}")
            if ssdp_data['SERVER']:
                print(f"    SERVER:   {ssdp_data['SERVER']}")
            if ssdp_data['ST']:
                print(f"    ST:       {ssdp_data['ST']}")
            if ssdp_data['USN']:
                print(f"    USN:      {ssdp_data['USN']}")

        location_record = {
            "location": location,
            "server": ssdp_data['SERVER'],
            "st": ssdp_data['ST'],
            "usn": ssdp_data['USN'],
            "ip": ip,
            "port": port,
            "devices": []
        }

        xml_data = fetch_device_description(location, verbose=verbose, quiet=quiet)
        if not xml_data:
            results.append(location_record)
            continue

        devices_info = parse_all_devices(xml_data, device_location=location,
                                         verbose=verbose, quiet=quiet)
        if not devices_info and not quiet:
            print("    [!] No valid <device> blocks found in descriptor.")
            results.append(location_record)
            continue

        for dev_idx, dev_info in enumerate(devices_info, start=1):
            if not quiet:
                print(f"\n    -- Device Block #{dev_idx} --")
                print(f"    Device Type:        {dev_info['deviceType']}")
                print(f"    Friendly Name:      {dev_info['friendlyName']}")
                print(f"    Manufacturer:       {dev_info['manufacturer']}")
                print(f"    ManufacturerURL:    {dev_info['manufacturerURL']}")
                print(f"    Model Description:  {dev_info['modelDescription']}")
                print(f"    Model Name:         {dev_info['modelName']}")
                print(f"    Model Number:       {dev_info['modelNumber']}")
                print(f"    Serial Number:      {dev_info['serialNumber']}")
                print(f"    UDN:                {dev_info['UDN']}")
                if dev_info["presentationURL"]:
                    print(f"    PresentationURL:    {dev_info['presentationURL']}")

                if dev_info["iconList"]:
                    print("    Icon(s):")
                    for icon in dev_info["iconList"]:
                        print(f"       - URL: {icon['url']} (type: {icon['mimetype']}"
                              f" {icon['width']}x{icon['height']} depth={icon['depth']})")

                if not dev_info["services"]:
                    print("    Services: None found.")
                else:
                    print("    Services:")

            for svc in dev_info["services"]:
                if not quiet:
                    print(f"       - Service Type: {svc['serviceType']}")
                    print(f"         Service ID:   {svc['serviceId']}")
                    print(f"         Control URL:  {svc['controlURL']}")
                    print(f"         EventSub URL: {svc['eventSubURL']}")
                    print(f"         SCPD URL:     {svc['SCPDURL']}")

                scpd_xml = fetch_scpd(svc["SCPDURL"], dev_info["resolvedBase"],
                                      verbose=verbose, quiet=quiet)
                actions = parse_scpd_actions(scpd_xml, verbose=verbose, quiet=quiet) if scpd_xml else []
                svc["actions"].extend(actions)

                if actions and not quiet:
                    print("         Actions:")
                    action_names = []
                    for act in actions:
                        print(f"           - {act['name']}")
                        action_names.append(act["name"])
                        if act["arguments"]:
                            for arg in act["arguments"]:
                                print(f"               * Arg: {arg['name']} ({arg['direction']}) "
                                      f"=> {arg['relatedStateVariable']}")
                        else:
                            print("               (No arguments)")

                    # If we see AddPortMapping => auto-enumerate port mappings
                    if "AddPortMapping" in action_names:
                        if not quiet:
                            print("\n         [auto] Found 'AddPortMapping' => enumerating port mappings (unlimited).")
                        found_maps = enumerate_port_mappings(svc, dev_info["resolvedBase"],
                                                             max_mappings=-1, verbose=verbose, quiet=quiet)
                        svc["portMappings"].extend(found_maps)
                        if not quiet:
                            print("")

                # IGD action
                handle_igd_action(
                    svc,
                    dev_info["resolvedBase"],
                    action,
                    max_mappings,
                    ext_port,
                    int_port,
                    int_client,
                    protocol,
                    description,
                    lease,
                    verbose=verbose,
                    quiet=quiet
                )

                # Subscription
                if subscribe and svc["eventSubURL"]:
                    if not quiet:
                        print("         Attempting SUBSCRIBE (CallStranger test)...")
                    subscribe_event(
                        svc["eventSubURL"],
                        dev_info["resolvedBase"],
                        callback_url,
                        subscribe_timeout,
                        verbose=verbose,
                        quiet=quiet
                    )

                # Additional enumerations
                maybe_handle_content_directory_or_wps(svc, dev_info["resolvedBase"],
                                                      verbose=verbose, quiet=quiet)

            location_record["devices"].append(dev_info)

        results.append(location_record)

    return results


###############################################################################
#                      (9) OUTPUT FORMATTING (JSON / XML)                     #
###############################################################################

def export_as_json(data: List[Dict[str, Union[str, list]]]) -> str:
    return json.dumps(data, indent=2)


def export_as_xml(data: List[Dict[str, Union[str, list]]]) -> str:
    root = ET.Element("UPnPDevices")
    for location in data:
        loc_elem = ET.SubElement(root, "DeviceLocation")
        loc_elem.set("location", location["location"])
        ET.SubElement(loc_elem, "IP").text = location["ip"]
        ET.SubElement(loc_elem, "Port").text = str(location["port"])
        ET.SubElement(loc_elem, "Server").text = location["server"]
        ET.SubElement(loc_elem, "ST").text = location["st"]
        ET.SubElement(loc_elem, "USN").text = location["usn"]

        devs_elem = ET.SubElement(loc_elem, "Devices")
        for dev_info in location["devices"]:
            dev_elem = ET.SubElement(devs_elem, "Device")
            for tag in [
                "deviceType", "friendlyName", "manufacturer", "manufacturerURL",
                "modelDescription", "modelName", "modelNumber", "serialNumber",
                "UDN", "presentationURL"
            ]:
                sub = ET.SubElement(dev_elem, tag)
                sub.text = dev_info[tag]

            icons_elem = ET.SubElement(dev_elem, "IconList")
            for icon in dev_info["iconList"]:
                icon_el = ET.SubElement(icons_elem, "Icon")
                for field in ["mimetype", "width", "height", "depth", "url"]:
                    subf = ET.SubElement(icon_el, field)
                    subf.text = icon[field]

            srvs_elem = ET.SubElement(dev_elem, "Services")
            for svc in dev_info["services"]:
                svc_el = ET.SubElement(srvs_elem, "Service")
                ET.SubElement(svc_el, "serviceType").text = svc["serviceType"]
                ET.SubElement(svc_el, "serviceId").text = svc["serviceId"]
                ET.SubElement(svc_el, "controlURL").text = svc["controlURL"]
                ET.SubElement(svc_el, "eventSubURL").text = svc["eventSubURL"]
                ET.SubElement(svc_el, "SCPDURL").text = svc["SCPDURL"]

                # actions
                acts_el = ET.SubElement(svc_el, "Actions")
                for act in svc["actions"]:
                    act_el = ET.SubElement(acts_el, "Action")
                    ET.SubElement(act_el, "name").text = act["name"]
                    args_el = ET.SubElement(act_el, "Arguments")
                    for argd in act["arguments"]:
                        arg_el = ET.SubElement(args_el, "Argument")
                        ET.SubElement(arg_el, "name").text = argd["name"]
                        ET.SubElement(arg_el, "direction").text = argd["direction"]
                        ET.SubElement(arg_el, "relatedStateVariable").text = argd["relatedStateVariable"]

                # port mappings
                pm_el = ET.SubElement(svc_el, "PortMappings")
                for pm in svc["portMappings"]:
                    pm_item = ET.SubElement(pm_el, "Mapping")
                    for key, val in pm.items():
                        subf = ET.SubElement(pm_item, key)
                        subf.text = val

                # contentDirectory
                cd_el = ET.SubElement(svc_el, "ContentDirectoryFolders")
                for ftitle in svc["contentDirectory"]:
                    fold = ET.SubElement(cd_el, "Folder")
                    fold.text = ftitle

                # wpsDeviceInfo
                wps_el = ET.SubElement(svc_el, "WPSDeviceInfo")
                for wps_item in svc["wpsDeviceInfo"]:
                    witem = ET.SubElement(wps_el, "InfoItem")
                    ET.SubElement(witem, "type").text = wps_item["type"]
                    ET.SubElement(witem, "value").text = wps_item["value"]

    return ET.tostring(root, encoding="unicode")


###############################################################################
#                   (10) COMMAND-LINE ENTRY POINT (main)                      #
###############################################################################

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Merged UPnP Enumeration & Management Tool "
                    "(Recursive + JSON/XML output + Quiet mode)."
    )
    parser.add_argument("-t", "--target",
                        help="Unicast target IP for UPnP scanning; omit for multicast.")
    parser.add_argument("--timeout", "-o", type=float, default=2.0,
                        help="SSDP response wait time (default=2.0).")
    parser.add_argument("--mx", type=int, default=2,
                        help="Value for the MX header in M-SEARCH (default=2).")
    parser.add_argument("--st-list", nargs="*", default=None,
                        help="List of ST (Search Target) values. Default set used if omitted.")
    parser.add_argument("--repeats", type=int, default=1,
                        help="[Compatibility] # of repeated M-SEARCH calls (unused).")

    # IGD actions
    parser.add_argument("--action", choices=["enum", "add", "remove"], default="enum",
                        help="IGD action to perform: (enum/add/remove). Default=enum.")
    parser.add_argument("--max-mappings", type=int, default=1,
                        help="Enumerate up to N port mappings (default=1). Use -1 for indefinite.")
    parser.add_argument("--ext-port", type=int, default=0,
                        help="External port for add/remove (default=0).")
    parser.add_argument("--int-port", type=int, default=0,
                        help="Internal port for add (default=0).")
    parser.add_argument("--int-client", default="",
                        help="Internal client IP for add (default='').")
    parser.add_argument("--protocol", choices=["TCP", "UDP"], default="TCP",
                        help="Protocol for port mapping (default=TCP).")
    parser.add_argument("--description", default="PortMapping",
                        help="Port mapping description (default='PortMapping').")
    parser.add_argument("--lease", type=int, default=0,
                        help="Lease duration in seconds (0=indefinite).")

    # Subscription (CallStranger)
    parser.add_argument("--subscribe", action="store_true",
                        help="Attempt SUBSCRIBE on each service's eventSubURL.")
    parser.add_argument("--callback", default="http://127.0.0.1:9999/",
                        help="Callback URL for SUBSCRIBE. Default=http://127.0.0.1:9999/")
    parser.add_argument("--subscribe-timeout", type=int, default=1800,
                        help="SUBSCRIBE duration in seconds (default=1800).")

    # Verbose & Output
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Enable verbose debugging output.")
    parser.add_argument("--output-format", choices=["none", "json", "xml"], default="none",
                        help="Output discovered data to a file in JSON or XML format. Default=none.")

    # New: Quiet mode
    parser.add_argument("--quiet", action="store_true",
                        help="Suppress all console output (including errors).")

    args = parser.parse_args()

    # If user didn't provide ST list, use defaults
    if not args.st_list:
        args.st_list = ST_LIST.copy()

    # Minimal or no console output if quiet
    if not args.quiet:
        if args.target:
            print(f"[*] Unicast scanning {args.target} for UPnP devices.")
        else:
            print("[*] Multicast scanning for UPnP devices on the local network.")
        if args.verbose:
            print("[VERBOSE] Using the following ST list:")
            for stv in args.st_list:
                print(f"          - {stv}")

    try:
        all_results = enumerate_upnp_devices(
            target=args.target,
            timeout=args.timeout,
            st_list=args.st_list,
            mx=args.mx,
            repeats=args.repeats,
            action=args.action,
            max_mappings=args.max_mappings,
            ext_port=args.ext_port,
            int_port=args.int_port,
            int_client=args.int_client,
            protocol=args.protocol,
            description=args.description,
            lease=args.lease,
            subscribe=args.subscribe,
            callback_url=args.callback,
            subscribe_timeout=args.subscribe_timeout,
            verbose=args.verbose,
            quiet=args.quiet
        )
    except KeyboardInterrupt:
        if not args.quiet:
            print("\n[!] Interrupted by user.")
        sys.exit(1)
    except Exception as ex:
        if not args.quiet:
            print(f"\n[ERROR] Unexpected exception: {ex}")
        sys.exit(1)

    # If user wants JSON/XML output, write to timestamped file
    if args.output_format in ("json", "xml"):
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        outfile = f"{timestamp}.{args.output_format}"

        if args.output_format == "json":
            data_str = export_as_json(all_results)
        else:  # args.output_format == "xml"
            data_str = export_as_xml(all_results)

        with open(outfile, "w", encoding="utf-8") as f:
            f.write(data_str)

        if not args.quiet:
            print(f"\n[INFO] Wrote {args.output_format.upper()} output to {outfile}")


if __name__ == "__main__":
    main()
