#!/bin/bash -e

SAVE_TO="artifacts/"
INPUT="input.json"
WITNESS="witness"
FILE="main"

circom --r1cs --wasm -o $SAVE_TO "${FILE}.circom"

node "${SAVE_TO}${FILE}_js/generate_witness.js" "${SAVE_TO}${FILE}_js/${FILE}.wasm" $INPUT "${SAVE_TO}${WITNESS}.wtns"

snarkjs wtns export json "${SAVE_TO}${WITNESS}.wtns" "${WITNESS}.json"

