package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
)

func main() {

	//g := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")
	//	g := gwtf.NewGoWithTheFlowMainNet()
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

		/*
			//set up fin network as the fin user
			g.TransactionFromFile("setup_fin_3_create_network").
				SignProposeAndPayAs("find-admin").
				RunPrintEventsFull()
		*/

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("find").
		StringArgument("find").
		RunPrintEventsFull()

	findLinks := cadence.NewArray([]cadence.Value{
		cadence.NewDictionary([]cadence.KeyValuePair{
			{Key: cadence.NewString("title"), Value: cadence.NewString("twitter")},
			{Key: cadence.NewString("type"), Value: cadence.NewString("twitter")},
			{Key: cadence.NewString("url"), Value: cadence.NewString("https://twitter.com/findonflow")},
		})})

	g.TransactionFromFile("createProfile").
		SignProposeAndPayAs("find-admin").
		StringArgument("ReservedNames").
		RunPrintEventsFull()

	g.TransactionFromFile("editProfile").
		SignProposeAndPayAs("find-admin").
		StringArgument("ReservedFindNames").
		StringArgument(`The names owned by this profile are reservd by find. In order to aquire a name here you have to:

Prices:
 - 3 letter name  500 FUSD
 - 4 letter name  100 FUSD
 - 5+ letter name   5 FUSD

1. make an offer for that name with the correct price (see above) 
2. go into the find discord and let the mods know you have made the bid

`).
		StringArgument("https://find.xyz/find.png").
		StringArrayArgument("find").
		BooleanArgument(false).
		Argument(findLinks).
		RunPrintEventsFull()

	g.TransactionFromFile("editProfile").
		SignProposeAndPayAs("find").
		StringArgument("find").
		StringArgument(`.find will allow you to find people and NFTS on flow!`).
		StringArgument("https://find.xyz/find.png").
		StringArrayArgument("find").
		BooleanArgument(true).
		Argument(findLinks).
		RunPrintEventsFull()

	g.TransactionFromFile("registerAdmin").
		SignProposeAndPayAs("find-admin").
		StringArrayArgument("find").
		AccountArgument("find").
		RunPrintEventsFull()

	g.TransactionFromFile("registerAdmin").
		SignProposeAndPayAs("find-admin").
		StringArrayArgument("reserved-names").
		AccountArgument("find-admin").
		RunPrintEventsFull()

}
