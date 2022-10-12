package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestBulkMarketSale(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		setupDandy("user1").
		createUser(1000.0, "user2").
		registerUser("user2").
		createUser(1000.0, "user3").
		registerUser("user3").
		setFlowDandyMarketOption("Sale").
		setProfile("user1").
		setProfile("user2")

	otu.O.Tx("testMintFlow", saSigner,
		WithArg("recipient", "user2"),
		WithArg("amount", 1000.0),
	).AssertSuccess(t)

	price := 10.0
	items := otu.mintThreeExampleDandies()
	items2 := otu.mintThreeExampleDandies()
	items3 := otu.mintThreeExampleDandies()
	items4 := otu.mintThreeExampleDandies()
	items5 := otu.mintThreeExampleDandies()
	items6 := otu.mintThreeExampleDandies()

	otu.registerFtInRegistry()

	id := items[0]
	id2 := items[1]
	id3 := items[2]
	id4 := items2[0]
	id5 := items2[1]
	id6 := items2[2]
	id7 := items3[0]
	id8 := items3[1]
	id9 := items3[2]
	id10 := items4[0]
	id11 := items4[1]
	id12 := items4[2]
	id13 := items5[0]
	id14 := items5[1]
	id15 := items5[2]
	id16 := items6[0]
	id17 := items6[1]

	otu.listNFTForSale("user1", id, price)
	otu.listNFTForSale("user1", id2, price)
	otu.listNFTForSale("user1", id3, price)
	otu.listNFTForSale("user1", id4, price)
	otu.listNFTForSale("user1", id5, price)
	otu.listNFTForSale("user1", id6, price)
	otu.listNFTForSale("user1", id7, price)
	otu.listNFTForSale("user1", id8, price)
	otu.listNFTForSale("user1", id9, price)
	otu.listNFTForSale("user1", id10, price)
	otu.listNFTForSale("user1", id11, price)
	otu.listNFTForSale("user1", id12, price)
	otu.listNFTForSale("user1", id13, price)
	otu.listNFTForSale("user1", id14, price)
	otu.listNFTForSale("user1", id15, price)
	otu.listNFTForSale("user1", id16, price)
	otu.listNFTForSale("user1", id17, price)

	t.Run("Should be able to list a dandy for sale and buy it", func(t *testing.T) {

		otu.O.Tx("buyMultipleNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithAddresses("users", "user1"),
			WithArg("ids", []uint64{id}),
			WithArg("amounts", `[10.0]`),
		).
			AssertSuccess(t)

		result := otu.O.Tx("buyMultipleNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithAddresses("users", "user1"),
			WithArg("ids", []uint64{id2}),
			WithArg("amounts", `[10.0]`),
		).
			AssertSuccess(t).
			AssertComputationLessThenOrEqual(t, 800)

		result.Print(WithMeter(), WithoutEvents())

	})

	// Max is 15 for now
	t.Run("Should be able to list multiple dandy for sale and buy it", func(t *testing.T) {

		result := otu.O.Tx("buyMultipleNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithAddresses("users", "user1", "user1", "user1", "user1", "user1", "user1", "user1", "user1", "user1", "user1"),
			WithArg("ids", []uint64{id3, id4, id5, id6, id7, id8, id9, id10, id11, id12}),
			WithArg("amounts", `[10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0, 10.0]`),
		).
			AssertSuccess(t).
			AssertComputationLessThenOrEqual(t, 2200)

		result.Print(WithMeter(), WithoutEvents())

	})

}
