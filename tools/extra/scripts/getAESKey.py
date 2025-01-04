import sys
import logging
import re
from binascii import unhexlify, Error as BinasciiError
from Crypto.Hash import HMAC, SHA1

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

def derive_aes_keys(nt_hash: str, username: str, domain: str) -> tuple[str, str]:
    """
    Derives AES keys (128-bit and 256-bit) for Kerberos from an NT hash.

    :param nt_hash: Hexadecimal NT hash string
    :param username: Username in Active Directory
    :param domain: Domain name
    :return: Tuple containing AES128 and AES256 keys as hexadecimal strings
    """
    try:
        decoded_nt_hash = unhexlify(nt_hash)
    except BinasciiError as e:
        raise ValueError(f"Invalid NT hash format: {e}")

    try:
        identity = (username.upper() + domain).encode('utf-16-le')
    except UnicodeEncodeError as e:
        raise ValueError(f"Failed to encode identity string: {e}")

    try:
        digest = HMAC.new(decoded_nt_hash, identity, SHA1).digest()
        aes128 = digest[:16]
        aes256 = digest[:32]
    except Exception as e:
        raise ValueError(f"Error generating AES keys: {e}")

    return aes128.hex(), aes256.hex()

def validate_nt_hash(nt_hash: str) -> None:
    """
    Validates the NT hash input to ensure it is a valid hexadecimal string.

    :param nt_hash: NT hash string
    :raises ValueError: If the NT hash is invalid
    """
    if not re.fullmatch(r'[0-9a-fA-F]{32}', nt_hash):
        raise ValueError("NT hash must be a valid 32-character hexadecimal string.")

def parse_arguments() -> tuple[str, str, str]:
    """
    Parses command-line arguments and validates input.

    :return: Tuple containing NT hash, username, and domain
    """
    if len(sys.argv) != 4:
        script_name = sys.argv[0]
        print(f"Usage: python3 {script_name} <nt_hash> <username> <domain>")
        print(f"Example: python3 {script_name} 4dc0fdca451c61fe48bbcdf6d1c1424d John.Doe example.org")
        sys.exit(1)

    nt_hash, username, domain = sys.argv[1], sys.argv[2], sys.argv[3]

    try:
        validate_nt_hash(nt_hash)
    except ValueError as e:
        logging.error(f"Error: {e}")
        sys.exit(1)

    return nt_hash, username, domain

def main() -> None:
    """
    Main function to parse command-line arguments and derive AES keys.
    """
    nt_hash, username, domain = parse_arguments()

    try:
        aes128_key, aes256_key = derive_aes_keys(nt_hash, username, domain)
        logging.info(f"AES128 Key: {aes128_key}")
        logging.info(f"AES256 Key: {aes256_key}")
    except ValueError as e:
        logging.error(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
