import asyncio
import sys
import socket
from pathlib import Path
from cryptography.x509.oid import ExtendedKeyUsageOID
sys.path.insert(0, "..")
from asyncua import Client
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua.crypto.cert_gen import setup_self_signed_certificate
from asyncua.crypto.validator import CertificateValidator, CertificateValidatorOptions
from asyncua.crypto.truststore import TrustStore
from asyncua import ua
import time

USE_TRUST_STORE = True

cert_base = Path(__file__).parent
cert = Path(cert_base / f"client-certificate.der")
private_key = Path(cert_base / f"client-private-key.pem")

async def task(loop):
    host_name = socket.gethostname()
    client_app_uri = f"urn:{host_name}:Ulisse:UA_client"
    url = "opc.tcp://10.0.0.2:4840/freeopcua/server/"

    await setup_self_signed_certificate(private_key,
                                        cert,
                                        client_app_uri,
                                        host_name,
                                        [ExtendedKeyUsageOID.CLIENT_AUTH],
                                        {
                                            'countryName': 'IT',
                                            'stateOrProvinceName': 'IT',
                                            'localityName': 'Bologna',
                                            'organizationName': "UniBo",
                                        })
    client = Client(url=url, timeout=10)
    client.application_uri = client_app_uri
    await client.set_security(
        SecurityPolicyBasic256Sha256,
        certificate=str(cert),
        private_key=str(private_key),
        server_certificate="./certificates/trusted/certs/server-certificate.der"
    )

    if USE_TRUST_STORE:
        trust_store = TrustStore([Path('') / 'certificates' / 'trusted' / 'certs'], [])
        await trust_store.load()
        print(trust_store.trust_locations)
        validator =CertificateValidator(CertificateValidatorOptions.BASIC_VALIDATION|CertificateValidatorOptions.PEER_SERVER, trust_store)
    else:
        validator =CertificateValidator(CertificateValidatorOptions.BASIC_VALIDATION|CertificateValidatorOptions.PEER_SERVER)
    client.certificate_validator = validator

    # Open file to save results
    file_path = "./results_conn.txt"
    with open(file_path, 'w') as file:
        for i in range(1000):
            timestamp = time.time()
            await client.connect()
            timestamp = time.time() - timestamp
            file.write(str(timestamp) + "\n")
            print(i, timestamp)
            await client.disconnect()

def main():
    loop = asyncio.get_event_loop()
    loop.set_debug(True)
    loop.run_until_complete(task(loop))
    loop.close()


if __name__ == "__main__":
    main()