package main

import (
	"github.com/bjartek/overflow/overflow"
)

func main() {

	o := overflow.NewOverflowTestnet().Start()

	user := "0xfbd6c52b7e6fe7be"

	o.SimpleTxArgs("testSendFlow", "account", o.Arguments().RawAccount(user).UFix64(1000.0))

	o.TransactionFromFile("testMintDandyTO").
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

	/*
		// transaction(nftAlias: String, id: UInt64, ftAlias: String, directSellPrice:UFix64) {

					o.SimpleTxArgs("listNFTForSale", "user1", o.Arguments().
						String("Dandy").
						UInt64(id).
						String("Flow").
						UFix64(10.0))

			var id uint64 = 93123574
			var amount float64 = 12.0

			o.SimpleTxArgs("buyItemForSale", "user1", o.Arguments().RawAddress("0xec63ca35a454a495").UInt64(id).UFix64(amount))
	*/

	//	o.ScriptFromFile("address_status").Args(o.Arguments().RawAddress("0xec63ca35a454a495")).Run()
	//	o.ScriptFromFile("resolveListingByAddress").Args(o.Arguments().RawAddress("0xec63ca35a454a495").UInt64(93123574)).Run()

}

//transaction(name: String, maxEdition:UInt64, artist:String, nftName:String, nftDescription:String, nftUrl:String, rarity: String, rarityNum:UFix64, to: Address) {
