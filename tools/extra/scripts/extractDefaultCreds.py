# =============================================================================
# NAME        : extract_http_default_accounts.py
# DESCRIPTION : Extracts default credentials from an Nmap XML file for services
#               using the 'http-default-accounts' script.
# AUTHOR      : Adam Compton
# DATE CREATED: 2025-06-06 23:49:00
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2025-06-06 23:49:00  | Adam Compton | Initial creation.
# =============================================================================

import argparse
import logging
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
from typing import Optional, Tuple, Dict, List, Any

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')


def parse_xml_file(filename: Path) -> Tuple[Optional[ET.Element], Optional[str]]:
    """
    Parses an XML file and returns the root element.

    Args:
        filename (Path): Path to the XML file.

    Returns:
        Tuple[Optional[ET.Element], Optional[str]]: Root element and error message, if any.
    """
    try:
        tree = ET.parse(filename)
        return tree.getroot(), None
    except ET.ParseError as e:
        return None, f"Error parsing XML: {e}"
    except OSError as e:
        return None, f"File access error: {e}"


def parse_credentials(table: ET.Element) -> List[Dict[str, str]]:
    """
    Extracts credentials from a nested table element.

    Args:
        table (ET.Element): XML element containing credential tables.

    Returns:
        List[Dict[str, str]]: List of username/password pairs.
    """
    credentials = []
    for cred in table.findall("table"):
        cred_info = {"username": "", "password": ""}
        for elem in cred.findall("elem"):
            match elem.get("key"):
                case "username":
                    cred_info["username"] = elem.text or ""
                case "password":
                    cred_info["password"] = elem.text or ""
        credentials.append(cred_info)
    return credentials


def parse_script(script: ET.Element, ip: str, hostname: str,
                 port_id: str, service_name: str) -> Dict[str, Any]:
    """
    Parses a script element for service info and credentials.

    Args:
        script (ET.Element): The script element from the port.
        ip (str): IP address of the host.
        hostname (str): Hostname of the host.
        port_id (str): Port number as string.
        service_name (str): Name of the service on the port.

    Returns:
        Dict[str, Any]: Extracted service details including credentials.
    """
    service_info = {
        "ip": ip,
        "hostname": hostname,
        "port": port_id,
        "service": service_name,
        "path": "",
        "cpe": "",
        "credentials": []
    }

    for table in script.findall("table"):
        key = table.get("key")
        if key:
            service_info["service"] = key
        for elem in table:
            if elem.tag == "elem" and elem.get("key") == "path":
                service_info["path"] = elem.text or ""
            elif elem.tag == "table" and elem.get("key") == "credentials":
                service_info["credentials"] = parse_credentials(elem)

    return service_info


def extract_information_from_xml(root: Optional[ET.Element]) -> Dict[str, Dict[str, Any]]:
    """
    Walks the XML root to extract information about vulnerable services.

    Args:
        root (Optional[ET.Element]): Root element of the XML tree.

    Returns:
        Dict[str, Dict[str, Any]]: Mapping of IP:port to extracted data.
    """
    if root is None:
        return {}

    results = {}
    for host in root.findall("host"):
        ip = ""
        for addr in host.findall("address"):
            if addr.attrib.get("addrtype") == "ipv4":
                ip = addr.attrib.get("addr", "")
                break
        hostname = ""
        hostname_elem = host.find("hostnames/hostname")
        if hostname_elem is not None:
            hostname = hostname_elem.attrib.get("name", "")

        for port in host.findall("ports/port"):
            port_id = port.attrib.get("portid", "")
            service = port.find("service")
            service_name = service.attrib.get("name", "") if service is not None else ""

            script = port.find("script")
            if script is not None and script.attrib.get("id") == "http-default-accounts":
                key = f"{ip}:{port_id}"
                results[key] = parse_script(script, ip, hostname, port_id, service_name)

    return results


def main() -> None:
    """
    Main function to handle argument parsing and extraction logic.
    """
    parser = argparse.ArgumentParser(
        description="Extract default HTTP credentials from an Nmap XML scan."
    )
    parser.add_argument(
        "-f", "--file", type=Path, required=True,
        help="Path to the Nmap XML output file."
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true",
        help="Enable verbose output for debugging."
    )
    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    if not args.file.is_file():
        logging.error(f"Input file not found: {args.file}")
        sys.exit(1)

    root, error = parse_xml_file(args.file)
    if error:
        logging.error(f"Failed to parse XML: {error}")
        sys.exit(1)

    info = extract_information_from_xml(root)
    if not info:
        logging.info("No http-default-accounts data found.")
        return

    for _, entry in info.items():
        for cred in entry["credentials"]:
            output = (
                f"{entry['ip']}:{entry['port']}{entry['path']},"
                f"{entry['service']},{cred['username']}:{cred['password']}"
            )
            print(output)


if __name__ == "__main__":
    main()