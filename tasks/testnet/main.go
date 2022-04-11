package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	//g := gwtf.NewGoWithTheFlowEmulator().InitializeContracts().CreateAccounts("emulator-account")
	o := overflow.NewOverflowTestnet().Start()

	/*
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
			SignProposeAndPayAs("find").RunPrintEventsFull()
	*/

	//link in the server in the versus client
	o.TransactionFromFile("setup_find_market_2").
		SignProposeAndPayAs("find-admin").
		Args(o.Arguments().Account("find")).
		RunPrintEventsFull()

	createProfileAndGiftName(o, "find")
	createProfileAndGiftName(o, "find-admin")

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
