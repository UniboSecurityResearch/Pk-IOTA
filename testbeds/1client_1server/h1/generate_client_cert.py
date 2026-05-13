#!/usr/bin/env python3
import asyncio
import socket
from pathlib import Path

from cryptography.x509.oid import ExtendedKeyUsageOID

from asyncua.crypto.cert_gen import setup_self_signed_certificate


async def main() -> None:
    cert_base = Path(__file__).parent
    cert = cert_base / "client-certificate.der"
    private_key = cert_base / "client-private-key.pem"

    host_name = socket.gethostname()
    client_app_uri = f"urn:{host_name}:Ulisse:UA_client"

    await setup_self_signed_certificate(
        private_key,
        cert,
        client_app_uri,
        host_name,
        [ExtendedKeyUsageOID.CLIENT_AUTH],
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
