package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
)

//NB! start from root dir with makefile
func main() {

	//GWTF has no future anymore?
	//flow := gwtf.NewGoWithTheFlow("./versus-flow.json")
	flow := gwtf.NewGoWithTheFlowEmulator()
	fmt.Println("Register a user and send him money")
	//create the versusAdminClientAndSomeOtherCollections
	flow.TransactionFromFile("register").
		SignProposeAndPayAs("user1").
		StringArgument("D").
		RunPrintEventsFull()

	flow.TransactionFromFile("send").
		SignProposeAndPayAs("user2").
		StringArgument("D").
		UFix64Argument("13.37").
		RunPrintEventsFull()
}
