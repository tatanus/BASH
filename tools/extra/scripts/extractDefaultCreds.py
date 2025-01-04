import xml.etree.ElementTree as ET
import argparse
import os
import sys

def parse_xml_file(filename):
    """
    Parses an XML file and returns the root element and an error message if applicable.

    Args:
        filename (str): The path to the XML file to be parsed.

    Returns:
        tuple: A tuple containing the root element and an error message (or None if no error).
    """
    try:
        tree = ET.parse(filename)
        root = tree.getroot()
        return root, None  # Return root and None for no error
    except ET.ParseError as e:
        return None, f"Error parsing XML content: {e}"
    except IOError as e:
        return None, f"Unable to open file: {e}"


def extract_information_from_xml(root):
    """
    Extracts information from the XML root element and returns it as a dictionary.

    Args:
        root (ET.Element): The root element of the parsed XML.

    Returns:
        dict: A dictionary containing extracted information.
    """
    info = {}

    if root is None:
        return info  # Return empty info if root is None

    # Iterate over each host element
    for host in root.findall('host'):
        # Extract IP address and hostname
        address = host.find('address')
        ip = address.get('addr') if address is not None else ''

        hostname_elements = host.find('hostnames')
        hostname = (hostname_elements.find('hostname').get('name')
                    if hostname_elements is not None and hostname_elements.find('hostname') is not None
                    else '')

        # Iterate over each port element
        for port in host.find('ports').findall('port'):
            port_id = port.get('portid')
            service_name = (port.find('service').get('name')
                            if port.find('service') is not None
                            else '')

            # Extract script output
            script = port.find('script')
            if script is not None and script.get('id') == 'http-default-accounts':
                service_info = {
                    "cpe": "",
                    "path": "",
                    "credentials": [],
                    "ip": ip,
                    "hostname": hostname,
                    "port": port_id,
                    "service": service_name
                }
                for table in script.findall('table'):
                    if table.get('key'):
                        service_info['service'] = table.get('key')
                    for elem in table:
                        if elem.tag == "elem":
                            if elem.get('key') == "path":
                                service_info["path"] = elem.text
                        elif elem.tag == "table" and elem.get('key') == "credentials":
                            for cred in elem:
                                cred_info = {"username": "", "password": ""}
                                if cred.tag == "table":
                                    for c in cred:
                                        if c.get('key') == "username":
                                            cred_info["username"] = c.text
                                        elif c.get('key') == "password":
                                            cred_info["password"] = c.text
                                    service_info["credentials"].append(cred_info)
                info[f"{ip}:{port_id}"] = service_info

    return info

def main():
    """
    Main function to parse XML file, extract information, and display it.
    """
    parser = argparse.ArgumentParser(description="Extract default credentials from an XML file.")
    parser.add_argument("file", help="Path to the XML file.")
    args = parser.parse_args()

    # Validate file path
    if not os.path.isfile(args.file):
        print(f"Error: File '{args.file}' does not exist.")
        sys.exit(1)

    # Parse the XML file
    root, err = parse_xml_file(args.file)

    if root is not None:
        extracted_info = extract_information_from_xml(root)
        if extracted_info:
            for key, details in extracted_info.items():
                for cred in details["credentials"]:
                    print(f"{details['ip']}:{details['port']}{details['path']},"
                          f"{details['service']},{cred['username']}:{cred['password']}")
        else:
            print("No information extracted from XML.")
    else:
        print("Error:", err)
        sys.exit(1)


if __name__ == "__main__":
    main()
