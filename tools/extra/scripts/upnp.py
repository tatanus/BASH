#!/usr/bin/env python3
"""
Combined UPnP Tool (Updated with SCRIPT2 Enhancements)
------------------------------------------------------
This script merges functionality from multiple UPnP scripts and now
includes improvements inspired by SCRIPT2:

1) SSDP-based scanning (unicast/multicast)
2) Support for scanning multiple 'ST' (Search Target) values automatically
3) Fetching and parsing device descriptors (including manufacturerURL and modelDescription)
4) Enumerating services and their SCPD actions
5) Optional SOAP actions (WANIPConnection/WANPPPConnection: GetExternalIPAddress, AddPortMapping, etc.)
6) Optional SUBSCRIBE-based eventing test (CallStranger-like)
7) ContentDirectory "Browse" support if service type matches "urn:schemas-upnp-org:service:ContentDirectory"
8) WPS "GetDeviceInfo" (M1) support if service type matches "urn:schemas-upnp-org:service:WPS"
9) Robust error handling, logging, and ability to store malformed XML

Usage Examples:
    # Default "enum" action (cycles through typical ST values by default).
    python combined_upnp_tool.py --max-mappings 5

    # Unicast scan a specific host, do subscription testing
    python combined_upnp_tool.py -t 192.168.1.1 --subscribe --callback http://10.0.0.5:9999/test

    # Add a TCP port mapping
    python combined_upnp_tool.py -t 192.168.1.1 --action add --ext-port 8080 --int-port 80 \
        --int-client 192.168.1.100 --description "MyHTTP" --protocol TCP --lease 3600

    # Remove a port mapping
    python combined_upnp_tool.py -t 192.168.1.1 --action remove --ext-port 8080 --protocol TCP

    # Verbose Mode
    python combined_upnp_tool.py --verbose
"""

import argparse
import datetime
import os
import socket
import sys
import time
import urllib.parse
import xml.etree.ElementTree as ET
from typing import List, Tuple, Dict, Optional, Union

import requests
import base64
import struct

# Default SSDP Multicast constants
SSDP_MCAST_ADDR = "239.255.255.250"
SSDP_PORT = 1900
ST_LIST = [
    # General / Catch-all
    "ssdp:all",
    "upnp:rootdevice",

    # Generic device search by UUID: (example format, replace <UUID> with actual)
    # "uuid:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",

    # Standard UPnP device types
    "urn:schemas-upnp-org:device:Basic:1",
    "urn:schemas-upnp-org:device:InternetGatewayDevice:1",
    "urn:schemas-upnp-org:device:MediaServer:1",
    "urn:schemas-upnp-org:device:MediaRenderer:1",
    # There are many more specialized device types (Printer:1, Scanner:1, etc.)

    # IGD Services
    "urn:schemas-upnp-org:service:WANIPConnection:1",
    "urn:schemas-upnp-org:service:WANIPConnection:2",
    "urn:schemas-upnp-org:service:WANPPPConnection:1",
    "urn:schemas-upnp-org:service:WANPPPConnection:2",
    "urn:schemas-upnp-org:service:WANCommonInterfaceConfig:1",
    "urn:schemas-upnp-org:service:Layer3Forwarding:1",

    # Multimedia / Streaming
    "urn:schemas-upnp-org:service:ContentDirectory:1",
    "urn:schemas-upnp-org:service:ConnectionManager:1",
    "roku:ecp",  # Roku ECP
    "urn:dial-multiscreen-org:service:dial:1",  # DIAL protocol (Chromecast, Smart TVs)

    # IoT / Home Automation
    "urn:schemas-upnp-org:device:BinaryLight:1",
    "urn:schemas-upnp-org:device:DimmableLight:1",
    "urn:schemas-upnp-org:device:DigitalSecurityCamera:1",
    "urn:schemas-upnp-org:device:HVAC_ZoneThermostat:1",
    # Potential others like SecurityAlarm:1, GarageDoor:1, etc.

    # Vendor-specific
    "urn:Belkin:device:controllee:1",     # Belkin WeMo Switch
    "urn:Belkin:device:lightswitch:1",    # Belkin WeMo Light Switch
    "urn:Belkin:device:insight:1",        # WeMo Insight Switch
    "urn:Belkin:device:sensor:1",         # WeMo Motion sensor
    "urn:schemas-upnp-org:device:ZonePlayer:1",  # Sonos

    # Additional known search targets
    "urn:schemas-upnp-org:device:Printer:1",
    "urn:schemas-upnp-org:device:WPS:1",  # Some WPS devices
]


###############################################################################
#                         SSDP / M-SEARCH Routines                            #
###############################################################################

def build_msearch_request(st: str = "ssdp:all", mx: int = 2, verbose: bool = False) -> str:
    """
    Build a single SSDP M-SEARCH request for a given ST value.
    """
    if verbose:
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
    target: Optional[str] = None,
    timeout: float = 2.0,
    mx: int = 2,
    verbose: bool = False
) -> List[Tuple[str, Tuple[str, int]]]:
    """
    Send an SSDP M-SEARCH for a single ST, either unicast or multicast.
    Returns a list of (raw_response, (ip,port)) from responders.
    """
    responses = []
    msearch_data = build_msearch_request(st, mx, verbose).encode("utf-8")

    if verbose and target:
        print(f"[VERBOSE] Sending unicast M-SEARCH (ST={st}) to {target}:{SSDP_PORT}")
    elif verbose:
        print(f"[VERBOSE] Sending multicast M-SEARCH (ST={st}) to {SSDP_MCAST_ADDR}:{SSDP_PORT}")

    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.settimeout(timeout)

        # Destination depends on unicast vs. multicast
        destination = (target or SSDP_MCAST_ADDR, SSDP_PORT)

        # Send once for each ST we want
        try:
            sock.sendto(msearch_data, destination)
        except socket.error as e:
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
                print(f"[ERROR] Exception receiving SSDP response: {e}")
                break

    if verbose:
        print(f"[VERBOSE] Received {len(responses)} responses for ST={st}")
    return responses


def parse_ssdp_responses(
    responses: List[Tuple[str, Tuple[str, int]]],
    verbose: bool = False
) -> Dict[str, Dict[str, Union[str, Tuple[str, int]]]]:
    """
    From raw SSDP responses, parse relevant headers and store them keyed by LOCATION.
    e.g. discovered[location_url] = { LOCATION, SERVER, ST, USN, addr=(ip,port) }
    """
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

    if verbose and discovered:
        print(f"[VERBOSE] parse_ssdp_responses discovered {len(discovered)} unique LOCATION entries.")
    return discovered


###############################################################################
#                         Device Description Routines                         #
###############################################################################

def store_malformed_xml(raw_data: str, location: str, verbose: bool = False) -> str:
    """
    Store raw malformed XML to a local file for debugging.
    """
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_loc = location.replace(":", "_").replace("/", "_").replace("\\", "_")
    filename = f"malformed_{safe_loc}_{timestamp}.xml"

    with open(filename, "w", encoding="utf-8") as f:
        f.write(raw_data)

    if verbose:
        print(f"[VERBOSE] Malformed XML stored at {os.path.abspath(filename)}")

    return os.path.abspath(filename)


def fetch_device_description(url: str, verbose: bool = False) -> Optional[str]:
    """
    Fetch the root device descriptor from a given LOCATION URL.
    """
    try:
        if verbose:
            print(f"[VERBOSE] Fetching device description from {url}")
        resp = requests.get(url, timeout=5)
        resp.raise_for_status()
        ctype = resp.headers.get("Content-Type", "").lower()
        if "xml" not in ctype and verbose:
            print(f"[WARNING] Content-Type '{ctype}' from {url} might not be valid XML.")
        return resp.text
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Could not fetch device description from {url}: {e}")
        return None


def derive_base_url(location: str, url_base: str) -> str:
    """
    If <URLBase> is present/absolute, use it. Otherwise parse from the LOCATION header.
    """
    url_base = url_base.strip()
    if url_base.lower().startswith("http"):
        return url_base
    if url_base:
        # might be relative
        return urllib.parse.urljoin(location, url_base)
    # fallback to scheme://host
    parsed = urllib.parse.urlparse(location)
    return f"{parsed.scheme}://{parsed.netloc}"


def parse_device_description(xml_data: str, device_location: str, verbose: bool = False) -> Optional[Dict[str, Union[str, List, Dict]]]:
    """
    Parse a device descriptor, returning device metadata, services, iconList, etc.
    """
    info = {
        "deviceType": "",
        "friendlyName": "",
        "manufacturer": "",
        "manufacturerURL": "",
        "modelDescription": "",
        "modelName": "",
        "UDN": "",
        "presentationURL": "",
        "iconList": [],
        "modelNumber": "",
        "serialNumber": "",
        "services": [],
        "resolvedBase": "",
    }

    try:
        root = ET.fromstring(xml_data)
    except ET.ParseError as e:
        print(f"[WARNING] Malformed device descriptor at {device_location}: {e}")
        path = store_malformed_xml(xml_data, device_location, verbose)
        print(f"    [!] Stored invalid XML at {path}")
        return None

    # <URLBase>
    url_base_elem = root.find("{*}URLBase")
    url_base = url_base_elem.text if (url_base_elem is not None and url_base_elem.text) else ""
    info["resolvedBase"] = derive_base_url(device_location, url_base)

    device_elem = root.find(".//{*}device")
    if not device_elem:
        return info

    # We'll parse a few more fields than originally (manufacturerURL, modelDescription).
    for tag in [
        "deviceType", "friendlyName", "manufacturer", "manufacturerURL",
        "modelDescription", "modelName", "UDN", "modelNumber",
        "serialNumber", "presentationURL"
    ]:
        elem = device_elem.find(f".//{{*}}{tag}")
        if elem is not None and elem.text:
            info[tag] = elem.text.strip()

    # Icons
    icon_list = device_elem.find(".//{*}iconList")
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

    # Services
    service_list = device_elem.find(".//{*}serviceList")
    if service_list is not None:
        for svc in service_list.findall("{*}service"):
            svc_data = {
                "serviceType": svc.findtext("{*}serviceType", default="").strip(),
                "serviceId": svc.findtext("{*}serviceId", default="").strip(),
                "controlURL": svc.findtext("{*}controlURL", default="").strip(),
                "eventSubURL": svc.findtext("{*}eventSubURL", default="").strip(),
                "SCPDURL": svc.findtext("{*}SCPDURL", default="").strip(),
            }
            info["services"].append(svc_data)

    if verbose:
        print(f"[VERBOSE] parse_device_description found {len(info['services'])} service(s) for {device_location}")
    return info


###############################################################################
#                           SCPD & SOAP Routines                              #
###############################################################################

def fetch_scpd(scpd_url: str, base_url: str, verbose: bool = False) -> Optional[str]:
    """
    Fetch the SCPD XML from a relative or absolute URL.
    """
    if not scpd_url:
        return None

    if not scpd_url.lower().startswith("http"):
        if base_url:
            scpd_url = urllib.parse.urljoin(base_url + "/", scpd_url)
        else:
            print(f"[WARNING] Unable to resolve relative SCPD URL: {scpd_url}")
            return None

    if verbose:
        print(f"[VERBOSE] Fetching SCPD from {scpd_url}")
    try:
        resp = requests.get(scpd_url, timeout=5)
        resp.raise_for_status()
        ctype = resp.headers.get("Content-Type", "").lower()
        if "xml" not in ctype and verbose:
            print(f"[WARNING] SCPD at {scpd_url} might not be valid XML.")
        return resp.text
    except requests.exceptions.RequestException as e:
        print(f"[WARNING] Failed to fetch SCPD from {scpd_url}: {e}")
        return None


def parse_scpd_actions(scpd_xml: str, verbose: bool = False) -> List[Dict[str, Union[str, List]]]:
    """
    Extract actions & arguments from an SCPD.
    """
    actions = []
    if not scpd_xml:
        return actions

    try:
        root = ET.fromstring(scpd_xml)
    except ET.ParseError as e:
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

    if verbose:
        print(f"[VERBOSE] Found {len(actions)} actions in SCPD.")
    return actions


def soap_call(control_url: str, service_type: str, action_name: str, body_xml: str, verbose: bool = False) -> Optional[str]:
    """
    Perform a SOAP call to a service's control URL with a given action name and body.
    """
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

    if verbose:
        print(f"[VERBOSE] SOAP POST to {control_url}, Action={soap_action}")
    try:
        resp = requests.post(control_url, data=envelope, headers=headers, timeout=5)
        if resp.status_code == 200:
            return resp.text
        else:
            print(f"      [!] SOAP action '{action_name}' returned status {resp.status_code}")
            return None
    except requests.exceptions.RequestException as e:
        print(f"      [!] SOAP action '{action_name}' failed: {e}")
        return None


###############################################################################
#                           Additional Features (SCRIPT2)                     #
###############################################################################

def browse_content_directory(control_url: str, service_type: str, verbose: bool = False):
    """
    Similar to SCRIPT2's find_directories():
    Send a 'Browse' request for the top-level directory and print out
    the top-level containers/folders (limited to first 10).
    """
    body = """<ObjectID>0</ObjectID>
<BrowseFlag>BrowseDirectChildren</BrowseFlag>
<Filter>*</Filter>
<StartingIndex>0</StartingIndex>
<RequestedCount>10</RequestedCount>
<SortCriteria></SortCriteria>"""

    resp_xml = soap_call(control_url, service_type, "Browse", body, verbose=verbose)
    if not resp_xml:
        print("         [!] ContentDirectory Browse request failed or returned no data.")
        return

    try:
        root = ET.fromstring(resp_xml)
        # The actual container XML is inside <Result>...</Result>
        result_elem = root.find(".//{*}Result")
        if result_elem is None or not result_elem.text:
            print("         [!] No <Result> found in response.")
            return
        # Now parse the DIDL-Lite response
        didl_root = ET.fromstring(result_elem.text)
        containers = didl_root.findall(".//{urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/}container")
        for c in containers:
            title_elem = c.find("{http://purl.org/dc/elements/1.1/}title")
            upnp_class_elem = c.find("{urn:schemas-upnp-org:metadata-1-0/upnp/}class")
            if title_elem is not None and upnp_class_elem is not None:
                if "object.container" in upnp_class_elem.text:
                    print(f"         -> Storage Folder: {title_elem.text}")
    except ET.ParseError as e:
        print(f"         [!] XML parse error from Browse response: {e}")


def wps_get_device_info(control_url: str, service_type: str, verbose: bool = False):
    """
    Similar to SCRIPT2's find_device_info():
    Send a 'GetDeviceInfo' request to WPS services and parse the base64-encoded M1.
    """
    resp_xml = soap_call(control_url, service_type, "GetDeviceInfo", "", verbose=verbose)
    if not resp_xml:
        print("         [!] WPS GetDeviceInfo request failed.")
        return

    # Extract the base64 data from <NewDeviceInfo>...</NewDeviceInfo>
    import re
    match = re.search(r"<NewDeviceInfo>(.+)</NewDeviceInfo>", resp_xml, flags=re.IGNORECASE)
    if not match:
        print("         [!] Failed to locate <NewDeviceInfo> in the SOAP response.")
        return

    encoded_info = match.group(1)
    try:
        info_data = base64.b64decode(encoded_info)
    except Exception as e:
        print(f"         [!] Base64 decode error: {e}")
        return

    # Attempt to parse the WPS M1 TLV structure
    # Each chunk is 2-byte type, 2-byte length, followed by 'length' bytes of value
    while info_data:
        if len(info_data) < 4:
            break
        try:
            tlv_type, tlv_length = struct.unpack("!HH", info_data[:4])
            raw_value = info_data[4:4+tlv_length]
            info_data = info_data[4+tlv_length:]

            # Basic examples from SCRIPT2
            if tlv_type == 0x1023:
                print(f"         -> Model Name: {raw_value.decode(errors='ignore')}")
            elif tlv_type == 0x1021:
                print(f"         -> Manufacturer: {raw_value.decode(errors='ignore')}")
            elif tlv_type == 0x1011:
                print(f"         -> Device Name: {raw_value.decode(errors='ignore')}")
            elif tlv_type == 0x1020:
                # This should be the MAC address in raw bytes
                # In Python 3, we can do: 
                mac_str = ":".join(f"{b:02x}" for b in raw_value)
                print(f"         -> MAC Address: {mac_str}")
            elif tlv_type == 0x1032:
                print(f"         -> Public Key (base64): {base64.b64encode(raw_value).decode()}")
            elif tlv_type == 0x101a:
                print(f"         -> Nonce (base64): {base64.b64encode(raw_value).decode()}")
        except Exception:
            print("         [!] Failed to parse WPS M1 TLV data chunk.")
            break


###############################################################################
#                           Port Mapping Routines                             #
###############################################################################

def get_external_ip(service_info: Dict[str, str], base_url: str, verbose: bool = False) -> None:
    """
    SOAP call: GetExternalIPAddress (if it's a WANIPConnection or WANPPPConnection).
    """
    st = service_info["serviceType"]
    if not any(x in st for x in ("WANIPConnection", "WANPPPConnection")):
        return

    control_url = service_info["controlURL"]
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    print(f"      [*] Trying GetExternalIPAddress on {control_url}")
    resp = soap_call(control_url, st, "GetExternalIPAddress", "", verbose=verbose)
    if resp:
        try:
            root = ET.fromstring(resp)
            ip_elem = root.find(".//{*}NewExternalIPAddress")
            if ip_elem is not None and ip_elem.text:
                print(f"      [+] External IP: {ip_elem.text}")
            else:
                print("      [!] No IP found in SOAP response.")
        except ET.ParseError as e:
            print(f"      [!] SOAP parse error: {e}")


def enumerate_port_mappings(service_info: Dict[str, str], base_url: str,
                            max_mappings: int = 1, verbose: bool = False) -> None:
    """
    SOAP call: GetGenericPortMappingEntry from index=0..(max_mappings-1).
    If max_mappings == -1, continue until a non-200 response or parse failure (SCRIPT2 style).
    """
    st = service_info["serviceType"]
    if not any(x in st for x in ("WANIPConnection", "WANPPPConnection")):
        return

    control_url = service_info["controlURL"]
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    index = 0
    while True:
        if max_mappings != -1 and index >= max_mappings:
            break

        body_xml = f"<NewPortMappingIndex>{index}</NewPortMappingIndex>"
        print(f"      [*] GetGenericPortMappingEntry(index={index}) -> {control_url}")
        resp = soap_call(control_url, st, "GetGenericPortMappingEntry", body_xml, verbose=verbose)
        if not resp:
            # Typically means no entry or an error
            break

        try:
            root = ET.fromstring(resp)
            new_ext_port = root.find(".//{*}NewExternalPort")
            new_int_port = root.find(".//{*}NewInternalPort")
            new_int_client = root.find(".//{*}NewInternalClient")
            new_proto = root.find(".//{*}NewProtocol")
            new_desc = root.find(".//{*}NewPortMappingDescription")

            # If these fields are missing, no further entries
            if not new_ext_port and not new_int_client:
                print("      [!] No port mapping found at this index.")
                break

            print(f"      [+] Port Mapping #{index}:")
            if new_ext_port is not None:
                print(f"          External Port: {new_ext_port.text}")
            if new_int_port is not None:
                print(f"          Internal Port: {new_int_port.text}")
            if new_int_client is not None:
                print(f"          Internal Host: {new_int_client.text}")
            if new_proto is not None:
                print(f"          Protocol:      {new_proto.text}")
            if new_desc is not None:
                print(f"          Description:   {new_desc.text}")
        except ET.ParseError as e:
            print(f"      [!] SOAP parse error: {e}")
            break

        index += 1


def add_port_mapping(
    service_info: Dict[str, str],
    base_url: str,
    ext_port: int,
    int_port: int,
    int_client: str,
    protocol: str,
    description: str,
    lease: int,
    verbose: bool = False
) -> None:
    """
    SOAP call: AddPortMapping
    """
    st = service_info["serviceType"]
    if not any(x in st for x in ("WANIPConnection", "WANPPPConnection")):
        return

    control_url = service_info["controlURL"]
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    body = f"""
<NewRemoteHost></NewRemoteHost>
<NewExternalPort>{ext_port}</NewExternalPort>
<NewProtocol>{protocol}</NewProtocol>
<NewInternalPort>{int_port}</NewInternalPort>
<NewInternalClient>{int_client}</NewInternalClient>
<NewEnabled>1</NewEnabled>
<NewPortMappingDescription>{description}</NewPortMappingDescription>
<NewLeaseDuration>{lease}</NewLeaseDuration>
""".strip()

    print(f"      [*] Attempting AddPortMapping on {control_url}")
    resp = soap_call(control_url, st, "AddPortMapping", body, verbose=verbose)
    if resp:
        print("      [+] Port mapping added successfully.")
    else:
        print("      [!] Failed to add port mapping.")


def remove_port_mapping(
    service_info: Dict[str, str],
    base_url: str,
    ext_port: int,
    protocol: str,
    verbose: bool = False
) -> None:
    """
    SOAP call: DeletePortMapping
    """
    st = service_info["serviceType"]
    if not any(x in st for x in ("WANIPConnection", "WANPPPConnection")):
        return

    control_url = service_info["controlURL"]
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    body = f"""
<NewRemoteHost></NewRemoteHost>
<NewExternalPort>{ext_port}</NewExternalPort>
<NewProtocol>{protocol}</NewProtocol>
""".strip()

    print(f"      [*] Attempting DeletePortMapping on {control_url}")
    resp = soap_call(control_url, st, "DeletePortMapping", body, verbose=verbose)
    if resp:
        print("      [+] Port mapping removed successfully.")
    else:
        print("      [!] Failed to remove port mapping.")


###############################################################################
#                         Event Subscription (CallStranger)                   #
###############################################################################

def subscribe_event(
    event_sub_url: str,
    base_url: str,
    callback_url: str,
    subscribe_timeout: int = 1800,
    verbose: bool = False
) -> None:
    """
    Perform a SUBSCRIBE request on the given eventSubURL, simulating
    a CallStranger-like SSRF check.
    """
    if not event_sub_url:
        return

    if not event_sub_url.lower().startswith("http"):
        # possibly relative
        event_sub_url = urllib.parse.urljoin(base_url + "/", event_sub_url)

    headers = {
        "CALLBACK": f"<{callback_url}>",
        "NT": "upnp:event",
        "TIMEOUT": f"Second-{subscribe_timeout}",
    }

    if verbose:
        print(f"[VERBOSE] Sending SUBSCRIBE to {event_sub_url} with callback={callback_url}")
    try:
        resp = requests.request("SUBSCRIBE", event_sub_url, headers=headers, timeout=5)
        if 200 <= resp.status_code < 300:
            sid = resp.headers.get("SID", "")
            print(f"         [+] SUBSCRIBE success! SID={sid} (status {resp.status_code})")
        else:
            print(f"         [!] SUBSCRIBE returned {resp.status_code} {resp.reason}")
    except requests.exceptions.RequestException as e:
        print(f"         [!] SUBSCRIBE failed: {e}")


###############################################################################
#                    Core Workflow: "enumerate_upnp_devices"                  #
###############################################################################

def handle_igd_action(
    svc: Dict[str, str],
    base_url: str,
    action: str,
    max_mappings: int,
    ext_port: int,
    int_port: int,
    int_client: str,
    protocol: str,
    description: str,
    lease: int,
    verbose: bool = False
) -> None:
    """
    Decide whether to get external IP, enumerate port mappings, add or remove a mapping, etc.
    Based on the user-chosen 'action'.
    """
    if action == "enum":
        get_external_ip(svc, base_url, verbose=verbose)
        enumerate_port_mappings(svc, base_url, max_mappings, verbose=verbose)
    elif action == "add":
        add_port_mapping(svc, base_url, ext_port, int_port, int_client, protocol, description, lease, verbose=verbose)
    elif action == "remove":
        remove_port_mapping(svc, base_url, ext_port, protocol, verbose=verbose)


def maybe_handle_content_directory_or_wps(svc: Dict[str, str], base_url: str, verbose: bool = False) -> None:
    """
    If the service type indicates a ContentDirectory or WPS,
    call the specialized routines from SCRIPT2.
    """
    st = svc["serviceType"]

    control_url = svc["controlURL"]
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    if "ContentDirectory" in st:
        print("         [*] Attempting to Browse ContentDirectory (top-level).")
        browse_content_directory(control_url, st, verbose=verbose)

    if "WPS" in st:
        print("         [*] Attempting WPS GetDeviceInfo.")
        wps_get_device_info(control_url, st, verbose=verbose)


def enumerate_upnp_devices(
    target: Optional[str],
    timeout: float,
    st_list: List[str],
    mx: int,
    repeats: int,
    # IGD port mapping arguments
    action: str,
    max_mappings: int,
    ext_port: int,
    int_port: int,
    int_client: str,
    protocol: str,
    description: str,
    lease: int,
    # Subscription
    subscribe: bool,
    callback_url: str,
    subscribe_timeout: int,
    # Verbose
    verbose: bool
):
    """
    Main scanning & enumeration workflow.
    1) For each ST in st_list, do an M-SEARCH (unicast or multicast).
    2) Parse SSDP responses, fetch & parse device descriptors, gather services, etc.
    3) If IGD, run the chosen port mapping action (enum/add/remove).
    4) Optionally attempt SUBSCRIBE on each service’s eventSubURL for SSRF testing.
    5) If a ContentDirectory service is found, attempt a "Browse" call (SCRIPT2).
    6) If a WPS service is found, attempt a "GetDeviceInfo" call (SCRIPT2).
    """
    combined_discovered = {}

    # 1) Cycle through ST values
    for st_value in st_list:
        print(f"\n[*] Sending M-SEARCH for ST={st_value}")
        resp_list = send_msearch(st_value, target=target, timeout=timeout, mx=mx, verbose=verbose)
        if not resp_list:
            print(f"    [!] No responses for ST={st_value}")
            continue

        # parse & merge discovered
        discovered_for_st = parse_ssdp_responses(resp_list, verbose=verbose)
        for loc, dev_info in discovered_for_st.items():
            # If the same location shows up for multiple ST, we'll keep the earliest
            if loc not in combined_discovered:
                combined_discovered[loc] = dev_info

    if not combined_discovered:
        print("\n[!] No UPnP devices discovered across all ST values.")
        return

    print(f"\n[+] Total unique devices discovered: {len(combined_discovered)}")

    # 2) Process each discovered device descriptor
    for location, ssdp_data in combined_discovered.items():
        ip, port = ssdp_data["addr"]
        print(f"\n[+] Device from {ip}:{port}")
        print(f"    LOCATION: {ssdp_data['LOCATION']}")
        if ssdp_data['SERVER']:
            print(f"    SERVER:   {ssdp_data['SERVER']}")
        if ssdp_data['ST']:
            print(f"    ST:       {ssdp_data['ST']}")
        if ssdp_data['USN']:
            print(f"    USN:      {ssdp_data['USN']}")

        # fetch descriptor
        xml_data = fetch_device_description(location, verbose=verbose)
        if not xml_data:
            continue

        dev_info = parse_device_description(xml_data, device_location=location, verbose=verbose)
        if not dev_info:
            print("    [!] Device descriptor invalid/malformed.")
            continue

        # show device summary
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

        # icons
        if dev_info["iconList"]:
            print("    Icon(s):")
            for icon in dev_info["iconList"]:
                print(f"       - URL: {icon['url']} "
                      f"(type: {icon['mimetype']} {icon['width']}x{icon['height']} depth={icon['depth']})")

        # services
        if not dev_info["services"]:
            print("    Services: None found")
            continue

        print("    Services:")
        for svc in dev_info["services"]:
            print(f"       - Service Type: {svc['serviceType']}")
            print(f"         Service ID:   {svc['serviceId']}")
            print(f"         Control URL:  {svc['controlURL']}")
            print(f"         EventSub URL: {svc['eventSubURL']}")
            print(f"         SCPD URL:     {svc['SCPDURL']}")

            # 3) If user wants to see actions, fetch & parse SCPD
            scpd_xml = fetch_scpd(svc["SCPDURL"], dev_info["resolvedBase"], verbose=verbose)
            actions = parse_scpd_actions(scpd_xml, verbose=verbose) if scpd_xml else []
            if actions:
                print("         Actions:")
                for act in actions:
                    print(f"           - {act['name']}")
                    if act["arguments"]:
                        for arg in act["arguments"]:
                            print(f"               * Arg: {arg['name']} ({arg['direction']}) "
                                  f"=> {arg['relatedStateVariable']}")
                    else:
                        print("               (No arguments)")

            # (a) If it's an IGD-like service, handle user-chosen port mapping
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
                verbose=verbose
            )

            # (b) If subscription test is enabled
            if subscribe and svc["eventSubURL"]:
                print("         Attempting SUBSCRIBE (CallStranger test)...")
                subscribe_event(
                    svc["eventSubURL"],
                    dev_info["resolvedBase"],
                    callback_url,
                    subscribe_timeout,
                    verbose=verbose
                )

            # (c) Check if it's ContentDirectory or WPS, do extra enumeration
            maybe_handle_content_directory_or_wps(svc, dev_info["resolvedBase"], verbose=verbose)


###############################################################################
#                                   MAIN                                      #
###############################################################################

def main() -> None:
    parser = argparse.ArgumentParser(
        description="All-in-One UPnP Scanner & Manager (updated with SCRIPT2-like features)."
    )
    parser.add_argument("-t", "--target",
                        help="Unicast target IP for UPnP scanning; otherwise do multicast on the local net.")
    parser.add_argument("--timeout", "-o", type=float, default=2.0,
                        help="SSDP response wait time in seconds (default=2.0)")
    parser.add_argument("--mx", type=int, default=2,
                        help="Value for the MX header (default=2).")

    # ST cycling
    parser.add_argument("--st-list", nargs="*", default=None,
                        help="List of ST (Search Target) values to cycle through. "
                             "If not provided, uses a typical default list.")

    parser.add_argument("--repeats", type=int, default=1,
                        help="[Deprecated Option if needed] Not actively used here. "
                             "We send one request per ST by default. (Default=1)")

    # IGD actions
    parser.add_argument("--action", choices=["enum", "add", "remove"], default="enum",
                        help="Action to perform on WANIP/WANPPP (default=enum).")
    parser.add_argument("--max-mappings", type=int, default=1,
                        help="Enumerate up to N port mapping entries (default=1). "
                             "Use -1 to try enumerating until failure (SCRIPT2 style).")
    parser.add_argument("--ext-port", type=int, default=0,
                        help="External port for add/remove (default=0).")
    parser.add_argument("--int-port", type=int, default=0,
                        help="Internal port for add (default=0).")
    parser.add_argument("--int-client", default="",
                        help="Internal host IP for add (default='').")
    parser.add_argument("--protocol", choices=["TCP", "UDP"], default="TCP",
                        help="Protocol for port mapping (default=TCP).")
    parser.add_argument("--description", default="PortMapping",
                        help="Description for port mapping (default='PortMapping').")
    parser.add_argument("--lease", type=int, default=0,
                        help="Lease duration (seconds) for add (default=0=indefinite).")

    # Subscription
    parser.add_argument("--subscribe", action="store_true",
                        help="Attempt SUBSCRIBE on each service's eventSubURL (CallStranger test).")
    parser.add_argument("--callback", default="http://127.0.0.1:9999/",
                        help="Callback URL used in SUBSCRIBE requests (default=http://127.0.0.1:9999/).")
    parser.add_argument("--subscribe-timeout", type=int, default=1800,
                        help="Requested SUBSCRIBE duration in seconds (default=1800).")

    # Verbose logging
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="Enable verbose debugging and logging output.")

    args = parser.parse_args()

    # Provide a "typical ST list" if none given
    if not args.st_list:
        args.st_list = ST_LIST.copy()

    if args.target:
        print(f"[*] Unicast scanning {args.target} for UPnP devices.")
    else:
        print("[*] Multicast scanning for UPnP devices on the local network.")

    if args.verbose:
        print("[VERBOSE] Starting enumerate_upnp_devices with the following ST list:")
        for stv in args.st_list:
            print(f"          - {stv}")

    enumerate_upnp_devices(
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
        verbose=args.verbose
    )


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[!] Interrupted by user.")
        sys.exit(1)
    except Exception as ex:
        print(f"\n[ERROR] Unexpected: {ex}")
        sys.exit(1)

