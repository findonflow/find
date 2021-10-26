package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	g := gwtf.NewGoWithTheFlowInMemoryEmulator()
	//	g := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")

	//first step create the adminClient as the fin user
	g.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("find").
		RunPrintEventsFull()

	//link in the server in the versus client
	g.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAsService().
		AccountArgument("find").
		RunPrintEventsFull()

	//set up fin network as the fin user
	g.TransactionFromFile("setup_fin_3_create_network").
		SignProposeAndPayAs("find").
		RunPrintEventsFull()

	//we advance the clock
	g.TransactionFromFile("clock").SignProposeAndPayAs("find").UFix64Argument("1.0").RunPrintEventsFull()

	g.TransactionFromFile("create_profile").
		SignProposeAndPayAs("user1").
		StringArgument("User1").
		RunPrintEventsFull()

	g.TransactionFromFile("create_profile").
		SignProposeAndPayAs("user2").
		StringArgument("User2").
		RunPrintEventsFull()

	g.TransactionFromFile("mint_fusd").
		SignProposeAndPayAsService().
		AccountArgument("user1").
		UFix64Argument("100.0").
		RunPrintEventsFull()

	g.TransactionFromFile("register").
		SignProposeAndPayAs("user1").
		StringArgument("user1").
		UFix64Argument("5.0").
		RunPrintEventsFull()

	g.TransactionFromFile("mint_fusd").
		SignProposeAndPayAsService().
		AccountArgument("user2").
		UFix64Argument("30.0").
		RunPrintEventsFull()

	g.TransactionFromFile("send").
		SignProposeAndPayAs("user2").
		StringArgument("user1").
		UFix64Argument("13.37").
		RunPrintEventsFull()

	g.TransactionFromFile("renew").
		SignProposeAndPayAs("user1").
		StringArgument("user1").
		UFix64Argument("5.0").
		RunPrintEventsFull()

	g.TransactionFromFile("listForSale").SignProposeAndPayAs("user1").StringArgument("user1").UFix64Argument("10.0").RunPrintEventsFull()

	g.TransactionFromFile("bid").
		SignProposeAndPayAs("user2").
		StringArgument("user1").
		UFix64Argument("10.0").
		RunPrintEventsFull()

	/*
		g.ScriptFromFile("lease_status").AccountArgument("user1").Run()
		g.ScriptFromFile("lease_status").AccountArgument("user2").Run()
		g.ScriptFromFile("bid_status").AccountArgument("user2").Run()

		g.TransactionFromFile("clock").SignProposeAndPayAs("find").UFix64Argument("86500.0").RunPrintEventsFull()

		g.TransactionFromFile("fullfill").
		SignProposeAndPayAs("user1").
		StringArgument("user1").
		RunPrintEventsFull()

		g.ScriptFromFile("lease_status").AccountArgument("user1").Run()
		g.ScriptFromFile("bid_status").AccountArgument("user2").Run()
	*/

	g.ScriptFromFile("address_status").AccountArgument("user2").Run()
	g.TransactionFromFile("mint_artifact").SignProposeAndPayAsService().AccountArgument("user2").RunPrintEventsFull()

	g.ScriptFromFile("find-full").AccountArgument("user2").Run()
	g.ScriptFromFile("find-collection").AccountArgument("user2").Run()
	g.ScriptFromFile("find-ids-profile").AccountArgument("user2").StringArgument("artifacts").Run()
	g.ScriptFromFile("find-schemes").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(0).Run()
	g.ScriptFromFile("find").AccountArgument("user2").StringArgument("artifacts").UInt64Argument(0).StringArgument("A.f8d6e0586b0a20c7.TypedMetadata.CreativeWork").Run()

}
