# [GG] based on simple_transaction.py from iota-sdk

from codecs import utf_16_decode
import json
import os
import threading
import codecs
import subprocess
import time

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization
from dotenv import load_dotenv

from iota_sdk import Client
from iota_sdk import Utils

#Da problemi con il load_dotenv; non carica un altro account
#subprocess.run(["python3","./sender/3_sender_mqtt_noinput.py"])
load_dotenv()

pkh_admin = "5548c2c7cb7b56bc71449646b221633ee0fa58dc14f835c71eedb87283dea121"
# hash of the public key of the admin
# from node rms1qzta3w8ahjd9zez0ncaekvcmkagqh4rsax794t6cr8xqhy9trwcjclxn6ef
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

tic = time.perf_counter()
client.listen_mqtt(["blocks/transaction/tagged-data/0x636572746966696361746f"], callback)

#with open("test2.txt", "a") as testfile:
#    trans_time = str(toc-tic) + '\n'
#    testfile.write(trans_time)

# Exit after 1 received events
received_1_events.wait()
toc = time.perf_counter()
print("[RECEIVER] Total time: " + str(toc-tic))
client.clear_mqtt_listeners(["blocks"])
