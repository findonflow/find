package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	g := gwtf.NewGoWithTheFlowDevNet()

	g.TransactionFromFile("register").
		SignProposeAndPayAs("find-admin").
		StringArgument("find-admin").
		UFix64Argument("5.0").
		RunPrintEventsFull()

	g.TransactionFromFile("mintArtifact").SignProposeAndPayAs("find-admin").AccountArgument("find").RunPrintEventsFull()

}
