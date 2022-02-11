package main

import "github.com/bjartek/overflow/overflow"

func main() {

	o := overflow.NewOverflowMainnet().Start()

	name := "im-ed"
	account := "0x58314b7e8ceac610"
	o.TransactionFromFile("registerAdmin").
		SignProposeAndPayAs("find-admin").
		Args(o.Arguments().StringArray(name).RawAccount(account)).
		RunPrintEventsFull()

}
