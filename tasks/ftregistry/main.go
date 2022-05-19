package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	o := overflow.NewOverflowInMemoryEmulator().Start()
	/*
		o := overflow.NewOverflowMainnet().Start()
	*/

	//first step create the adminClient as the fin user
	o.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("find").
		RunPrintEventsFull()

	//link in the server in the versus client
	o.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAsService().
		Args(o.Arguments().Account("find")).
		RunPrintEventsFull()

	//Set up Fungible Token Registry
	o.TransactionFromFile("setFTInfo_flow").
		SignProposeAndPayAs("find").
		Args(o.Arguments()).
		RunPrintEventsFull()

	// get Info by Alias
	o.ScriptFromFile("getFTInfo").
		Args(o.Arguments().String("Flow")).
		Run()

	// get Info by TypeIdentifier
	o.ScriptFromFile("getFTInfo").
		Args(o.Arguments().String("A.0ae53cb6e3f42a79.FlowToken.Vault")).
		Run()

	// get All Info
	o.ScriptFromFile("getFTInfoAll").
		Args(o.Arguments()).
		Run()

	//Remove Fungible Token Registry By Alias
	o.TransactionFromFile("removeFTInfoByAlias").
		SignProposeAndPayAs("find").
		Args(o.Arguments().String("Flow")).
		RunPrintEventsFull()

	//Set up Fungible Token Registry Again (for testing out delete)
	o.TransactionFromFile("setFTInfo_flow").
		SignProposeAndPayAsService().
		Args(o.Arguments()).
		RunPrintEventsFull()

	//Remove Fungible Token Registry By Type Identifier
	o.TransactionFromFile("removeFTInfoByTypeIdentifier").
		SignProposeAndPayAsService().
		Args(o.Arguments().String("A.0ae53cb6e3f42a79.FlowToken.Vault")).
		RunPrintEventsFull()

}
