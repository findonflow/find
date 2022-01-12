package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	g := gwtf.NewGoWithTheFlowInMemoryEmulator()
	//g := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")

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

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("user1").
		StringArgument("User1").
		RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("user2").
		StringArgument("User2").
		RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAsService().
		StringArgument("Find").
		RunPrintEventsFull()

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("find").
		StringArgument("Find").
		RunPrintEventsFull()

	g.TransactionFromFile("mintFusd").
		SignProposeAndPayAsService().
		AccountArgument("user1").
		UFix64Argument("100.0").
		RunPrintEventsFull()

	g.TransactionFromFile("register").
		SignProposeAndPayAs("user1").
		StringArgument("user1").
		UFix64Argument("5.0").
		RunPrintEventsFull()

	g.TransactionFromFile("mintFusd").
		SignProposeAndPayAsService().
		AccountArgument("user2").
		UFix64Argument("100.0").
		RunPrintEventsFull()

	g.TransactionFromFile("mintFlow").
		SignProposeAndPayAsService().
		AccountArgument("user2").
		UFix64Argument("100.0").
		RunPrintEventsFull()

	g.TransactionFromFile("buyAddon").SignProposeAndPayAs("user1").StringArgument("user1").StringArgument("forge").UFix64Argument("50.0").RunPrintEventsFull()

	g.TransactionFromFile("mintDandy").
		SignProposeAndPayAs("user1").
		StringArgument("user1").
		RunPrintEventsFull()

	id := uint64(74)
	g.ScriptFromFile("dandyViews").StringArgument("user1").UInt64Argument(id).Run()

	g.ScriptFromFile("dandy").StringArgument("user1").UInt64Argument(id).StringArgument("A.f8d6e0586b0a20c7.TypedMetadata.Display").Run()
	//g.ScriptFromFile("dandy").StringArgument("user1").UInt64Argument(71).StringArgument("AnyStruct{A.f8d6e0586b0a20c7.TypedMetadata.Royalty}").Run()

	g.TransactionFromFile("listDandyForSale").SignProposeAndPayAs("user1").UInt64Argument(id).UFix64Argument("10.0").RunPrintEventsFull()

	g.TransactionFromFile("bidMarket").SignProposeAndPayAs("user2").AccountArgument("user1").UInt64Argument(id).UFix64Argument("10.0").RunPrintEventsFull()

	g.TransactionFromFile("listDandyForAuction").SignProposeAndPayAs("user2").UInt64Argument(id).UFix64Argument("10.0").RunPrintEventsFull()

	g.TransactionFromFile("bidMarket").SignProposeAndPayAs("user1").AccountArgument("user2").UInt64Argument(id).UFix64Argument("15.0").RunPrintEventsFull()

	g.TransactionFromFile("clock").SignProposeAndPayAs("find").UFix64Argument("400.0").RunPrintEventsFull()

	g.TransactionFromFile("fulfillMarketAuction").SignProposeAndPayAs("user1").AccountArgument("user2").UInt64Argument(id).RunPrintEventsFull()
}
