# [GG] based on simple_transaction.py from iota-sdk
import os
import sys

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization

import base64

from dotenv import load_dotenv

from iota_sdk import SendParams, Wallet

load_dotenv()

# Check parameters
if len(sys.argv) > 1:
    # Read path of the certificate received as parameter
    cert_path = sys.argv[1]
else:
    print("[ERROR] Please insert the certificate path --> python3 3_sender_mqtt.py /path/to/certificate.txt")
    exit()

wallet = Wallet(os.environ['WALLET_DB_PATH'])

account = wallet.get_account('Giacomo')

# Sync account with the node
response = account.sync()

if 'STRONGHOLD_PASSWORD' not in os.environ:
    raise Exception(".env STRONGHOLD_PASSWORD is undefined, see .env.example")

wallet.set_stronghold_password(os.environ["STRONGHOLD_PASSWORD"])

outputs = [{
    "address": "rms1qzta3w8ahjd9zez0ncaekvcmkagqh4rsax794t6cr8xqhy9trwcjclxn6ef",
    "amount": "42600",
}]

# Read the certificate

text = ""
with open(cert_path, 'r') as file:
    for line in file:
    	text += line
#print(text)

enc_text=text.encode('utf-8')

# Load the private key to sign the text
with open("jwtRS256.key", "rb") as key_file:
    priv_key = serialization.load_pem_private_key(
        key_file.read(),
        password=None,
    )

#pem stores the serialized private key
pem = priv_key.private_bytes(
   encoding=serialization.Encoding.PEM,
   format=serialization.PrivateFormat.TraditionalOpenSSL,
   encryption_algorithm=serialization.NoEncryption()
)
#print(pem)

#Sign
sig = priv_key.sign(enc_text,padding.PSS(mgf=padding.MGF1(hashes.SHA256()),salt_length=padding.PSS.MAX_LENGTH),hashes.SHA256())




tag = '0x'+'certificato'.encode('utf-8').hex()
data = '0x'+enc_text.hex()+sig.hex()
# # The last 1024 characters are the sign

transaction = account.send(100000,"rms1qqvnuxck92uwvf2hjpr0m9m0rj565efvchcy0xj9u5w8cwprqealva8g48e",options={"taggedDataPayload": {"type": 5, "tag": tag, "data": data}})
print(transaction)
print(f'Check your block on: {os.environ["EXPLORER_URL"]}/block/{transaction.blockId}')
