import xml.etree.ElementTree as ET
import argparse
import os
import sys
import logging
from typing import Tuple, Optional, Dict, Any, List

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')


def parse_xml_file(filename: str) -> Tuple[Optional[ET.Element], Optional[str]]:
    """
    Parses an XML file and returns the root element and an error message if applicable.

    Args:
        filename (str): The path to the XML file to be parsed.

    Returns:
        tuple: A tuple containing the root element and an error message (or None if no error).
    """
    try:
        tree = ET.parse(filename)
        return tree.getroot(), None
    except ET.ParseError as e:
        return None, f"Error parsing XML content: {e}"
    except IOError as e:
        return None, f"Unable to open file: {e}"


def parse_credentials(table: ET.Element) -> List[Dict[str, str]]:
    """
    Parses the credentials from a given table element.

    Args:
        table (ET.Element): The XML table element containing credential information.

    Returns:
        list: A list of dictionaries containing credentials.
    """
    credentials = []
    for cred in table.findall("table"):
        cred_info = {"username": "", "password": ""}
        for elem in cred:
            if elem.tag == "elem":
                if elem.get("key") == "username":
                    cred_info["username"] = elem.text or ""
                elif elem.get("key") == "password":
                    cred_info["password"] = elem.text or ""
        credentials.append(cred_info)
    return credentials


def parse_script(script: ET.Element, ip: str, hostname: str, port_id: str, service_name: str) -> Dict[str, Any]:
    """
    Parses the script output for service details and credentials.

    Args:
        script (ET.Element): The XML script element.
        ip (str): The IP address of the host.
        hostname (str): The hostname of the host.
        port_id (str): The port number.
        service_name (str): The name of the service.

    Returns:
        dict: A dictionary containing parsed information.
    """
    service_info = {
        "cpe": "",
        "path": "",
        "credentials": [],
        "ip": ip,
        "hostname": hostname,
        "port": port_id,
        "service": service_name
    }

    for table in script.findall("table"):
        if table.get("key"):
            service_info["service"] = table.get("key")
        for elem in table:
            if elem.tag == "elem" and elem.get("key") == "path":
                service_info["path"] = elem.text or ""
            elif elem.tag == "table" and elem.get("key") == "credentials":
                service_info["credentials"] = parse_credentials(elem)

    return service_info


def extract_information_from_xml(root: Optional[ET.Element]) -> Dict[str, Dict[str, Any]]:
    """
    Extracts information from the XML root element and returns it as a dictionary.

    Args:
        root (ET.Element): The root element of the parsed XML.

    Returns:
        dict: A dictionary containing extracted information.
    """
    if root is None:
        return {}

    info = {}
    for host in root.findall("host"):
        address = host.find("address")
        ip = address.get("addr") if address is not None else ""

        hostname_elements = host.find("hostnames")
        hostname = (hostname_elements.find("hostname").get("name")
                    if hostname_elements is not None and hostname_elements.find("hostname") is not None
                    else "")

        ports = host.find("ports")
        if ports is None:
            continue

        for port in ports.findall("port"):
            port_id = port.get("portid", "")
            service = port.find("service")
            service_name = service.get("name") if service is not None else ""

            script = port.find("script")
            if script is not None and script.get("id") == "http-default-accounts":
                service_info = parse_script(script, ip, hostname, port_id, service_name)
                info[f"{ip}:{port_id}"] = service_info

    return info


def main() -> None:
    """
    Main function to parse XML file, extract information, and display it.
    """
    parser = argparse.ArgumentParser(description="Extract default credentials from an XML file.")
    parser.add_argument("file", help="Path to the XML file.")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose output.")
    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    if not os.path.isfile(args.file):
        logging.error(f"Error: File '{args.file}' does not exist.")
        sys.exit(1)

    root, err = parse_xml_file(args.file)

    if root is not None:
        extracted_info = extract_information_from_xml(root)
        if extracted_info:
            for key, details in extracted_info.items():
                for cred in details["credentials"]:
                    print(f"{details['ip']}:{details['port']}{details['path']},"
                          f"{details['service']},{cred['username']}:{cred['password']}")
        else:
            logging.info("No information extracted from XML.")
    else:
        logging.error(f"Error: {err}")
        sys.exit(1)


if __name__ == "__main__":
    main()
