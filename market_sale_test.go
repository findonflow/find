package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
	"github.com/stretchr/testify/assert"
)

func TestMarketSale(t *testing.T) {

	t.Run("Should be able to list a dandy for sale and buy it", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setFlowDandyMarketOption("Sale")

		price := 10.0
		id := otu.mintThreeExampleDandies()[0]
		otu.listNFTForSale("user1", id, price)

		otu.checkRoyalty("user1", id, "platform", "Dandy", 0.15)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyNFTForMarketSale("user2", "user1", id, price)
	})

	//TODO: Should there be a seperate status?
	t.Run("Should be able to change price of dandy", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setFlowDandyMarketOption("Sale")

		price := 10.0
		id := otu.mintThreeExampleDandies()[0]
		otu.listNFTForSale("user1", id, price)

		otu.checkRoyalty("user1", id, "platform", "Dandy", 0.15)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		newPrice := 15.0
		otu.listNFTForSale("user1", id, newPrice)
		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, fmt.Sprintf("%.8f", newPrice), itemsForSale[0].Amount)
	})

	// //TODO: Should there be a seperate status?
	t.Run("Should be able to canel sale", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setFlowDandyMarketOption("Sale")

		price := 10.0
		id := otu.mintThreeExampleDandies()[0]
		otu.listNFTForSale("user1", id, price)

		otu.checkRoyalty("user1", id, "platform", "Dandy", 0.15)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.cancelNFTForSale("user1", id)
		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 0, len(itemsForSale))
	})

	t.Run("Should not be able to buy if too low price", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setFlowDandyMarketOption("Sale")

		price := 10.0
		id := otu.mintThreeExampleDandies()[0]
		otu.listNFTForSale("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.O.TransactionFromFile("buyItemForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("user1").
				UInt64(id).
				UFix64(5.0)).
			Test(otu.T).
			AssertFailure("Incorrect balance sent in vault. Expected 10.00000000 got 5.00000000")
	})

	t.Run("Should be able to list it in Flow but not FUSD.", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setFlowDandyMarketOption("Sale")

		price := 10.0
		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Nothing matches")
	})

	t.Run("Should be able cancel all listing", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setFlowDandyMarketOption("Sale")

		price := 10.0
		ids := otu.mintThreeExampleDandies()

		otu.listNFTForSale("user1", ids[0], price)
		otu.listNFTForSale("user1", ids[1], price)
		otu.listNFTForSale("user1", ids[2], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 3, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		expected := []*overflow.FormatedEvent{
			overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.ForSale", map[string]interface{}{
				"amount":    "10.00000000",
				"buyer":     "",
				"buyerName": "",
				"id":        fmt.Sprintf("%d", ids[2]),
				"nft": map[string]interface{}{
					"name":      "Neo Motorcycle 3 of 3",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type":      "A.f8d6e0586b0a20c7.Dandy.NFT",
					"id":        fmt.Sprintf("%d", ids[2]),
					"grouping":  "user1",
					"rarity":    "",
					"scalars": map[string]interface{}{
						"Speed": "100.00000000",
					},
					"tags": map[string]interface{}{
						"NeoMotorCycleTag": "Tag1",
					},
					"editionNumber":  "3",
					"totalInEdition": "3",
				},
				"seller":     otu.accountAddress("user1"),
				"sellerName": "user1",
				"status":     "cancel",
				"tenant":     "find",
				"vaultType":  "A.0ae53cb6e3f42a79.FlowToken.Vault",
			}),
			overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.ForSale", map[string]interface{}{
				"amount":    "10.00000000",
				"buyer":     "",
				"buyerName": "",
				"id":        fmt.Sprintf("%d", ids[1]),
				"nft": map[string]interface{}{
					"name":      "Neo Motorcycle 2 of 3",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type":      "A.f8d6e0586b0a20c7.Dandy.NFT",
					"id":        fmt.Sprintf("%d", ids[1]),
					"grouping":  "user1",
					"rarity":    "",
					"scalars": map[string]interface{}{
						"Speed": "100.00000000",
					},
					"tags": map[string]interface{}{
						"NeoMotorCycleTag": "Tag1",
					},
					"editionNumber":  "2",
					"totalInEdition": "3",
				},
				"seller":     otu.accountAddress("user1"),
				"sellerName": "user1",
				"status":     "cancel",
				"tenant":     "find",
				"vaultType":  "A.0ae53cb6e3f42a79.FlowToken.Vault",
			}),
			overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.ForSale", map[string]interface{}{
				"amount":    "10.00000000",
				"buyer":     "",
				"buyerName": "",
				"id":        fmt.Sprintf("%d", ids[0]),
				"nft": map[string]interface{}{
					"name":      "Neo Motorcycle 1 of 3",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type":      "A.f8d6e0586b0a20c7.Dandy.NFT",
					"id":        fmt.Sprintf("%d", ids[0]),
					"grouping":  "user1",
					"rarity":    "",
					"scalars": map[string]interface{}{
						"Speed": "100.00000000",
					},
					"tags": map[string]interface{}{
						"NeoMotorCycleTag": "Tag1",
					},
					"editionNumber":  "1",
					"totalInEdition": "3",
				},
				"seller":     otu.accountAddress("user1"),
				"sellerName": "user1",
				"status":     "cancel",
				"tenant":     "find",
				"vaultType":  "A.0ae53cb6e3f42a79.FlowToken.Vault",
			}),
		}

		otu.O.TransactionFromFile("cancelAllNFTForSale").
			SignProposeAndPayAs("user1").
			Test(otu.T).AssertSuccess().
			AssertEmitEvent(expected...)
	})

	t.Run("Should be able to list it, deprecate it and cannot list another again, but able to buy and delist.", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setFlowDandyMarketOption("Sale")

		price := 10.0
		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.alterMarketOption("Sale", "deprecate")

		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.O.TransactionFromFile("buyItemForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("user1").
				UInt64(ids[0]).
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()

		otu.alterMarketOption("Sale", "enable")

		otu.listNFTForSale("user1", ids[1], price)

		otu.alterMarketOption("Sale", "deprecate")

		otu.O.TransactionFromFile("cancelNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				UInt64Array(ids[1])).
			Test(otu.T).
			AssertSuccess()

	})

	t.Run("Should be able to list it, stop it and cannot list another again, nor buy but able to delist.", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setFlowDandyMarketOption("Sale")

		price := 10.0
		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.alterMarketOption("Sale", "stop")

		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.O.TransactionFromFile("buyItemForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("user1").
				UInt64(ids[0]).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.O.TransactionFromFile("cancelNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				UInt64Array(ids[0])).
			Test(otu.T).AssertFailure("Tenant has stopped this item")

	})

	t.Run("Should be able to purchase, list and delist items after enabled market option..", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setFlowDandyMarketOption("Sale").
			alterMarketOption("Sale", "stop").
			alterMarketOption("Sale", "enable")

		price := 10.0
		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()

		otu.O.TransactionFromFile("buyItemForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("user1").
				UInt64(ids[0]).
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()

		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[0]).
				String("Flow").
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()

		otu.cancelNFTForSale("user2", ids[0])
		itemsForSale = otu.getItemsForSale("user2")
		assert.Equal(t, 0, len(itemsForSale))
	})

}
