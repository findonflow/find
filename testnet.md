# Deploy to new testnet account
 - create new addresses using the TESTNET_ACCOUNT PK
 - replace addreses in flow.json
 - `flow transactions send transactions/adminSendFlow.cdc -n testnet --signer testnet-account 0x2781fb99eb727ca2 1000.0`
 - `flow project deploy -n testnet`
 - `go run tasks/testnet/main.go`
 
