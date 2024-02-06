from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
with open("jwtRS256.key.pub", "rb") as key_file:
    pub_key = serialization.load_pem_public_key(
        key_file.read(),
    )
with open("jwtRS256.key", "rb") as key_file:
    priv_key = serialization.load_pem_private_key(
        key_file.read(),
        password=None,
    )
enc_text=b"ciao"
sig = priv_key.sign(enc_text,padding.PSS(mgf=padding.MGF1(hashes.SHA256()),salt_length=padding.PSS.MAX_LENGTH),hashes.SHA256())
try:
    pub_key.verify(
        sig,
        enc_text,
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH
        ),
        hashes.SHA256()
    )
    print("Valid signature")
except:
    print("[ERROR]: Invalid signature!")

