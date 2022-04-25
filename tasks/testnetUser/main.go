package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	o := overflow.NewOverflowTestnet().Start()

	/*
			o.TransactionFromFile("createProfile").
				SignProposeAndPayAsService().
				Args(o.Arguments().String("find")).
				RunPrintEventsFull()

		o.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			Args(o.Arguments().String("user1").UFix64(5.0)).
			RunPrintEventsFull()


	*/

	o.TransactionFromFile("buyAddon").SignProposeAndPayAs("user1").
		Args(o.Arguments().String("user1").String("forge").UFix64(50.0)).
		RunPrintEventsFull()

	o.TransactionFromFile("mintDandy").
		SignProposeAndPayAs("user1").
		Args(o.Arguments().
			String("user1").
			UInt64(3).
			String("Neo").
			String("Neo Motorcycle").
			String(`Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK`).
			String("https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp")).
		RunPrintEventsFull()
}
