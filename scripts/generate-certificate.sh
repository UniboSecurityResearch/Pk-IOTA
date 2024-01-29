#!/bin/bash

set -eu

if test $# -lt 3; then
	echo "Usage: $0 <outfile> <subject> <uri>" >&2
	echo "Example: $0 out '/C=IT/L=Bologna/O=Unibo/OU=Ulisse/CN=out' urn:$(hostname):Ulisse:GDS_client" >&2
	exit 1
fi

CERTIFICATENAME="$1"
SUBJECT="$2"
URI="$3"

generate_certificate() {
	CERTIFICATENAME="$1"
	SUBJECT="$2"
	URI="$3"
	openssl genrsa                         \
		-out "$CERTIFICATENAME.key"    \
		2048                  \
		;
	openssl req                                 \
		-new                                \
		-key "$CERTIFICATENAME.key"         \
		-subj "$SUBJECT"                    \
		-out "$CERTIFICATENAME.csr"         \
		;

	T="$(mktemp)"

	cat >"$T" <<-_END_
		basicConstraints = critical,CA:FALSE
		keyUsage = digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment,keyCertSign
		extendedKeyUsage = serverAuth,clientAuth
		subjectAltName = @alt_names
		[ alt_names ]
		URI = $URI
		DNS = $(echo "$URI" | cut -f 2 -d :)
	_END_

	openssl x509                            \
		-req                            \
		-extfile "$T"                   \
		-days 3650                      \
		-in "$CERTIFICATENAME.csr"      \
		-signkey "$CERTIFICATENAME.key" \
		-out "$CERTIFICATENAME.der"     \
		-outform der                    \
		;

	rm -rf "$T"
}

generate_certificate "$CERTIFICATENAME" "$SUBJECT" "$URI"
