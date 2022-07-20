package test_main

import (
	"testing"

	"github.com/bjartek/overflow/overflow"
	"github.com/stretchr/testify/assert"
)

func TestBulkMarketSale(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		setupDandy("user1").
		createUser(100.0, "user2").
		registerUser("user2").
		createUser(100.0, "user3").
		registerUser("user3").
		registerFtInRegistry().
		setFlowDandyMarketOption("Sale").
		setProfile("user1").
		setProfile("user2")
	price := 10.0
	items := otu.mintThreeExampleDandies()
	items2 := otu.mintThreeExampleDandies()
	items3 := otu.mintThreeExampleDandies()

	id := items[0]
	id2 := items[1]
	id3 := items[2]
	id4 := items2[0]
	id5 := items2[1]
	id6 := items2[2]
	id7 := items3[0]
	id8 := items3[1]
	id9 := items3[2]

	otu.listNFTForSale("user1", id, price)
	otu.listNFTForSale("user1", id2, price)
	otu.listNFTForSale("user1", id3, price)
	otu.listNFTForSale("user1", id4, price)
	otu.listNFTForSale("user1", id5, price)
	otu.listNFTForSale("user1", id6, price)
	otu.listNFTForSale("user1", id7, price)
	otu.listNFTForSale("user1", id8, price)
	otu.listNFTForSale("user1", id9, price)

	t.Run("Should be able to list a dandy for sale and buy it", func(t *testing.T) {

		result := otu.O.TransactionFromFile("buyMultipleNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				AccountArray("user1").
				UInt64Array(id).
				UFix64Array(price)).
			Test(otu.T).AssertSuccess().
			AssertComputationLessThenOrEqual(0)

		result.Result.Print(overflow.WithMeter(), overflow.WithoutEvents())
		assert.Fail(t, "failed")

	})

	t.Run("Should be able to list multiple dandy for sale and buy it", func(t *testing.T) {
		result := otu.O.TransactionFromFile("buyMultipleNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				AccountArray("user1", "user1", "user1", "user1", "user1", "user1", "user1", "user1").
				UInt64Array(id2, id3, id4, id5, id6, id7, id8, id9).
				UFix64Array(price, price, price, price, price, price, price, price)).
			Test(otu.T).AssertSuccess().
			AssertComputationLessThenOrEqual(0)

		result.Result.Print(overflow.WithMeter(), overflow.WithoutEvents())
		assert.Fail(t, "failed")

	})

}
