# Copyright 2023 IOTA Stiftung
# SPDX-License-Identifier: Apache-2.0

# This example shows how to listen to MQTT events of a node.

from codecs import utf_16_decode
import json
import os
import threading
import codecs

from dotenv import load_dotenv

from iota_sdk import Client

load_dotenv()

node_url = os.environ.get('NODE_URL', 'https://api.testnet.shimmer.network')

# Create a Client instance
client = Client(nodes=[node_url])

received_events = 0

received_10_events = threading.Event()


def callback(event):
    """Callback function for the MQTT listener"""
    event_dict = json.loads(event)
    testo = event_dict.split('data')
    #Filtering only from the data part on, of the json
    data_part = testo[2]
    #Trimming the string to obtain only the clean data hex
    cert_hex = data_part[7:].split('}')[0][:-2]
    #Decode of the hex certificate
    cert_utf = codecs.decode(cert_hex, "hex").decode("utf-8")
    print(cert_utf)
    # pylint: disable=global-statement
    global received_events
    received_events += 1
    if received_events > 10:
        received_10_events.set()


# Topics can be found here
# https://studio.asyncapi.com/?url=https://raw.githubusercontent.com/iotaledger/tips/main/tips/TIP-0028/event-api.yml
#0x636572746966696361746f is the hex form of "certificato" string, that is the tag from the sender_mqtt.py
client.listen_mqtt(["blocks/transaction/tagged-data/0x636572746966696361746f"], callback)

# Exit after 10 received events
received_10_events.wait()
client.clear_mqtt_listeners(["blocks"])
