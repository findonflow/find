package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	//g := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")
	o := overflow.NewOverflowTestnet().Start()

	o.SimpleTxArgs("adminSendFlow", "account", o.Arguments().Account("find").UFix64(1.0))

	//Deploy contracts to testnet
	o.InitializeContracts()

	//send flow to admin and user account
	o.SimpleTxArgs("adminSendFlow", "account", o.Arguments().Account("find-admin").UFix64(1000.0))
	o.SimpleTxArgs("adminSendFlow", "account", o.Arguments().Account("user1").UFix64(1000.0))

	//first step create the adminClient as the fin user
	o.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("find-admin").
		RunPrintEventsFull()

	//link in the server in the versus client
	o.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAs("find").
		Args(o.Arguments().Account("find-admin")).
		RunPrintEventsFull()

	//set up fin network as the fin user
	o.TransactionFromFile("setup_fin_3_create_network").
		SignProposeAndPayAs("find-admin").
		RunPrintEventsFull()

	o.TransactionFromFile("setup_find_market_1").
		SignProposeAndPayAs("find").
		RunPrintEventsFull()

	//link in the server in the versus client
	o.TransactionFromFile("setup_find_market_2").
		SignProposeAndPayAs("find-admin").
		Args(o.Arguments().Account("find")).
		RunPrintEventsFull()

	o.SimpleTxArgs("adminSetupMarketOptionsTypes", "find-admin", o.Arguments())
	o.SimpleTxArgs("adminSetFTInfo_flow", "find-admin", o.Arguments())
	o.SimpleTxArgs("adminSetFTInfo_usdc", "find-admin", o.Arguments())
	o.SimpleTxArgs("adminSetFTInfo_fusd", "find-admin", o.Arguments())

	o.SimpleTxArgs("adminSetNFTInfo_Dandy", "find-admin", o.Arguments())
	o.SimpleTxArgs("adminSellNeoTestnet", "find", o.Arguments())

	o.SimpleTxArgs("adminSetNFTInfo_Neo", "find-admin", o.Arguments())
	o.SimpleTxArgs("testSetSellNeoTestnetRules", "find", o.Arguments())

	o.SimpleTxArgs("adminAddBl0xTestnet", "find-admin", o.Arguments())

	createProfileAndGiftName(o, "find")
	createProfileAndGiftName(o, "find-admin")
	createProfileAndGiftName(o, "user1")

	o.SimpleTxArgs("adminSendFUSD", "account", o.Arguments().Account("user1").UFix64(100.0))

	o.TransactionFromFile("buyAddon").SignProposeAndPayAs("user1").
		Args(o.Arguments().String("user1").String("forge").UFix64(50.0)).
		RunPrintEventsFull()

}

func createProfileAndGiftName(o *overflow.Overflow, name string) {
	o.TransactionFromFile("createProfile").
		SignProposeAndPayAs(name).
		Args(o.Arguments().String(name)).
		RunPrintEventsFull()

	o.TransactionFromFile("registerAdmin").
		SignProposeAndPayAs("find-admin").
		Args(o.Arguments().StringArray(name).Account(name)).
		RunPrintEventsFull()

}
