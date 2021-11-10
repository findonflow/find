package main

import (
	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	g := gwtf.NewGoWithTheFlowDevNet()

	/*
		g.TransactionFromFile("register").
			SignProposeAndPayAs("find").
			StringArgument("find").
			UFix64Argument("100.0").
			RunPrintEventsFull()

		g.TransactionFromFile("buyAddon").SignProposeAndPayAs("find").StringArgument("find").StringArgument("artifact").UFix64Argument("50.0").RunPrintEventsFull()

		g.TransactionFromFile("mintArtifact").SignProposeAndPayAs("find").StringArgument("find").RunPrintEventsFull()
	*/

	g.TransactionFromFile("mintArt").
		SignProposeAndPayAs("find-admin").
		AccountArgument("find-admin").
		StringArgument("Kinger9999").
		StringArgument("Bull").
		StringArgument("Teh crypto bull").
		AccountArgument("find").
		StringArgument("image/jpeg").
		UFix64Argument("0.05").
		UFix64Argument("0.025").
		StringArgument("http://bull-address-here").
		RunPrintEventsFull()

	g.ScriptFromFile("find-list").AccountArgument("find").Run()

}
