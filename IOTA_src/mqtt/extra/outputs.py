# [GG] copied from features.py inside hot_tos/outputs from iota-sdk
import json
import os
from dataclasses import asdict

from dotenv import load_dotenv

from iota_sdk import (
    AddressUnlockCondition,
    Client,
    Ed25519Address,
    Utils,
    SenderFeature,
    IssuerFeature,
    MetadataFeature,
    TagFeature,
    utf8_to_hex,
    Wallet
)

load_dotenv()

wallet = Wallet(os.environ['WALLET_DB_PATH'])

account = wallet.get_account('Alice')

# Sync account with the node
response = account.sync()

if 'STRONGHOLD_PASSWORD' not in os.environ:
    raise Exception(".env STRONGHOLD_PASSWORD is undefined, see .env.example")

wallet.set_stronghold_password(os.environ["STRONGHOLD_PASSWORD"])

client = Client()

hex_address = Utils.bech32_to_hex(
    'rms1qpllaj0pyveqfkwxmnngz2c488hfdtmfrj3wfkgxtk4gtyrax0jaxzt70zy')

address_unlock_condition = AddressUnlockCondition(
    Ed25519Address(hex_address)
)

# Output with metadata feature
nft_output = client.build_nft_output(
    nft_id='0x0000000000000000000000000000000000000000000000000000000000000000',
    unlock_conditions=[
        address_unlock_condition,
    ],
    features=[
        MetadataFeature(utf8_to_hex('Hello, World!'))
    ],
)
outputs = [nft_output]

# Output with immutable metadata feature
nft_output = client.build_nft_output(
    nft_id='0x0000000000000000000000000000000000000000000000000000000000000000',
    unlock_conditions=[
        address_unlock_condition,
    ],
    immutable_features=[
        MetadataFeature(utf8_to_hex('Hello, World!'))
    ],
)
outputs.append(nft_output)

# Output with tag feature
nft_output = client.build_nft_output(
    nft_id='0x0000000000000000000000000000000000000000000000000000000000000000',
    unlock_conditions=[
        address_unlock_condition
    ],
    features=[
        TagFeature(utf8_to_hex('Hello, World!'))
    ],
)
outputs.append(nft_output)

print(json.dumps([asdict(o) for o in outputs], indent=2))

transaction = account.send_outputs([outputs])

print(f'Transaction sent: {transaction.transactionId}')

block_id = account.retry_transaction_until_included(transaction.transactionId)

print(
    f'Block sent: {os.environ["EXPLORER_URL"]}/block/{block_id}')
