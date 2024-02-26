# Copyright 2023 IOTA Stiftung
# SPDX-License-Identifier: Apache-2.0

# This example sends tokens to an address.

import os
import time

from dotenv import load_dotenv

from iota_sdk import SyncOptions, Wallet

# This example uses secrets in environment variables for simplicity which
# should not be done in production.
load_dotenv()

for env_var in ['WALLET_DB_PATH', 'STRONGHOLD_PASSWORD', 'EXPLORER_URL']:
    if env_var not in os.environ:
        raise Exception(f'.env {env_var} is undefined, see .env.example')

wallet = Wallet(os.environ.get('WALLET_DB_PATH'))

account = wallet.get_account('Alice')

wallet.set_stronghold_password(os.environ["STRONGHOLD_PASSWORD"])

# Set sync_only_most_basic_outputs to True if not interested in outputs that are timelocked,
# have a storage deposit return, expiration or are nft/alias/foundry outputs.
balance = account.sync(SyncOptions(sync_only_most_basic_outputs=True))
print('Balance', balance)
tic = time.perf_counter()
transaction = account.send(
    100000,
    "rms1qpszqzadsym6wpppd6z037dvlejmjuke7s24hm95s9fg9vpua7vluaw60xu",
)
print(
    f'Check your block on: {os.environ["EXPLORER_URL"]}/block/{transaction.blockId}')
toc = time.perf_counter()
print('-----------------------------')
print(f'Time for the transaction: {toc-tic:0.8f} seconds')
print('-----------------------------')
