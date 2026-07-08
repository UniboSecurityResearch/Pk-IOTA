#!/usr/bin/env python3
"""Generate the server certificate without starting the OPC UA server.

Lets the campaign runner produce and exchange both certificates before the
server process starts, so CertificateUserManager sees the client certificate
on its one-shot load at startup.
"""
import asyncio
import socket
from pathlib import Path

from cryptography.x509.oid import ExtendedKeyUsageOID

from asyncua.crypto.cert_gen import setup_self_signed_certificate


async def main() -> None:
    cert_base = Path(__file__).parent
    cert = cert_base / "server-certificate.der"
    private_key = cert_base / "server-private-key.pem"

    host_name = socket.gethostname()
    server_app_uri = f"urn:{host_name}:Ulisse:UA_server"

    await setup_self_signed_certificate(
        private_key,
        cert,
        server_app_uri,
        host_name,
        [ExtendedKeyUsageOID.CLIENT_AUTH, ExtendedKeyUsageOID.SERVER_AUTH],
        {
            "countryName": "IT",
            "stateOrProvinceName": "IT",
            "localityName": "Bologna",
            "organizationName": "UniBo",
        },
    )

    print(f"generated={cert}")
    print(f"size_bytes={cert.stat().st_size}")


if __name__ == "__main__":
    asyncio.run(main())
