# Copyright 2023 IOTA Stiftung
# SPDX-License-Identifier: Apache-2.0

# This example sends tokens to an address.

import os
import sys
import time
import binascii

from dotenv import load_dotenv

from iota_sdk import SyncOptions, Wallet

# This example uses secrets in environment variables for simplicity which
# should not be done in production.
load_dotenv()

# Check parameters
if len(sys.argv) > 1:
    # Read path of the certificate received as parameter
    index = sys.argv[1]
else:
    print("[ERROR] Please insert the index of the iteration (FOR TEST)")
    exit()

init_time = time.time()
with open("test2_sender.txt", "a") as testfile:
    init_txt = index + ' - ' + str(init_time) + ' - '
    testfile.write(init_txt)

for env_var in ['WALLET_DB_PATH', 'STRONGHOLD_PASSWORD', 'EXPLORER_URL']:
    if env_var not in os.environ:
        raise Exception(f'.env {env_var} is undefined, see .env.example')

wallet = Wallet(os.environ.get('WALLET_DB_PATH'))

account = wallet.get_account('Giacomo')

wallet.set_stronghold_password(os.environ["STRONGHOLD_PASSWORD"])

# Set sync_only_most_basic_outputs to True if not interested in outputs that are timelocked,
# have a storage deposit return, expiration or are nft/alias/foundry outputs.
account.sync(SyncOptions(sync_only_most_basic_outputs=True))
aftersync_time = time.time()
with open("test_txt_sender.txt", "a") as testfile:
    testfile.write(str(aftersync_time) + ' - ')

addresses = account.addresses()
# Read and encode the certificate
cert_path = 'cert.txt'
text = ""
with open(cert_path, 'r') as file:
    for line in file:
    	text += line

enc_text=text.encode('utf-8')

tag = '0x'+'certificato'.encode('utf-8').hex()
data = '0x'+enc_text.hex()
before_trans_time = time.time()
with open("test2_sender.txt", "a") as testfile:
    testfile.write(str(before_trans_time)+' - ')
#transaction=
account.send(100000,"tst1qqv5avetndkxzgr3jtrswdtz5ze6mag20s0jdqvzk4fwezve8q9vkamkkx0",options={"taggedDataPayload": {"type": 5, "tag": tag, "data": data}})
after_trans_time = time.time()
with open("test2_sender.txt", "a") as testfile:
    testfile.write(str(after_trans_time) + '\n')
#print(f'Check your block on: {os.environ["EXPLORER_URL"]}/block/{transaction.blockId}')
print('-----------------------------')
print(f'[SENDER] Time for the transaction: {after_trans_time-before_trans_time:0.8f} seconds')
print('-----------------------------')

