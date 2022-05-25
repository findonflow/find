#!/bin/bash

flow transactions send transactions/transferAllFusd.cdc -n mainnet --signer mainnet-find-admin 0x936851d3e331acd4 
flow transactions send transactions/transferAllFusd.cdc -n mainnet --signer mainnet-find 0x936851d3e331acd4 
