package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	// o := overflow.NewOverflowTestnet().Start()

	// user := "0x49d14b03d7411f53"

	// o.ScriptFromFile("getCollections").Args(o.Arguments().String(user)).Run()
	//user := "0xfbd6c52b7e6fe7be"

	// o.SimpleTxArgs("adminSendFlow", "account", o.Arguments().RawAccount(user).UFix64(10.0))

	// o.TransactionFromFile("testMintDandyTO").
	// 	SignProposeAndPayAs("user1").
	// 	Args(o.Arguments().
	// 		String("user1").
	// 		UInt64(10).
	// 		String("Neo").
	// 		String("Neo Motorcycle").
	// 		String(`Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK`).
	// 		String("https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp").
	// 		String("rare").
	// 		UFix64(50.0).
	// 		RawAddress(user)).
	// 	RunPrintEventsFull()
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

	// New Overflow

	number := 10
	price := 1.0
	nftIdentifier := "Dandy"
	ftIdentifier := "Flow"
	seller := "user1"

	o := Overflow(
		WithNetwork("testnet"),
		StopOnError(),
		PrintInteractionResults(),
	)

	// o.Tx("adminSendFlow",
	// 	SignProposeAndPayAs("account"),
	// 	Arg("receiver", "user2"),
	// 	Arg("amount", 50.0),
	// )

	o.Tx("createprofile",
		SignProposeAndPayAs("user2"),
		Arg("name", "user2"),
	)

	ids := o.Tx("testMintDandyTO",
		SignProposeAndPayAs("user1"),
		Arg("name", "user1"),
		Arg("maxEdition", 3),
		Arg("artist", "Neo"),
		Arg("nftName", "Neo Motorcycle"),
		Arg("nftDescription", `Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK`),
		Arg("nftUrl", "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"),
		Arg("rarity", "rare"),
		Arg("rarityNum", 50.0),
		Arg("to", "user2"),
	).
		GetIdsFromEvent("Sale", "id")

	saleIds := ids[:number]

	var prices []float64
	var nftIdentifiers []string
	var ftIdentifiers []string
	var sellers []string
	for len(prices) < number {
		prices = append(prices, price)
		nftIdentifiers = append(nftIdentifiers, nftIdentifier)
		ftIdentifiers = append(ftIdentifiers, ftIdentifier)
		sellers = append(sellers, seller)
	}

	o.Tx("listMultipleNFTForSale",
		SignProposeAndPayAs("user1"),
		Arg("marketplace", "find"),
		Arg("nftAliasOrIdentifiers", nftIdentifiers),
		Arg("ids", saleIds),
		Arg("ftAliasOrIdentifiers", ftIdentifiers),
		Arg("directSellPrices", prices),
		Arg("validUntil", nil))

	o.Tx("buyMultipleNFTForSale",
		SignProposeAndPayAs("user1"),
		Arg("marketplace", "find"),
		Addresses("users", sellers...),
		Arg("ids", saleIds),
		Arg("amounts", prices))

}
