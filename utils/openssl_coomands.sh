#!/bin/bash
# Transform to .txt from .der: 
openssl x509 -in out.der -inform der -out cert.txt --text 

# Transform to .pem from .der:
openssl x509 -in out.der -inform der -out cert.pem -outform pem

# Generate publickey.pem from privatekey.pem: 
openssl pkey -in jwtRS256.key -pubout > jwtRS256.key.pub

