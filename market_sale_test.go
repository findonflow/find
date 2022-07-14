package test_main

import (
	"testing"

	"github.com/bjartek/overflow/overflow"
	"github.com/stretchr/testify/assert"
)

func TestMarketSale(t *testing.T) {

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
	id := otu.mintThreeExampleDandies()[0]

	t.Run("Should be able to list a dandy for sale and buy it", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)

		otu.checkRoyalty("user1", id, "platform", "Dandy", 0.025)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyNFTForMarketSale("user2", "user1", id, price).
			sendDandy("user1", "user2", id)

	})

	t.Run("Should be able to list a dandy for sale and buy it without the collection", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price).
			destroyDandyCollection("user2").
			buyNFTForMarketSale("user2", "user1", id, price).
			sendDandy("user1", "user2", id)
	})

	t.Run("Should be able to cancel listing if the pointer is no longer valid", func(t *testing.T) {
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
			sendDandy("user2", "user1", id)

		otu.O.TransactionFromFile("delistNFTSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).AssertSuccess()

	})

	t.Run("Should be able to change price of dandy", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)

		newPrice := 15.0
		otu.listNFTForSale("user1", id, newPrice)
		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, newPrice, itemsForSale[0].Amount)

		otu.cancelAllNFTForSale("user1")

	})

	t.Run("Should not be able to buy your own listing", func(t *testing.T) {

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

		otu.tickClock(200.0)

		otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("This sale item listing is already expired")

		otu.cancelAllNFTForSale("user1")
	})

	t.Run("Should be able to cancel sale", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)

		otu.cancelNFTForSale("user1", id)
		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 0, len(itemsForSale))
	})

	t.Run("Should not be able to buy if too low price", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)

		otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(5.0)).
			Test(otu.T).
			AssertFailure("Incorrect balance sent in vault. Expected 10.00000000 got 5.00000000")

		otu.cancelAllNFTForSale("user1")
	})

	t.Run("Should be able to list it in Flow but not FUSD.", func(t *testing.T) {

		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("Dandy").
				UInt64(id).
				String("FUSD").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Nothing matches")
	})

	t.Run("Should be able cancel all listing", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.listNFTForSale("user1", ids[0], price)
		otu.listNFTForSale("user1", ids[1], price)
		otu.listNFTForSale("user1", ids[2], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 3, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		res := otu.O.TransactionFromFile("delistAllNFTSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().Account("account")).
			Test(otu.T).AssertSuccess()

		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketSale.Sale", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindMarketSale.Sale"})
		result = otu.replaceID(result, ids)
		result = otu.replaceID(result, saleIDs)
		o := *otu
		o.AutoGoldRename("Should be able cancel all listing events", result)
	})

	t.Run("Should be able to list it, deprecate it and cannot list another again, but able to buy and delist.", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, price, itemsForSale[0].Amount)

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

		otu.alterMarketOption("Sale", "enable")

	})

	t.Run("Should be able to list it, stop it and cannot list another again, nor buy but able to delist.", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, price, itemsForSale[0].Amount)

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

		otu.alterMarketOption("Sale", "enable")
		otu.cancelAllNFTForSale("user1")

	})

	t.Run("Should be able to purchase, list and delist items after enabled market option..", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, price, itemsForSale[0].Amount)

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
		otu.cancelAllNFTForSale("user1")
		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		status = otu.replaceID(status, ids)
		otu.AutoGoldRename("Royalties should be sent to correspondence upon buy action status", status)

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
				"amount":      0.25,
				"id":          ids[0],
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          ids[0],
				"royaltyName": "minter",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      0.25,
				"id":          ids[0],
				"royaltyName": "platform",
				"tenant":      "find",
			}))
		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketSale.Sale", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindMarketSale.Sale"})
		result = otu.replaceID(result, ids)
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties should be sent to correspondence upon buy action events", result)

	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.setFindCut(0.035)
		otu.listNFTForSale("user1", ids[0], price)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		status = otu.replaceID(status, ids)
		otu.AutoGoldRename("Royalties of find platform should be able to change status", status)

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
				"amount":      0.35,
				"id":          ids[0],
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          ids[0],
				"royaltyName": "minter",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      0.25,
				"id":          ids[0],
				"royaltyName": "platform",
				"tenant":      "find",
			}))
		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketSale.Sale", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindMarketSale.Sale"})
		result = otu.replaceID(result, ids)
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties of find platform should be able to change events", result)

	})

	/* Honour Banning */
	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)
		otu.profileBan("user1")
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		otu.cancelNFTForSale("user1", id).
			removeProfileBan("user1")
	})

	t.Run("Should be able to ban user, user cannot buy NFT.", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)
		otu.profileBan("user2")

		otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

		otu.removeProfileBan("user2").
			cancelNFTForSale("user1", id).
			removeProfileBan("user2")
	})

	t.Run("Royalties should be sent to residual account if royalty receiver is not working", func(t *testing.T) {

		otu.setTenantRuleFUSD("FlowDandySale").
			removeTenantRule("FlowDandySale", "Flow")

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
				UFix64(otu.currentTime() + 100.0)).
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
		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketSale.Sale", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindMarketSale.Sale"})
		result = otu.replaceID(result, ids)
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties should be sent to residual account if royalty receiver is not working events", result)
		otu.cancelAllNFTForSale("user1")
	})

	t.Run("Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {
		otu.registerDUCInRegistry().
			sendExampleNFT("user1", "account").
			setDUCExampleNFT()

		saleItemID := otu.listNFTForSaleDUC("user1", 0, price)

		otu.checkRoyalty("user1", 0, "minter", "ExampleNFT", 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyNFTForMarketSaleDUC("user2", "user1", saleItemID[0], price).
			sendExampleNFT("user1", "user2")

	})

	t.Run("Should be able to list an NFT for sale and buy it. where id != uuid", func(t *testing.T) {
		saleItem := otu.listExampleNFTForSale("user1", 0, price)

		otu.checkRoyalty("user1", 0, "minter", "ExampleNFT", 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyNFTForMarketSale("user2", "user1", saleItem[0], price).
			sendExampleNFT("user1", "user2")

	})

	t.Run("Should be able to list multiple dandies for sale and buy them in one go", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		// list multiple NFT for sale
		otu.O.TransactionFromFile("listMultipleNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				StringArray("Dandy", "Dandy", "Dandy").
				UInt64Array(ids[0], ids[1], ids[2]).
				StringArray("FUSD", "FUSD", "FUSD").
				UFix64Array(price, price, price).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess()

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 3, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, "active_listed", itemsForSale[1].SaleType)
		assert.Equal(t, "active_listed", itemsForSale[2].SaleType)

		seller := "user1"
		name := "user2"
		// otu.buyNFTForMarketSale("user2", "user1", id, price)
		otu.O.TransactionFromFile("buyMultipleNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				StringArray("user1", "user1", "user1").
				UInt64Array(ids[0], ids[1], ids[2]).
				UFix64Array(price, price, price)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.Sale", map[string]interface{}{
				"amount": price,
				"id":     ids[0],
				"seller": otu.accountAddress(seller),
				"buyer":  otu.accountAddress(name),
				"status": "sold",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.Sale", map[string]interface{}{
				"amount": price,
				"id":     ids[1],
				"seller": otu.accountAddress(seller),
				"buyer":  otu.accountAddress(name),
				"status": "sold",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.Sale", map[string]interface{}{
				"amount": price,
				"id":     ids[2],
				"seller": otu.accountAddress(seller),
				"buyer":  otu.accountAddress(name),
				"status": "sold",
			}))

	})

	t.Run("Should be able to list 15 dandies in one go", func(t *testing.T) {

		number := 15

		otu.O.TransactionFromFile("testMintFusd").
			SignProposeAndPayAsService().
			Args(otu.O.Arguments().
				Account("user2").
				UFix64(1000.0)).
			Test(otu.T).
			AssertSuccess()

		ids := otu.mintThreeExampleDandies()
		dandy := []string{"Dandy", "Dandy", "Dandy"}
		fusd := []string{"FUSD", "FUSD", "FUSD"}
		prices := []float64{price, price, price}

		for len(ids) < number {
			id := otu.mintThreeExampleDandies()
			ids = append(ids, id...)
		}

		ids = ids[:number]

		for len(dandy) < number {
			dandy = append(dandy, dandy[0])
			fusd = append(fusd, fusd[0])
			prices = append(prices, prices[0])
		}

		// list multiple NFT for sale
		//1024 for 1 buy, 634 each increment, max 15 items
		otu.O.TransactionFromFile("listMultipleNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				StringArray(dandy...).
				UInt64Array(ids...).
				StringArray(fusd...).
				UFix64Array(prices...).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess()

		otu.cancelAllNFTForSale("user1")

	})

	t.Run("Should be able to buy at max 5 dandies", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		dandy := []string{"Dandy", "Dandy", "Dandy"}
		fusd := []string{"FUSD", "FUSD", "FUSD"}
		prices := []float64{price, price, price}
		buyers := []string{"user1", "user1", "user1"}

		id := otu.mintThreeExampleDandies()
		ids = append(ids, id[0], id[1])
		dandy = append(dandy, []string{"Dandy", "Dandy"}...)
		fusd = append(fusd, []string{"FUSD", "FUSD"}...)
		prices = append(prices, []float64{price, price}...)
		buyers = append(buyers, []string{"user1", "user1"}...)

		// list multiple NFT for sale
		//1024 for 1 buy, 634 each increment, max 15 items
		otu.O.TransactionFromFile("listMultipleNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				StringArray(dandy...).
				UInt64Array(ids...).
				StringArray(fusd...).
				UFix64Array(prices...).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess()

		otu.O.TransactionFromFile("buyMultipleNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				StringArray(buyers...).
				UInt64Array(ids...).
				UFix64Array(prices...)).
			Test(otu.T).AssertSuccess()

		otu.cancelAllNFTForSale("user1")

	})

	t.Run("Should be able to list ExampleNFT for sale and buy it with DUC using MultipleNFT transaction", func(t *testing.T) {

		res := otu.O.TransactionFromFile("listMultipleNFTForSaleDUC").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				Account("account").
				StringArray("ExampleNFT").
				UInt64Array(0).
				UFix64Array(price).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess()

		saleItemID := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketSale.Sale", "id")

		otu.checkRoyalty("user1", 0, "minter", "ExampleNFT", 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.O.TransactionFromFile("buyMultipleNFTForSaleDUC").
			SignProposeAndPayAs("user2").PayloadSigner("account").
			Args(otu.O.Arguments().
				Account("account").
				Account("account").
				StringArray("user1").
				UInt64Array(saleItemID[0]).
				UFix64Array(price)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.Sale", map[string]interface{}{
				"amount": price,
				"id":     saleItemID[0],
				"seller": otu.accountAddress("user1"),
				"buyer":  otu.accountAddress("user2"),
				"status": "sold",
			}))

		otu.sendExampleNFT("user1", "user2")

	})

}
