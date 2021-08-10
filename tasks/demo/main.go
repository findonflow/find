package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
)

func main() {

	g := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")

	//first step create the adminClient as the fin user
	g.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("fin").
		RunPrintEventsFull()

		//link in the server in the versus client
	g.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAsService().
		AccountArgument("fin").
		RunPrintEventsFull()

		//set up fin network as the fin user
	g.TransactionFromFile("setup_fin_3_create_network").
		SignProposeAndPayAs("fin").
		UFix64Argument("60.0"). //duration of a lease, this is for testing
		RunPrintEventsFull()

	tags := cadence.NewArray([]cadence.Value{cadence.String("tag1"), cadence.String("tag2")})

	g.TransactionFromFile("create_profile").
		SignProposeAndPayAs("user1").
		StringArgument("User1").
		StringArgument("This is user1").
		Argument(tags).
		BooleanArgument(true).
		RunPrintEventsFull()

	g.TransactionFromFile("create_profile").
		SignProposeAndPayAs("user2").
		StringArgument("User2").
		StringArgument("This is user2").
		Argument(tags).
		BooleanArgument(true).
		RunPrintEventsFull()

	g.TransactionFromFile("mint_fusd").
		SignProposeAndPayAsService().
		AccountArgument("user1").
		UFix64Argument("100.0").
		RunPrintEventsFull()

	g.TransactionFromFile("register").
		SignProposeAndPayAs("user1").
		StringArgument("user1").
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
		RunPrintEventsFull()

	g.TransactionFromFile("sell").SignProposeAndPayAs("user1").StringArgument("user1").UFix64Argument("10.0").RunPrintEventsFull()
	g.TransactionFromFile("buy").SignProposeAndPayAs("user2").AccountArgument("user1").StringArgument("user1").UFix64Argument("10.0").RunPrintEventsFull()

}
