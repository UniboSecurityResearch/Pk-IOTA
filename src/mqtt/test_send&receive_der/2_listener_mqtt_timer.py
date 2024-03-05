# [GG] based on simple_transaction.py from iota-sdk

from codecs import utf_16_decode
import json
import os
import threading
import codecs
import sys
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

# Check parameters
if len(sys.argv) > 1:
    # Read path of the certificate received as parameter
    index = sys.argv[1]
else:
    print("[ERROR] Please insert the index of the iteration (FOR TEST)")
    exit()

with open("test_der_listener.txt", "a") as testfile:
		testfile.write(index + ' - ')

received_1_events = threading.Event()
pkh_admin = "97d8b8fdbc9a51644f9e3b9b331bb7500bd470e9bc5aaf5819cc0b90ab1bb12c"
# hash of the public key of the admin
# from node rms1qzta3w8ahjd9zez0ncaekvcmkagqh4rsax794t6cr8xqhy9trwcjclxn6ef
# that is Giacomo, sender launched from Pk-IOTA/src/mqtt/test_2/sender

node_url = os.environ.get('NODE_URL', 'https://api.testnet.shimmer.network')

# Create a Client instance
client = Client(nodes=[node_url])
utils = Utils()


def callback(event):
	"""Callback function for the MQTT listener"""
	received_time = time.time()
	with open("test2_listener.txt", "a") as testfile:
		testfile.write(str(received_time)+' - ')
	event_dict = json.loads(event)
	text_splitted = event_dict.split('data')
	#bech32_res = utils.hex_public_key_to_bech32_address("0xe364c1734abe4d60507c03a6f34be01fd1a5530680aae95f7ca573afeb300567","rms")
	
	#Taking only the header part
	header_splitted = text_splitted[1].split('pubKeyHash')
	#Trimming the string to obtain only the clean hash of the public key of the sender
	pkh_received = header_splitted[2][7:].split('}')[0][:-2]
	
	#Checking if the sender is admin
	if pkh_received == pkh_admin:
		#Filtering only from the data part on, of the json
		data_part = text_splitted[2]
		#Trimming the string to obtain only the clean data hex
		cert_hex = data_part[7:].split('}')[0][:-2]
		#Decode of the hex certificate
		cert_utf = codecs.decode(cert_hex, "hex")
		decoded_time = time.time()
		with open("test2_listener.txt", "a") as testfile:
			testfile.write(str(decoded_time)+'\n')
		print('-----------------------------')
		print(f'[RECEIVER] Time for the decode: {decoded_time-received_time:0.8f} seconds')
		print('-----------------------------')
		global received_events
		received_1_events.set()

	else:
		print('[DEBUG]: Certificate not from Admin')

client.listen_mqtt(["blocks/transaction/tagged-data/0x636572746966696361746f"], callback)
received_1_events.wait()
client.clear_mqtt_listeners(["blocks"])

