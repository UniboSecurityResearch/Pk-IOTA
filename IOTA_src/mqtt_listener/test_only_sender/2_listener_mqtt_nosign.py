# [GG] based on simple_transaction.py from iota-sdk

from codecs import utf_16_decode
import json
import os
import threading
import codecs

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization
from dotenv import load_dotenv

from iota_sdk import Client
from iota_sdk import Utils

load_dotenv()

pkh_admin = "194eb32b9b6c61207192c7073562a0b3adf50a7c1f268182b552ec8999380acb"
# hash of the public key of the admin
# from node rms1qqv5avetndkxzgr3jtrswdtz5ze6mag20s0jdqvzk4fwezve8q9vkpnqlqe
# that is Alice, sender launched from Pk-IOTA/src/mqtt

node_url = os.environ.get('NODE_URL', 'https://api.testnet.shimmer.network')

# Create a Client instance
client = Client(nodes=[node_url])
utils = Utils()

received_1_events = threading.Event()


def callback(event):
	"""Callback function for the MQTT listener"""
	event_dict = json.loads(event)
	text_splitted = event_dict.split('data')
	#bech32_res = utils.hex_public_key_to_bech32_address("0xe364c1734abe4d60507c03a6f34be01fd1a5530680aae95f7ca573afeb300567","rms")
	
	#Taking only the header part
	header_splitted = text_splitted[1].split('pubKeyHash')
	#Trimming the string to obtain only the clean hash of the public key of the sender
	pkh_received = header_splitted[2][7:].split('}')[0][:-2]
	print(pkh_received)
	
	#Checking if the sender is admin
	if pkh_received == pkh_admin:
		#Filtering only from the data part on, of the json
		data_part = text_splitted[2]
		#Trimming the string to obtain only the clean data hex
		cert_hex = data_part[7:].split('}')[0][:-2]
		#Decode of the hex certificate
		cert_utf = codecs.decode(cert_hex, "hex")
		print(cert_utf)

		global received_events
		received_1_events.set()
	else:
		print('[DEBUG]: Certificate not from Admin')


# Topics can be found here
# https://studio.asyncapi.com/?url=https://raw.githubusercontent.com/iotaledger/tips/main/tips/TIP-0028/event-api.yml
#0x636572746966696361746f is the hex form of "certificato" string, that is the tag from the sender_mqtt.py
client.listen_mqtt(["blocks/transaction/tagged-data/0x636572746966696361746f"], callback)

# Exit after 1 received events
received_1_events.wait()
client.clear_mqtt_listeners(["blocks"])
