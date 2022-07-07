package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
	"github.com/stretchr/testify/assert"
)

func TestLeaseMarketSale(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(100.0, "user1").
		registerUser("user1").
		createUser(100.0, "user2").
		registerUser("user2").
		createUser(100.0, "user3").
		registerUser("user3").
		registerFtInRegistry().
		setFlowLeaseMarketOption("Sale").
		setProfile("user1").
		setProfile("user2")
	price := 10.0

	otu.registerUserWithName("user1", "name1").
		registerUserWithName("user1", "name2").
		registerUserWithName("user1", "name3")

	t.Run("Should be able to list a lease for sale and buy it", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)

		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyLeaseForMarketSale("user2", "user1", "name1", price).
			moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should be able to list a lease for sale and buy it without the collection", func(t *testing.T) {
		otu.listLeaseForSale("user1", "name1", price).
			destroyLeaseCollection("user2").
			buyLeaseForMarketSale("user2", "user1", "name1", price).
			moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to cancel listing if the pointer is no longer valid", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price).
			moveNameTo("user1", "user2", "name1")

		otu.O.TransactionFromFile("delistLeaseSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				StringArray("name1")).
			Test(otu.T).AssertSuccess()

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to change price of lease", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)

		newPrice := 15.0
		otu.listLeaseForSale("user1", "name1", newPrice)
		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, fmt.Sprintf("%.8f", newPrice), itemsForSale[0].Amount)

		otu.cancelAllLeaseForSale("user1")

	})

	t.Run("Should not be able to buy your own listing", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)

		otu.O.TransactionFromFile("buyLeaseForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("You cannot buy your own listing")
	})

	t.Run("Should not be able to buy expired listing", func(t *testing.T) {

		otu.tickClock(200.0)

		otu.O.TransactionFromFile("buyLeaseForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("This sale item listing is already expired")

		otu.cancelAllLeaseForSale("user1")
	})

	t.Run("Should be able to cancel sale", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)

		otu.cancelLeaseForSale("user1", "name1")
		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 0, len(itemsForSale))
	})

	t.Run("Should not be able to buy if too low price", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)

		otu.O.TransactionFromFile("buyLeaseForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(5.0)).
			Test(otu.T).
			AssertFailure("Incorrect balance sent in vault. Expected 10.00000000 got 5.00000000")

		otu.cancelAllNFTForSale("user1")
	})

	t.Run("Should be able to list it in Flow but not FUSD.", func(t *testing.T) {

		otu.O.TransactionFromFile("listLeaseForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name1").
				String("FUSD").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Nothing matches")
	})

	t.Run("Should be able cancel all listing", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)
		otu.listLeaseForSale("user1", "name2", price)
		otu.listLeaseForSale("user1", "name3", price)

		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 3, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		res := otu.O.TransactionFromFile("delistAllLeaseSale").
			SignProposeAndPayAs("user1").
			Test(otu.T).AssertSuccess()

		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale"})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Should be able cancel all listing events", result)
	})

	t.Run("Should be able to list it, deprecate it and cannot list another again, but able to buy and delist.", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)

		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.alterLeaseMarketOption("Sale", "deprecate")

		otu.O.TransactionFromFile("listLeaseForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name2").
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.O.TransactionFromFile("buyLeaseForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()

		otu.alterLeaseMarketOption("Sale", "enable")

		otu.listLeaseForSale("user1", "name2", price)

		otu.alterLeaseMarketOption("Sale", "deprecate")

		otu.O.TransactionFromFile("delistLeaseSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				StringArray("name2")).
			Test(otu.T).
			AssertSuccess()

		otu.alterLeaseMarketOption("Sale", "enable")

		otu.cancelAllLeaseForSale("user1").
			moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should be able to list it, stop it and cannot list another again, nor buy but able to delist.", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)

		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.alterLeaseMarketOption("Sale", "stop")

		otu.O.TransactionFromFile("listLeaseForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name2").
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.O.TransactionFromFile("buyLeaseForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.O.TransactionFromFile("delistLeaseSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				StringArray("name1")).
			Test(otu.T).AssertFailure("Tenant has stopped this item")

		otu.alterLeaseMarketOption("Sale", "enable")
		otu.cancelAllLeaseForSale("user1")

	})

	t.Run("Should be able to purchase, list and delist items after enabled market option", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)

		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.O.TransactionFromFile("listLeaseForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name2").
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertSuccess()

		otu.O.TransactionFromFile("buyLeaseForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()

		otu.O.TransactionFromFile("listLeaseForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertSuccess()

		otu.cancelLeaseForSale("user2", "name1").
			moveNameTo("user2", "user1", "name1")
		itemsForSale = otu.getItemsForSale("user2")
		assert.Equal(t, 0, len(itemsForSale))
		otu.cancelAllLeaseForSale("user1")
	})

	/* Testing on Royalties */

	// network 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon buy action", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		otu.AutoGoldRename("Royalties should be sent to correspondence upon buy action status", status)

		res := otu.O.TransactionFromFile("buyLeaseForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"name":        "name1",
				"royaltyName": "find",
				"tenant":      "findLease",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("find"),
				"amount":      "0.50000000",
				"findName":    "",
				"name":        "name1",
				"royaltyName": "network",
				"tenant":      "findLease",
			}))
		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale"})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties should be sent to correspondence upon buy action events", result)

		otu.cancelAllLeaseForSale("user1").
			moveNameTo("user2", "user1", "name1")
	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		otu.setFindLeaseCut(0.035)
		otu.listLeaseForSale("user1", "name1", price)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()

		otu.AutoGoldRename("Royalties of find platform should be able to change status", status)

		res := otu.O.TransactionFromFile("buyLeaseForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.35000000",
				"findName":    "",
				"name":        "name1",
				"royaltyName": "find",
				"tenant":      "findLease",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("find"),
				"amount":      "0.50000000",
				"findName":    "",
				"name":        "name1",
				"royaltyName": "network",
				"tenant":      "findLease",
			}))
		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale"})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties of find platform should be able to change events", result)

		otu.cancelAllLeaseForSale("user1").
			moveNameTo("user2", "user1", "name1")
	})

	/* Honour Banning */
	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)
		otu.leaseProfileBan("user1")
		otu.O.TransactionFromFile("listLeaseForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name2").
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		otu.O.TransactionFromFile("buyLeaseForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		otu.cancelLeaseForSale("user1", "name1").
			removeLeaseProfileBan("user1")
	})

	t.Run("Should be able to ban user, user cannot buy NFT.", func(t *testing.T) {

		otu.listLeaseForSale("user1", "name1", price)
		otu.leaseProfileBan("user2")

		otu.O.TransactionFromFile("buyLeaseForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

		otu.removeLeaseProfileBan("user2").
			cancelLeaseForSale("user1", "name1").
			removeLeaseProfileBan("user2")
	})

	t.Run("Royalties should be sent to residual account if royalty receiver is not working", func(t *testing.T) {

		otu.setLeaseTenantRuleFUSD("FlowLeaseSale").
			removeLeaseTenantRule("FlowLeaseSale", "Flow")

		otu.O.TransactionFromFile("testSetResidualAddress").
			SignProposeAndPayAs("find").
			Args(otu.O.Arguments().Account("user3")).
			Test(otu.T).AssertSuccess()

		otu.O.TransactionFromFile("listLeaseForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name1").
				String("FUSD").
				UFix64(price).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess()

		otu.destroyFUSDVault("find")

		res := otu.O.TransactionFromFile("buyLeaseForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()
		/*
			  TODO maybe add back after overflow v3
				AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
					"address":     otu.accountAddress("account"),
					"amount":      "0.25000000",
					"id":          fmt.Sprintf("%d", ids[0]),
					"royaltyName": "find",
				})).
				AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyCouldNotBePaid", map[string]interface{}{
					"address":         otu.accountAddress("user1"),
					"amount":          "0.50000000",
					"findName":        "user1",
					"residualAddress": otu.accountAddrss("find"),
						"id":              fmt.Sprintf("%d", ids[0]),
					"royaltyName":     "minter",
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
		*/
		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindLeaseMarketSale.Sale"})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties should be sent to residual account if royalty receiver is not working events", result)
		otu.cancelAllNFTForSale("user1").
			moveNameTo("user2", "user1", "name1")
		// createUser(100, "find")

	})

	t.Run("Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {
		otu.registerDUCInRegistry().
			setDUCLease()

		otu.listLeaseForSaleDUC("user1", "name1", price)

		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyLeaseForMarketSaleDUC("user2", "user1", "name1", price).
			moveNameTo("user2", "user1", "name1")

	})

}
