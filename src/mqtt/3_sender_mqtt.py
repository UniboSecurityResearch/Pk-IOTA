# [GG] copied from simple_transaction.py from iota-sdk
import os

from dotenv import load_dotenv

from iota_sdk import SendParams, Wallet

load_dotenv()

# This example sends a transaction.

wallet = Wallet(os.environ['WALLET_DB_PATH'])

account = wallet.get_account('Alice')

# Sync account with the node
response = account.sync()

if 'STRONGHOLD_PASSWORD' not in os.environ:
    raise Exception(".env STRONGHOLD_PASSWORD is undefined, see .env.example")

wallet.set_stronghold_password(os.environ["STRONGHOLD_PASSWORD"])

outputs = [{
    "address": "rms1qqvnuxck92uwvf2hjpr0m9m0rj565efvchcy0xj9u5w8cwprqealva8g48e",
    "amount": "42600",
}]

testo = ""
file_path = "./cert.txt"
with open(file_path, 'r') as file:
    for line in file:
    	testo += line
print(testo)
tag = '0x'+'certificato'.encode('utf-8').hex()
data = '0x'+testo.encode('utf-8').hex()

transaction = account.send(100000,"rms1qqvnuxck92uwvf2hjpr0m9m0rj565efvchcy0xj9u5w8cwprqealva8g48e",options={"taggedDataPayload": {"type": 5, "tag": tag, "data": data}})
print(transaction)
print(f'Check your block on: {os.environ["EXPLORER_URL"]}/block/{transaction.blockId}')
