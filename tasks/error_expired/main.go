package main

import (
	"time"

	"github.com/bjartek/go-with-the-flow/gwtf"
)

func tickAndStatus(flow *gwtf.GoWithTheFlow) {
	flow.TransactionFromFile("status").SignProposeAndPayAsService().StringArgument("D").Run()
	time.Sleep(10 * time.Second)
}

func main() {

	flow := gwtf.NewGoWithTheFlowEmulator()
	flow.TransactionFromFile("register").
		SignProposeAndPayAs("user1").
		StringArgument("D").
		RunPrintEventsFull()

	for {
		tickAndStatus(flow)
	}

}
