package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/gwtf"
	"github.com/onflow/cadence"
)

func main() {

	flow := gwtf.NewGoWithTheFlowEmulator()
	fmt.Println("Register a user and send him money")
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
