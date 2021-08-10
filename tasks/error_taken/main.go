package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	flow := gwtf.NewGoWithTheFlowEmulator()
	fmt.Println("Register a user and send him money")
	flow.TransactionFromFile("register").
		SignProposeAndPayAs("user1").
		StringArgument("D").
		RunPrintEventsFull()

	flow.TransactionFromFile("register").
		SignProposeAndPayAs("user2").
		StringArgument("D").
		RunPrintEventsFull()

}
