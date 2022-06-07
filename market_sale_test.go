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

		otu.checkRoyalty("user1", id, "platform", "Dandy", 0.025)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyNFTForMarketSale("user2", "user1", id, price)
	})

	t.Run("Should be able to list a dandy for sale and buy it without the collection", func(t *testing.T) {
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

		otu.checkRoyalty("user1", id, "platform", "Dandy", 0.025)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.destroyDandyCollection("user2").
			buyNFTForMarketSale("user2", "user1", id, price)
	})

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

		otu.checkRoyalty("user1", id, "platform", "Dandy", 0.025)

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

	t.Run("Should not be able to buy your own listing", func(t *testing.T) {
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

		otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("You cannot buy your own listing")
	})

	t.Run("Should not be able to buy expired listing", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setFlowDandyMarketOption("Sale")

		price := 10.0
		id := otu.mintThreeExampleDandies()[0]
		otu.listNFTForSale("user1", id, price).
			tickClock(200.0)

		otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("This sale item listing is already expired")
	})

	t.Run("Should be able to cancel sale", func(t *testing.T) {
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

		otu.checkRoyalty("user1", id, "platform", "Dandy", 0.025)

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

		otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
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
				Account("account").
				String("Dandy").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price).
				UFix64(100.0)).
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

		result := otu.O.TransactionFromFile("delistAllNFTSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().Account("account")).
			Test(otu.T).AssertSuccess()

		otu.AutoGold("events", result.Events)
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
				Account("account").
				String("Dandy").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(ids[0]).
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()

		otu.alterMarketOption("Sale", "enable")

		otu.listNFTForSale("user1", ids[1], price)

		otu.alterMarketOption("Sale", "deprecate")

		otu.O.TransactionFromFile("delistNFTSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
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
				Account("account").
				String("Dandy").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(ids[0]).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.O.TransactionFromFile("delistNFTSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
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
				Account("account").
				String("Dandy").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertSuccess()

		otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(ids[0]).
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()

		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("Dandy").
				UInt64(ids[0]).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertSuccess()

		otu.cancelNFTForSale("user2", ids[0])
		itemsForSale = otu.getItemsForSale("user2")
		assert.Equal(t, 0, len(itemsForSale))
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon buy action", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setProfile("user1").
			setProfile("user2").
			setFlowDandyMarketOption("Sale")

		price := 10.0
		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		otu.AutoGold("status", status)

		res := otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(ids[0]).
				UFix64(price)).
			Test(otu.T).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", ids[0]),
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      "0.50000000",
				"findName":    "user1",
				"id":          fmt.Sprintf("%d", ids[0]),
				"royaltyName": "artist",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", ids[0]),
				"royaltyName": "platform",
				"tenant":      "find",
			}))
		otu.AutoGold("events", res.Events)

	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry().
			setFlowDandyMarketOption("Sale").
			setProfile("user1").
			setProfile("user2").
			setFindCut(0.035)

		price := 10.0
		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		otu.AutoGold("status", status)

		res := otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(ids[0]).
				UFix64(price)).
			Test(otu.T).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.35000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", ids[0]),
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      "0.50000000",
				"findName":    "user1",
				"id":          fmt.Sprintf("%d", ids[0]),
				"royaltyName": "artist",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", ids[0]),
				"royaltyName": "platform",
				"tenant":      "find",
			}))
		otu.AutoGold("events", res.Events)

	})

	t.Run("Royalties should be sent to residual account if royalty receiver is not working", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			createUser(100.0, "user3").
			registerUser("user3").
			registerFtInRegistry().
			setProfile("user1").
			setProfile("user2").
			setProfile("user3").
			setFlowDandyMarketOption("Sale").
			setTenantRuleFUSD("FlowDandySale").
			removeTenantRule("FlowDandySale", "Flow")

		price := 10.0
		ids := otu.mintThreeExampleDandies()
		otu.sendDandy("user3", "user1", ids[0])

		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("account").
				String("Dandy").
				UInt64(ids[0]).
				String("FUSD").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).AssertSuccess()
		otu.destroyFUSDVault("user1")

		res := otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user3").
				UInt64(ids[0]).
				UFix64(price)).
			Test(otu.T).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", ids[0]),
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyCouldNotBePaid", map[string]interface{}{
				"address":         otu.accountAddress("user1"),
				"amount":          "0.50000000",
				"findName":        "user1",
				"residualAddress": otu.accountAddress("find"),
				"id":              fmt.Sprintf("%d", ids[0]),
				"royaltyName":     "artist",
				"tenant":          "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", ids[0]),
				"royaltyName": "platform",
				"tenant":      "find",
			}))
		otu.AutoGold("events", res.Events)

	})
}
