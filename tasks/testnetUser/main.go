package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	o := overflow.NewOverflowTestnet().Start()

	o.SimpleTxArgs("adminSellDandy", "find", o.Arguments())
	user := "0x745fbb422764513b"

	o.SimpleTxArgs("adminSendFlow", "account", o.Arguments().RawAccount(user).UFix64(1000.0))

	o.TransactionFromFile("mintDandyTO").
		SignProposeAndPayAs("user1").
		Args(o.Arguments().
			String("user1").
			UInt64(5).
			String("Neo").
			String("Neo Motorcycle").
			String(`Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK`).
			String("https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp").
			String("rare").
			UFix64(50.0).
			RawAddress(user)).
		RunPrintEventsFull()
}
