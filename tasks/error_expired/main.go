package main

import (
	"fmt"
	"time"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func tickAndStatus(flow *gwtf.GoWithTheFlow) {
	time.Sleep(10 * time.Second)
	flow.TransactionFromFile("status").SignProposeAndPayAsService().StringArgument("D").Run()
}

func main() {

	flow := gwtf.NewGoWithTheFlowEmulator()
	flow.TransactionFromFile("register").
		SignProposeAndPayAs("user1").
		StringArgument("D").
		RunPrintEventsFull()

	for {
		fmt.Println("Tick and status")
		tickAndStatus(flow)
		fmt.Println("Press 'y' to try to reregister, any other key to wait longer")
		var char string
		fmt.Scanln(&char)
		if char == "y" {
			break
		}
	}

	flow.TransactionFromFile("reregister").SignProposeAndPayAs("user1").StringArgument("D").Run()

}
