#!/bin/bash

# this file needs an service account for testnet that can create accounts
keys=$(flow keys generate -o json)

publicKey=$(echo $keys | jq ".public" -r)
privateKey=$(echo $keys | jq ".private" -r)

account=$(flow accounts create --network testnet --signer testnet-account --key $publicKey -o json)


address=$(echo $account | jq ".address" -r)


cat << EOF
{
  "address": "$address",
  "key": "$privateKey",
}
EOF
