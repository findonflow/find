#!/bin/bash
address=$(flow accounts create --network testnet --signer testnet-account --key e8f34988de164383f60cc15d0ad2d6eeca3bb34758f08e829c67566cbff84fcb1967097686b7217d01cd4ddaa2cea5f1daa0822709386df887b29993eeeb24ab -o json | jq '.address' -r)

yq -iP ".accounts.\"testnet-find\".address=\"$address\"" flow.json -o json

address=$(flow accounts create --network testnet --signer testnet-account --key e8f34988de164383f60cc15d0ad2d6eeca3bb34758f08e829c67566cbff84fcb1967097686b7217d01cd4ddaa2cea5f1daa0822709386df887b29993eeeb24ab -o json | jq '.address' -r)

yq -iP ".accounts.\"testnet-find-admin\".address=\"$address\"" flow.json -o json

address=$(flow accounts create --network testnet --signer testnet-account --key e8f34988de164383f60cc15d0ad2d6eeca3bb34758f08e829c67566cbff84fcb1967097686b7217d01cd4ddaa2cea5f1daa0822709386df887b29993eeeb24ab -o json | jq '.address' -r)

yq -iP ".accounts.\"testnet-user1\".address=\"$address\"" flow.json -o json

