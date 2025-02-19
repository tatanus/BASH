#!/usr/bin/env python3

"""
UPnP Deep Scanner - Enhanced Version (Python 3.11)

Features:
1) Multicast or unicast SSDP discovery of UPnP devices
2) Fetches device descriptors (XML), storing malformed XML in a file for debugging
3) Handles relative SCPD and control URLs by using:
   - <URLBase> from the descriptor if present
   - Otherwise, deriving a fallback base from the LOCATION header
4) Enumerates services, fetches & parses SCPD for actions
5) Demonstrates multiple SOAP calls on WANIPConnection/WANPPPConnection:
   - GetExternalIPAddress
   - GetGenericPortMappingEntry (index=0 as a sample)
6) Graceful error handling for malformed or partial UPnP implementations

Usage:
  python upnp_deep_scanner.py
  python upnp_deep_scanner.py --target 192.168.1.100
  python upnp_deep_scanner.py --timeout 5.0
"""

import socket
import argparse
import requests
import sys
import time
import xml.etree.ElementTree as ET
import urllib.parse
import datetime
import os
from typing import List, Tuple, Dict, Optional, Union

# SSDP Multicast address and port
SSDP_MCAST_ADDR = "239.255.255.250"
SSDP_PORT = 1900

# Basic SSDP M-SEARCH request for all UPnP devices
SSDP_MSEARCH = (
    "M-SEARCH * HTTP/1.1\r\n"
    f"HOST: {SSDP_MCAST_ADDR}:{SSDP_PORT}\r\n"
    'MAN: "ssdp:discover"\r\n'
    "ST: ssdp:all\r\n"
    "MX: 2\r\n"
    "\r\n"
)


def send_msearch(target: Optional[str] = None, timeout: float = 2.0) -> List[Tuple[str, Tuple[str, int]]]:
    """
    Send an SSDP M-SEARCH request to discover UPnP devices.  
    Depending on the 'target' parameter, this can be unicast or multicast.

    :param target: The IP address (str) for unicast or None for multicast.
    :param timeout: The time in seconds to wait for SSDP responses.
    :return: A list of tuples (raw_response, (ip, port)) containing the
             response string and the remote address/port of the responder.
    """
    responses = []

    # Create a UDP socket
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP) as sock:
        # Allow reusing the address in case of repeated runs
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.settimeout(timeout)

        if target:
            # Send M-SEARCH directly to the target on SSDP_PORT
            destination = (target, SSDP_PORT)
        else:
            # Multicast to the standard SSDP address/port
            destination = (SSDP_MCAST_ADDR, SSDP_PORT)

        # Send the SSDP M-SEARCH request
        try:
            sock.sendto(SSDP_MSEARCH.encode("utf-8"), destination)
        except socket.error as e:
            print(f"[ERROR] Unable to send M-SEARCH: {e}")
            return responses

        # Collect responses until timeout
        start_time = time.time()
        while True:
            if time.time() - start_time > timeout:
                break
            try:
                data, addr = sock.recvfrom(65507)
                # Decode response while preserving unknown characters
                resp_str = data.decode("utf-8", errors="replace")
                responses.append((resp_str, addr))
            except socket.timeout:
                break
            except Exception as e:
                print(f"[ERROR] Exception receiving SSDP response: {e}")
                break

    return responses


def parse_ssdp_responses(
    responses: List[Tuple[str, Tuple[str, int]]]
) -> Dict[str, Tuple[str, int]]:
    """
    Extract and aggregate LOCATION headers from raw SSDP M-SEARCH responses.

    :param responses: List of (response_string, (ip, port)) tuples.
    :return: A dictionary mapping { location_url: (ip, port) }.
             location_url is from the "LOCATION" header of the UPnP device.
    """
    devices = {}
    for resp, (ip, port) in responses:
        lines = resp.split("\r\n")
        location = None
        # Look for LOCATION header in each response
        for line in lines:
            if line.lower().startswith("location:"):
                location = line.split(":", 1)[1].strip()
                break
        if location:
            devices[location] = (ip, port)
    return devices


def store_malformed_xml(raw_data: str, location: str) -> str:
    """
    Store raw malformed XML to a local file for debugging.

    :param raw_data: The raw XML text that failed parsing.
    :param location: The device LOCATION or some identifier for naming.
    :return: The absolute file path where the malformed XML is stored.
    """
    # Create a filename based on current time and sanitized location
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_loc = location.replace(":", "_").replace("/", "_")
    filename = f"malformed_{safe_loc}_{timestamp}.xml"

    # Write to file
    with open(filename, "w", encoding="utf-8") as f:
        f.write(raw_data)

    return os.path.abspath(filename)


def fetch_device_description(url: str) -> Optional[str]:
    """
    Fetch the root device description XML from a UPnP device.

    :param url: The LOCATION URL from an SSDP response.
    :return: The raw text (XML or otherwise) on success, or None on error.
    """
    try:
        response = requests.get(url, timeout=5)
        response.raise_for_status()

        content_type = response.headers.get("Content-Type", "").lower()
        if "xml" not in content_type:
            print(f"[WARNING] Content-Type '{content_type}' might not be valid XML.")

        return response.text

    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Could not fetch device description from {url}: {e}")
        return None


def derive_base_url(device_location: str, url_base_tag: str) -> str:
    """
    Attempt to resolve a base URL for subsequent requests to the UPnP device.

    1) If the device descriptor provided <URLBase>, use that.
    2) Otherwise, parse the LOCATION header to get a fallback base URL.

    :param device_location: The LOCATION header (e.g., "http://192.168.1.10:8080/rootDesc.xml").
    :param url_base_tag: The <URLBase> found in the XML, if present.
    :return: A string with the best-guess base URL, or an empty string if resolution is impossible.
    """
    url_base_tag = url_base_tag.strip()
    if url_base_tag:
        # If <URLBase> is fully qualified (starts with http), use it directly.
        if url_base_tag.lower().startswith("http"):
            return url_base_tag
        else:
            # <URLBase> might be relative. Combine it with LOCATION.
            return urllib.parse.urljoin(device_location, url_base_tag)
    else:
        # Fallback: derive from LOCATION if no <URLBase> is provided.
        parsed = urllib.parse.urlparse(device_location)
        base_fallback = f"{parsed.scheme}://{parsed.netloc}"
        return base_fallback


def parse_device_description(xml_data: str, device_location: str) -> Optional[Dict[str, Union[str, List, Dict]]]:
    """
    Parse the UPnP device description XML. Return a dictionary with device metadata.

    If parsing fails, store the raw data to a file for debugging and return None.

    :param xml_data: The device description XML (as a string).
    :param device_location: The LOCATION header for fallback base URL derivation.
    :return: A dictionary with parsed device info, or None if parsing fails.
    """
    info = {
        "deviceType": "",
        "friendlyName": "",
        "manufacturer": "",
        "modelName": "",
        "UDN": "",
        "presentationURL": "",
        "iconList": [],
        "modelNumber": "",
        "serialNumber": "",
        "services": [],
        "resolvedBase": ""  # We'll store our best guess for base URLs here.
    }

    try:
        root = ET.fromstring(xml_data)
    except ET.ParseError as e:
        print(f"[WARNING] Malformed or invalid XML from {device_location}: {e}")
        # Store the raw invalid XML for debugging
        path = store_malformed_xml(xml_data, device_location)
        print(f"    [!] Stored invalid XML to {path}")
        return None

    # Extract <URLBase> if present for deriving base URL
    url_base_elem = root.find("{*}URLBase")
    url_base_tag = url_base_elem.text if (url_base_elem is not None and url_base_elem.text) else ""

    # Derive final base URL
    info["resolvedBase"] = derive_base_url(device_location, url_base_tag)

    # Look for <device> element
    device_elem = root.find(".//{*}device")
    if not device_elem:
        return info

    # Extract common device tags
    for tag in [
        "deviceType", "friendlyName", "manufacturer", "modelName", "UDN",
        "modelNumber", "serialNumber", "presentationURL"
    ]:
        elem = device_elem.find(f".//{{*}}{tag}")
        if elem is not None and elem.text:
            info[tag] = elem.text.strip()

    # Look for icons in <iconList>
    icon_list_elem = device_elem.find(".//{*}iconList")
    if icon_list_elem is not None:
        for icon in icon_list_elem.findall("{*}icon"):
            icon_info = {
                "mimetype": icon.findtext("{*}mimetype", default="").strip(),
                "width": icon.findtext("{*}width", default="").strip(),
                "height": icon.findtext("{*}height", default="").strip(),
                "depth": icon.findtext("{*}depth", default="").strip(),
                "url": icon.findtext("{*}url", default="").strip(),
            }
            info["iconList"].append(icon_info)

    # Look for services in <serviceList>
    service_list_elem = device_elem.find(".//{*}serviceList")
    if service_list_elem is not None:
        for service in service_list_elem.findall("{*}service"):
            service_info = {
                "serviceType": service.findtext("{*}serviceType", default="").strip(),
                "serviceId": service.findtext("{*}serviceId", default="").strip(),
                "controlURL": service.findtext("{*}controlURL", default="").strip(),
                "eventSubURL": service.findtext("{*}eventSubURL", default="").strip(),
                "SCPDURL": service.findtext("{*}SCPDURL", default="").strip()
            }
            info["services"].append(service_info)

    return info


def fetch_scpd(scpd_url: str, base_url: str) -> Optional[str]:
    """
    Fetch the SCPD (Service Control Point Definition) XML for a specific service.

    :param scpd_url: The service's SCPD URL (may be relative).
    :param base_url: The derived or declared base URL for the device.
    :return: The SCPD XML as a string, or None on error.
    """
    if not scpd_url:
        return None

    # Resolve a relative URL if needed
    if not scpd_url.lower().startswith("http"):
        if base_url:
            scpd_url = urllib.parse.urljoin(base_url + "/", scpd_url)
        else:
            print(f"[WARNING] SCPD URL '{scpd_url}' is relative; no base URL to resolve.")
            return None

    try:
        r = requests.get(scpd_url, timeout=5)
        r.raise_for_status()
        if "xml" not in r.headers.get("Content-Type", "").lower():
            print(f"[WARNING] SCPD at {scpd_url} might not be valid XML.")
        return r.text
    except requests.exceptions.RequestException as e:
        print(f"[WARNING] Failed to fetch SCPD from {scpd_url}: {e}")
        return None


def parse_scpd(scpd_xml: str) -> List[Dict[str, Union[str, List]]]:
    """
    Parse the SCPD XML to extract actions and arguments.

    :param scpd_xml: The raw SCPD XML as a string.
    :return: A list of dictionaries, each describing one action:
        {
            "name": (action name),
            "arguments": [
                {
                    "name": ...,
                    "direction": ...,
                    "relatedStateVariable": ...
                },
                ...
            ]
        }
    """
    actions = []
    if not scpd_xml:
        return actions

    try:
        root = ET.fromstring(scpd_xml)
    except ET.ParseError as e:
        print(f"[WARNING] Failed to parse SCPD XML: {e}")
        return actions

    action_list = root.find(".//{*}actionList")
    if action_list is not None:
        for action_elem in action_list.findall("{*}action"):
            action_name_elem = action_elem.find("{*}name")
            action_name = action_name_elem.text.strip() if action_name_elem is not None else "UnnamedAction"
            arg_list = []
            argument_list_elem = action_elem.find("{*}argumentList")
            if argument_list_elem is not None:
                for arg_elem in argument_list_elem.findall("{*}argument"):
                    arg_name = arg_elem.findtext("{*}name", default="").strip()
                    arg_dir = arg_elem.findtext("{*}direction", default="").strip()
                    arg_var = arg_elem.findtext("{*}relatedStateVariable", default="").strip()
                    arg_list.append({
                        "name": arg_name,
                        "direction": arg_dir,
                        "relatedStateVariable": arg_var
                    })
            actions.append({
                "name": action_name,
                "arguments": arg_list
            })
    return actions


def soap_call(
    control_url: str,
    service_type: str,
    action_name: str,
    body_xml: str
) -> Optional[str]:
    """
    Send a SOAP request to the specified control endpoint for a particular action.

    :param control_url: Full URL for the service's control endpoint.
    :param service_type: For example, "urn:schemas-upnp-org:service:WANIPConnection:1".
    :param action_name: The SOAP action name, e.g., "GetExternalIPAddress".
    :param body_xml: The XML body inserted under <u:actionName>...</u:actionName>.
    :return: The raw SOAP response text (str) if successful, otherwise None.
    """
    soap_action = f"{service_type}#{action_name}"
    soap_envelope = f"""<?xml version="1.0"?>
<s:Envelope
    xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
    s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:{action_name} xmlns:u="{service_type}">
      {body_xml}
    </u:{action_name}>
  </s:Body>
</s:Envelope>
"""
    headers = {
        "Content-Type": "text/xml; charset=utf-8",
        "SOAPAction": soap_action
    }

    try:
        resp = requests.post(control_url, data=soap_envelope, headers=headers, timeout=5)
        if resp.status_code == 200:
            return resp.text
        else:
            print(f"      [!] SOAP call for {action_name} returned status {resp.status_code}.")
            return None
    except requests.exceptions.RequestException as e:
        print(f"      [!] SOAP call for {action_name} failed: {e}")
        return None


def attempt_get_external_ip(service_info: Dict[str, str], base_url: str) -> None:
    """
    Attempt a SOAP call to GetExternalIPAddress on WANIPConnection or WANPPPConnection services.

    :param service_info: A dictionary describing the service, including keys like
                         "serviceType" and "controlURL".
    :param base_url: The resolved base URL for the device.
    """
    service_type = service_info["serviceType"]
    # Only proceed if the service is WANIPConnection or WANPPPConnection
    if not any(x in service_type for x in ("WANIPConnection", "WANPPPConnection")):
        return

    control_url = service_info["controlURL"]
    # Resolve relative URLs if necessary
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    print(f"      [*] Trying GetExternalIPAddress on {control_url}")
    resp_text = soap_call(control_url, service_type, "GetExternalIPAddress", "")
    if resp_text:
        try:
            root = ET.fromstring(resp_text)
            ip_elem = root.find(".//{*}NewExternalIPAddress")
            if ip_elem is not None and ip_elem.text:
                print(f"      [+] External IP reported: {ip_elem.text}")
            else:
                print("      [!] SOAP call succeeded but no IP found in response.")
        except ET.ParseError as e:
            print(f"      [!] SOAP response parse error: {e}")


def attempt_get_port_mapping(service_info: Dict[str, str], base_url: str) -> None:
    """
    Example SOAP call to retrieve the 0th port mapping entry (GetGenericPortMappingEntry).

    In a real-world scenario, you might iterate through multiple indexes or handle them dynamically.

    :param service_info: The service info dict (serviceType, controlURL, etc.).
    :param base_url: The resolved base URL for the device.
    """
    service_type = service_info["serviceType"]
    if not any(x in service_type for x in ("WANIPConnection", "WANPPPConnection")):
        return

    control_url = service_info["controlURL"]
    if not control_url.lower().startswith("http"):
        control_url = urllib.parse.urljoin(base_url + "/", control_url)

    # We'll try NewPortMappingIndex=0 as a basic demonstration
    body_xml = "<NewPortMappingIndex>0</NewPortMappingIndex>"
    print(f"      [*] Trying GetGenericPortMappingEntry(index=0) on {control_url}")
    resp_text = soap_call(control_url, service_type, "GetGenericPortMappingEntry", body_xml)
    if resp_text:
        try:
            root = ET.fromstring(resp_text)
            new_ext_port = root.find(".//{*}NewExternalPort")
            new_int_client = root.find(".//{*}NewInternalClient")

            if new_ext_port is not None:
                print(f"      [+] External Port: {new_ext_port.text}")
            if new_int_client is not None:
                print(f"      [+] Internal Client: {new_int_client.text}")

            if (new_ext_port is None) and (new_int_client is None):
                print("      [!] No port mapping info found; possibly no entry at index=0.")
        except ET.ParseError as e:
            print(f"      [!] SOAP port mapping parse error: {e}")


def enumerate_upnp_devices(target: Optional[str] = None, timeout: float = 2.0) -> None:
    """
    Main scanning & enumeration workflow:
    1) Perform SSDP discovery (either unicast or multicast).
    2) Fetch device descriptors and parse them.
    3) For each service in the device descriptor, fetch and parse the SCPD.
    4) Attempt sample SOAP calls on WANIPConnection/WANPPPConnection.

    :param target: The unicast target IP or None for multicast scanning.
    :param timeout: Time in seconds to wait for SSDP responses.
    """
    print("[*] Sending M-SEARCH request...")
    responses = send_msearch(target, timeout)
    if not responses:
        print("[!] No SSDP responses received.")
        return

    print("[*] Parsing SSDP responses for device LOCATIONs...")
    devices = parse_ssdp_responses(responses)
    if not devices:
        print("[!] No valid LOCATION headers found in responses.")
        return

    # Process each discovered device
    for location, (ip, port) in devices.items():
        print(f"\n[+] Found device responding from {ip}:{port}")
        print(f"    LOCATION: {location}")

        # Fetch the device descriptor (root XML)
        xml_data = fetch_device_description(location)
        if not xml_data:
            continue

        # Parse the device description
        device_info = parse_device_description(xml_data, device_location=location)
        if not device_info:
            print("    [!] Invalid or malformed device description. Skipping.")
            continue

        # Print relevant device metadata
        print(f"    Device Type:     {device_info['deviceType']}")
        print(f"    Friendly Name:   {device_info['friendlyName']}")
        print(f"    Manufacturer:    {device_info['manufacturer']}")
        print(f"    Model Name:      {device_info['modelName']}")
        print(f"    Model Number:    {device_info['modelNumber']}")
        print(f"    Serial Number:   {device_info['serialNumber']}")
        print(f"    UDN:             {device_info['UDN']}")
        if device_info["presentationURL"]:
            print(f"    PresentationURL: {device_info['presentationURL']}")

        # Print icon(s)
        if device_info["iconList"]:
            print("    Icon(s):")
            for icon in device_info["iconList"]:
                print(f"       - URL: {icon['url']} (type: {icon['mimetype']} "
                      f"{icon['width']}x{icon['height']} depth={icon['depth']})")

        # Print services and attempt to fetch SCPD
        if device_info["services"]:
            print("    Services:")
            for svc in device_info["services"]:
                print(f"       - Service Type: {svc['serviceType']}")
                print(f"         Service ID:   {svc['serviceId']}")
                print(f"         Control URL:  {svc['controlURL']}")
                print(f"         EventSub URL: {svc['eventSubURL']}")
                print(f"         SCPD URL:     {svc['SCPDURL']}")

                # Fetch and parse SCPD (if any)
                scpd_xml = fetch_scpd(svc["SCPDURL"], device_info["resolvedBase"])
                actions = parse_scpd(scpd_xml) if scpd_xml else []
                if actions:
                    print("         Actions:")
                    for action in actions:
                        print(f"           - {action['name']}")
                        if action["arguments"]:
                            for arg in action["arguments"]:
                                print(
                                    f"               * Arg: {arg['name']} ({arg['direction']}), "
                                    f"StateVar={arg['relatedStateVariable']}"
                                )
                        else:
                            print("               (No arguments)")

                # Demonstrate SOAP calls for IGD (InternetGatewayDevice)-like services
                attempt_get_external_ip(svc, device_info["resolvedBase"])
                attempt_get_port_mapping(svc, device_info["resolvedBase"])
        else:
            print("    Services:       None found")


def main() -> None:
    """
    Entry point for the Enhanced UPnP Deep Scanner:
    - Parses command-line arguments.
    - Invokes unicast or multicast SSDP discovery based on '--target'.
    - Enumerates discovered UPnP devices and performs sample SOAP calls.
    """
    parser = argparse.ArgumentParser(description="Enhanced UPnP Deep Scanner")
    parser.add_argument(
        "--target", "-t", help="Unicast target IP for UPnP scanning"
    )
    parser.add_argument(
        "--timeout", "-o", type=float, default=2.0,
        help="SSDP response wait time in seconds (default=2.0)"
    )
    args = parser.parse_args()

    if args.target:
        print(f"[*] Unicast scanning {args.target} for UPnP devices...\n")
        enumerate_upnp_devices(target=args.target, timeout=args.timeout)
    else:
        print("[*] Multicast scanning for UPnP devices on the local network...\n")
        enumerate_upnp_devices(timeout=args.timeout)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[!] Scan interrupted by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\n[ERROR] Unexpected exception: {e}")
        sys.exit(1)
