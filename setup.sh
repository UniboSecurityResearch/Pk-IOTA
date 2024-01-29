#!/bin/bash

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Clone the Stronghold repo:
git clone https://github.com/iotaledger/stronghold.rs.git

# Build the Stronghold CLI library
cd stronghold.rs
cargo build --release

# Add line resolver = 2 to Cargo.toml file under workspace section
while read line; do
    printf "%s\n" "$line"
    if [[ $line == *"]"* ]] && [[ $prev_line == *'"stm"'* ]]; then 
        printf "%s\n" "resolver = \"2\""   
    fi
    prev_line=$line
done < Cargo.toml > Cargo.toml.tmp
mv Cargo.toml.tmp Cargo.toml

# Generate an Ed25519 key pair and print the public key on console
cargo run --example cli generate-key --key-type Ed25519 --vault-path "vault_path" --record-path "record_path"
