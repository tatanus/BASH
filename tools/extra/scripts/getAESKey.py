import sys
from binascii import unhexlify, Error as BinasciiError
from Crypto.Hash import HMAC, SHA1


def derive_aes_keys(nt_hash, username, domain):
    """
    Derives AES keys (128-bit and 256-bit) for Kerberos from an NT hash.

    :param nt_hash: Hexadecimal NT hash string
    :param username: Username in Active Directory
    :param domain: Domain name
    :return: Tuple containing AES128 and AES256 keys as hexadecimal strings
    """
    try:
        # Convert NT hash from hex to binary
        binary_nt_hash = unhexlify(nt_hash)
    except BinasciiError as e:
        raise ValueError(f"Invalid NT hash format: {e}")

    # Prepare identity string in UTF-16LE encoding
    try:
        identity = (username.upper() + domain).encode('utf-16-le')
    except Exception as e:
        raise ValueError(f"Failed to encode identity string: {e}")

    # Calculate AES keys using HMAC-SHA1
    try:
        aes128 = HMAC.new(binary_nt_hash, identity, SHA1).digest()[:16]
        aes256 = HMAC.new(binary_nt_hash, identity, SHA1).digest()[:32]
    except Exception as e:
        raise ValueError(f"Error generating AES keys: {e}")

    return aes128.hex(), aes256.hex()


def validate_nt_hash(nt_hash):
    """
    Validates the NT hash input to ensure it is a valid hexadecimal string.

    :param nt_hash: NT hash string
    :return: None
    :raises ValueError: If the NT hash is invalid
    """
    if len(nt_hash) != 32:
        raise ValueError("NT hash must be exactly 32 hexadecimal characters.")
    try:
        unhexlify(nt_hash)
    except BinasciiError:
        raise ValueError("NT hash contains invalid characters.")


def parse_arguments():
    """
    Parses command-line arguments and validates input.

    :return: Tuple containing NT hash, username, and domain
    """
    if len(sys.argv) != 4:
        script_name = sys.argv[0]
        print(f"Usage: python3 {script_name} <nt_hash> <username> <domain>")
        print(f"Example: python3 {script_name} 4dc0fdca451c61fe48bbcdf6d1c1424d John.Doe example.org")
        sys.exit(1)

    nt_hash = sys.argv[1]
    username = sys.argv[2]
    domain = sys.argv[3]

    # Validate NT hash
    try:
        validate_nt_hash(nt_hash)
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)

    return nt_hash, username, domain

def main():
    """
    Main function to parse command-line arguments and derive AES keys.
    """
    nt_hash, username, domain = parse_arguments()

    try:
        aes128_key, aes256_key = derive_aes_keys(nt_hash, username, domain)
        print(f"AES128 Key: {aes128_key}")
        print(f"AES256 Key: {aes256_key}")
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
    