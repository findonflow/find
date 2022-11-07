package main

import (
	"fmt"
	"strconv"

	. "github.com/bjartek/overflow"
)

func main() {

	// o := overflow.NewOverflowTestnet().Start()

	// user := "0x49d14b03d7411f53"

	// o.ScriptFromFile("getCollections").Args(o.Arguments().String(user)).Run()
	//user := "0xfbd6c52b7e6fe7be"

	// o.SimpleTxArgs("adminSendFlow", "account", o.Arguments().RawAccount(user).UFix64(10.0))

	// o.TransactionFromFile("devMintDandyTO").
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
	priceString := fmt.Sprintf("%.1f", price)
	nftIdentifier := `"Dandy"`
	ftIdentifier := `"Flow"`
	seller := "user1"

	o := Overflow(
		WithNetwork("testnet"),
		WithGlobalPrintOptions(),
	)

	// o.Tx("adminSendFlow",
	// 	SignProposeAndPayAs("account"),
	// 	Arg("receiver", "user2"),
	// 	Arg("amount", 10.0),
	// )

	// o.Tx("createprofile",
	// 	SignProposeAndPayAs("user2"),
	// 	Arg("name", "user2"),
	// )

	ids := o.Tx("devMintDandyTO",
		WithSigner("user1"),
		WithArg("name", "user1"),
		WithArg("maxEdition", 12),
		WithArg("artist", "Neo"),
		WithArg("nftName", "Neo Motorcycle"),
		WithArg("nftDescription", `Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK`),
		WithArg("nftUrl", "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"),
		WithArg("rarity", "rare"),
		WithArg("rarityNum", 50.0),
		WithArg("to", "user1"),
	).
		GetIdsFromEvent("Deposit", "id")

	// ids := []uint64{
	// 	100293819,
	// 	100293820,
	// 	100293821,
	// 	100293822,
	// 	100293823,
	// 	100293824,
	// 	100293825,
	// 	100293826,
	// 	100293827,
	// 	100293828,
	// }

	saleIds := fmt.Sprint(`[ `, ids[0])

	prices := `[ ` + priceString
	var nftIdentifiers string = `[ "Dandy" `
	var ftIdentifiers string = ` [ "Flow" `

	sellers := make([]string, 1)
	sellers[0] = seller
	i := 1
	for i < number {
		id := fmt.Sprint(ids[i])
		saleIds = saleIds + ` , ` + id
		prices = prices + ` , ` + priceString
		nftIdentifiers = nftIdentifiers + ` , ` + nftIdentifier
		ftIdentifiers = ftIdentifiers + ` , ` + ftIdentifier
		sellers = append(sellers, seller)

		i++
	}
	saleIds = saleIds + ` ]`
	nftIdentifiers = nftIdentifiers + ` ]`
	ftIdentifiers = ftIdentifiers + ` ]`
	prices = prices + ` ]`

	returnTime, _ := o.Script(`import Clock from "../contracts/Clock.cdc"
	pub fun main() :  UFix64 {
		return Clock.time()
	}`).GetAsJson()

	time, _ := strconv.ParseFloat(returnTime, 64)

	o.Tx("listMultipleNFTForSale",
		WithSigner("user1"),
		WithArg("marketplace", "find"),
		WithArg("nftAliasOrIdentifiers", nftIdentifiers),
		WithArg("ids", saleIds),
		WithArg("ftAliasOrIdentifiers", ftIdentifiers),
		WithArg("directSellPrices", prices),
		WithArg("validUntil", time+100000.0))

	fmt.Println(saleIds)

	o.Tx("buyMultipleNFTForSale",
		WithSigner("user2"),
		WithArg("marketplace", "find"),
		WithAddresses("users", sellers...),
		WithArg("ids", saleIds),
		WithArg("amounts", prices),
		WithMaxGas(2300),
	)

}
