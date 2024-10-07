Giacomo Gori - scripts to send and receive certificates, mqtt (i.e., with iota tangle)

Instructions:

1. Install all the python packages of requirements-dev.txt with pip install -r requirements-dev.txt


2. Invoke scripts in order to send and receive a transaction with the certificate in the payload and a tag that is "certificato". Invoke the scripts following the orders of the first number in the names.

3. You can use cert.txt, cert.der, cert.pem to send different types of certificates. A .env file on the directory represents the data for the creation of the account for script 1; remember to change the nodes if you are using personalized IOTA nodes.

Site for all events of the IOTA tangle: https://studio.asyncapi.com/?url=https://raw.githubusercontent.com/iotaledger/tips/main/tips/TIP-0028/event-api.yml#operation-subscribe-blocks/tagged-data/{tag}

Site for iota-SDK documentation: https://docs.rs/iota-sdk/latest/iota_sdk/index.html
