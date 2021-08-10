package main

import (
	"fmt"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
)

func main() {

	flow := gwtf.NewGoWithTheFlowEmulator()
	fmt.Println("Demo of FIN")
	flow.CreateAccount("fin", "user1", "user2")

	//create the finAdminClientAndSomeOtherCollections
	flow.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("fin").
		RunPrintEventsFull()

	//link in the server in the versus client
	flow.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAsService().
		AccountArgument("fin").
		RunPrintEventsFull()

	//set up fin
	flow.TransactionFromFile("setup_fin_3_create_network").
		SignProposeAndPayAs("fin").
		UFix64Argument("60.0"). //duration of a lease, this is for testing
		UFix64Argument("0.1").  //base cost
		UInt64Argument(6).
		RunPrintEventsFull()

	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("user1").UFix64Argument("100.0").RunPrintEventsFull()
	flow.TransactionFromFile("mint_tokens").SignProposeAndPayAsService().AccountArgument("user2").UFix64Argument("100.0").RunPrintEventsFull()

}
