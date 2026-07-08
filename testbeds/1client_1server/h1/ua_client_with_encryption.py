import asyncio
import logging
import sys
import socket
from pathlib import Path
from cryptography.x509.oid import ExtendedKeyUsageOID
from asyncua import Client
from asyncua.crypto.security_policies import SecurityPolicyBasic256Sha256
from asyncua.crypto.cert_gen import setup_self_signed_certificate
from asyncua.crypto.validator import CertificateValidator, CertificateValidatorOptions
from asyncua.crypto.truststore import TrustStore


logging.basicConfig(level=logging.INFO)
_logger = logging.getLogger(__name__)

USE_TRUST_STORE = True

SERVER_NAMESPACE_URI = "http://example.org/server"
TRUSTED_CERTS_DIR = Path("/certificates/trusted/certs")

cert_base = Path(__file__).parent
cert = Path(cert_base / "client-certificate.der")
private_key = Path(cert_base / "client-private-key.pem")


async def task():
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
    client = Client(url=url)
    client.application_uri = client_app_uri
    await client.set_security(
        SecurityPolicyBasic256Sha256,
        certificate=str(cert),
        private_key=str(private_key),
        server_certificate=str(TRUSTED_CERTS_DIR / "server-certificate.der")
    )

    if USE_TRUST_STORE:
        trust_store = TrustStore([TRUSTED_CERTS_DIR], [])
        await trust_store.load()
        validator = CertificateValidator(CertificateValidatorOptions.BASIC_VALIDATION | CertificateValidatorOptions.PEER_SERVER, trust_store)
    else:
        validator = CertificateValidator(CertificateValidatorOptions.BASIC_VALIDATION | CertificateValidatorOptions.PEER_SERVER)
    client.certificate_validator = validator

    async with client:
        # MyObject/MyVariable live in the namespace the server registers at
        # startup, never in namespace 0: resolve the index instead of assuming it.
        nsidx = await client.get_namespace_index(SERVER_NAMESPACE_URI)
        child = await client.nodes.objects.get_child([f'{nsidx}:MyObject', f'{nsidx}:MyVariable'])
        initial = await child.get_value()
        await child.set_value(42.0)
        readback = await child.get_value()
        if readback != 42.0:
            raise RuntimeError(f"readback mismatch: wrote 42.0, got {readback!r}")
        print(f"SESSION_OK initial={initial} readback={readback}")


def main():
    try:
        asyncio.run(task())
    except Exception as exp:
        # Fail loudly: the campaign runner counts sessions by exit code.
        _logger.error("session failed: %s", exp)
        sys.exit(1)


if __name__ == "__main__":
    main()
