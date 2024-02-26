# Copyright 2023 IOTA Stiftung
# SPDX-License-Identifier: Apache-2.0

# This example sends tokens to an address.

import os
import sys
import time


from dotenv import load_dotenv

from iota_sdk import SyncOptions, Wallet

# This example uses secrets in environment variables for simplicity which
# should not be done in production.
load_dotenv()

# Check parameters
if len(sys.argv) > 1:
    # Read path of the certificate received as parameter
    cert_path = sys.argv[1]
else:
    print("[ERROR] Please insert the certificate path --> python3 3_sender_mqtt.py /path/to/certificate.txt")
    exit()

for env_var in ['WALLET_DB_PATH', 'STRONGHOLD_PASSWORD', 'EXPLORER_URL']:
    if env_var not in os.environ:
        raise Exception(f'.env {env_var} is undefined, see .env.example')

wallet = Wallet(os.environ.get('WALLET_DB_PATH'))

account = wallet.get_account('Alice')

wallet.set_stronghold_password(os.environ["STRONGHOLD_PASSWORD"])

# Set sync_only_most_basic_outputs to True if not interested in outputs that are timelocked,
# have a storage deposit return, expiration or are nft/alias/foundry outputs.
balance = account.sync(SyncOptions(sync_only_most_basic_outputs=True))


# Read the certificate

text = ""
with open(cert_path, 'r') as file:
    for line in file:
    	text += line
#print(text)

enc_text=text.encode('utf-8')



tag = '0x'+'certificato'.encode('utf-8').hex()
#data = '0x'+enc_text.hex()
data = '0x124549235012'

tic = time.perf_counter()
transaction = account.send(100000,"rms1qqvnuxck92uwvf2hjpr0m9m0rj565efvchcy0xj9u5w8cwprqealva8g48e",options={"taggedDataPayload": {"type": 5, "tag": tag, "data": data}})
toc = time.perf_counter()
print(f'Check your block on: {os.environ["EXPLORER_URL"]}/block/{transaction.blockId}')
print('-----------------------------')
print(f'Time for the transaction: {toc-tic:0.8f} seconds')
print('-----------------------------')
