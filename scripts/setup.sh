#!/usr/bin/env bash
# Compile the circuit and run a Groth16 setup (Powers of Tau + zkey + verification key).
# Compiled with --O0 so the constraint structure mirrors the source: the bug leaves the
# circuit with one constraint and `root` unconstrained; the fix adds the missing constraint.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -rf build && mkdir -p build

circom circuits/Square.circom --r1cs --wasm --sym --O0 -o build

snarkjs powersoftau new bn128 8 build/p0.ptau
snarkjs powersoftau contribute build/p0.ptau build/p1.ptau --name=dev -e="hermes-e1"
snarkjs powersoftau prepare phase2 build/p1.ptau build/pf.ptau

snarkjs groth16 setup build/Square.r1cs build/pf.ptau build/Square_0.zkey
snarkjs zkey contribute build/Square_0.zkey build/Square.zkey --name=dev2 -e="hermes-e2"
snarkjs zkey export verificationkey build/Square.zkey build/vkey.json

echo "SETUP DONE"
