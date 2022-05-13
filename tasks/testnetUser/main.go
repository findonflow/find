package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	o := overflow.NewOverflowTestnet().Start()

	//o.SimpleTxArgs("adminSellNeoTestnet", "find", o.Arguments())
	o.SimpleTxArgs("setNFTInfo_neo", "find-admin", o.Arguments())
	//o.ScriptFromFile("address_status").Args(o.Arguments().RawAccount("0x745fbb422764513b")).Run()
	//o.ScriptFromFile("address_status").Args(o.Arguments().RawAccount("0xb26a2c441eda9091")).Run()
	/*

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
				RawAddress(user)).
			RunPrintEventsFull()
	*/
}
