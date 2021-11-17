package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	//g := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")
	g := gwtf.NewGoWithTheFlowDevNet()

	//first step create the adminClient as the fin user
	g.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("find-admin").
		RunPrintEventsFull()

	//link in the server in the versus client
	g.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAs("find").
		AccountArgument("find-admin").
		RunPrintEventsFull()

	//set up fin network as the fin user
	g.TransactionFromFile("setup_fin_3_create_network").
		SignProposeAndPayAs("find-admin").
		RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("find").
		StringArgument("find").
		RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("find-admin").
		StringArgument("find-admin").
		RunPrintEventsFull()

	/*
		//we advance the clock
		//	g.TransactionFromFile("clock").SignProposeAndPayAs("find").UFix64Argument("1.0").RunPrintEventsFull()

		tags := cadence.NewArray([]cadence.Value{cadence.String("find")})

		g.TransactionFromFile("createProfile").
			SignProposeAndPayAs("user1").
			StringArgument("User1").
			StringArgument("This is user1").
			Argument(tags).
			BooleanArgument(true).
			RunPrintEventsFull()

		g.TransactionFromFile("createProfile").
			SignProposeAndPayAs("user2").
			StringArgument("User2").
			StringArgument("This is user2").
			Argument(tags).
			BooleanArgument(true).
			RunPrintEventsFull()

		g.TransactionFromFile("mintFusd").
			SignProposeAndPayAsService().
			AccountArgument("user1").
			UFix64Argument("100.0").
			RunPrintEventsFull()

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			RunPrintEventsFull()

		g.TransactionFromFile("mintFusd").
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
			RunPrintEventsFull()

		g.TransactionFromFile("sell").SignProposeAndPayAs("user1").StringArgument("user1").UFix64Argument("10.0").RunPrintEventsFull()

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("10.0").
			RunPrintEventsFull()

		g.ScriptFromFile("lease_status").AccountArgument("user1").Run()
		g.ScriptFromFile("lease_status").AccountArgument("user2").Run()
		g.ScriptFromFile("bid_status").AccountArgument("user2").Run()

		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("86500.0").RunPrintEventsFull()

		g.TransactionFromFile("fulfill").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			RunPrintEventsFull()

		g.ScriptFromFile("lease_status").AccountArgument("user2").Run()
		g.ScriptFromFile("lease_status").AccountArgument("user1").Run()
		g.ScriptFromFile("bid_status").AccountArgument("user2").Run()

	*/
}
