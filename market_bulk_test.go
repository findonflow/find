package test_main

import (
	"fmt"
	"testing"

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

	id := items[0]
	id2 := items[1]
	id3 := items[2]
	id4 := items2[0]
	id5 := items2[1]
	id6 := items2[2]

	t.Run("Should be able to list a dandy for sale and buy it", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)
		otu.listNFTForSale("user1", id2, price)
		otu.listNFTForSale("user1", id3, price)
		otu.listNFTForSale("user1", id4, price)
		otu.listNFTForSale("user1", id5, price)
		otu.listNFTForSale("user1", id6, price)

		result := otu.O.TransactionFromFile("buyNew").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				AccountArray("user1", "user1", "user1").
				//				AccountArray("user1").
				//				UInt64Array(id).
				UInt64Array(id, id2, id3).
				//				UFix64Array(price)).
				UFix64Array(price, price, price)).
			Test(otu.T).AssertSuccess()

		fmt.Println(result.Result.ComputationUsed)
		assert.Fail(t, "failed")

	})
}
