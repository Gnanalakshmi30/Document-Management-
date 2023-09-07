import sys
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.backends import default_backend
from cryptography.fernet import Fernet
import base64

SECRET_KEY = "1539ee7352874ce36b3cb2c8b914f1ac51e8d02bcf238e3c2b7343f2464386b4"


def decrypt_information(license_key: str, last: bool = False) -> str:

    encrypted_message = license_key.encode('latin-1')
    salt = SECRET_KEY.encode()

    kdf = PBKDF2HMAC(

        algorithm=hashes.SHA256(),

        length=32,

        salt=salt,

        iterations=100000,

        backend=default_backend()

    )

    key = kdf.derive(SECRET_KEY.encode())

    cipher = Fernet(base64.urlsafe_b64encode(key))

    decrypted_message = cipher.decrypt(encrypted_message)

    decrypted_message_str = decrypted_message.decode()



    if last:

        mac_address, product_name, num_licenses = decrypted_message_str.split('|')

        return mac_address, product_name, num_licenses

    else:

        return decrypted_message_str



def decrypt_license_key(license_key: str, decryption_count: int = 3) -> str:

    for _ in range(decryption_count - 1):

        license_key = decrypt_information(license_key)

    license_key = decrypt_information(license_key, last=True)

    print(license_key) 

lincenkey = sys.argv[1]
decrypt_license_key(lincenkey)


