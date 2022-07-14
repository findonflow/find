package test_main

import (
	"testing"

	"github.com/bjartek/overflow/overflow"
)

func TestMarketDirectOfferEscrow(t *testing.T) {
	otu := NewOverflowTest(t)
	price := 10.0
	id := otu.setupMarketAndDandy()
	otu.registerFtInRegistry().
		setFlowDandyMarketOption("DirectOfferEscrow").
		setProfile("user1").
		setProfile("user2")

	otu.O.TransactionFromFile("testMintFusd").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			Account("user2").
			UFix64(1000.0)).
		Test(otu.T).
		AssertSuccess()

	otu.O.TransactionFromFile("testMintFlow").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			Account("user2").
			UFix64(1000.0)).
		Test(otu.T).
		AssertSuccess()

	otu.O.TransactionFromFile("testMintUsdc").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			Account("user2").
			UFix64(1000.0)).
		Test(otu.T).
		AssertSuccess()

	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to add direct offer and then sell even the buyer is without collection", func(t *testing.T) {

		otu.destroyDandyCollection("user2").
			directOfferMarketEscrowed("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			destroyDandyCollection("user2").
			directOfferMarketEscrowed("user2", "user1", id, price).
			sendDandy("user2", "user1", id)

		otu.O.TransactionFromFile("cancelMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).
			AssertSuccess()

	})

	t.Run("Should be able to retract offer if the pointer is no longer valid", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			destroyDandyCollection("user2").
			directOfferMarketEscrowed("user2", "user1", id, price).
			sendDandy("user2", "user1", id)

		otu.O.TransactionFromFile("retractOfferMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).
			AssertSuccess()

	})

	t.Run("Should be able to increase offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0)

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to reject offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	t.Run("Should be able to retract offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			retractOfferDirectOfferEscrowed("user2", "user1", id)

		otu.cancelAllDirectOfferMarketEscrowed("user1")

	})

	t.Run("Should not be able to offer your own NFT", func(t *testing.T) {

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).AssertFailure("You cannot bid on your own resource")

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to accept expired offers", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			tickClock(200.0)

		otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertFailure("This direct offer is already expired")

		otu.cancelAllDirectOfferMarketEscrowed("user1")

	})

	//return money when outbid

	t.Run("Should return money when outbid", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)
```suggestion
```suggestion
newPrice := 11.0
		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(newPrice).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
				"amount":    newPrice,
				"id":            id,
				"previousBuyer": otu.accountAddress("user2"),
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
				"amount": price,
				"to":     otu.accountAddress("user2"),
			}))
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	/* Tests on Rules */
	t.Run("Should not be able to direct offer after deprecated", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferEscrow", "deprecate")

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")
		otu.alterMarketOption("DirectOfferEscrow", "enable")
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to increase offer if deprecated but able to accept offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.alterMarketOption("DirectOfferEscrow", "deprecate")

		otu.O.TransactionFromFile("increaseBidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(5)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.saleItemListed("user1", "active_ongoing", 10.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 10.0)

		otu.alterMarketOption("DirectOfferEscrow", "enable")

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 10.0)
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to reject offer when deprecated", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferEscrow", "deprecate").
			rejectDirectOfferEscrowed("user1", id, 10.0)
		otu.alterMarketOption("DirectOfferEscrow", "enable")
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to direct offer after stopped", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferEscrow", "enable")
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to increase offer nor buy if stopped", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.TransactionFromFile("increaseBidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(5)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.saleItemListed("user1", "active_ongoing", 10.0)

		otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferEscrow", "enable").
			cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to reject offer after stopped", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.TransactionFromFile("cancelMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferEscrow", "enable").
			cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to able to direct offer, add bit and accept offer after enabled", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferEscrow", "deprecate").
			alterMarketOption("DirectOfferEscrow", "enable").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0)
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to able to direct offerand reject after enabled", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferEscrow", "deprecate").
			alterMarketOption("DirectOfferEscrow", "enable").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferEscrowed("user1", id, 10.0)
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferEscrow", "deprecate")

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price + 10.0).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price + 10.0).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferEscrow", "enable").
			cancelAllDirectOfferMarketEscrowed("user1")

	})

	t.Run("Should be able to retract offer when deprecated, but not when stopped", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.TransactionFromFile("retractOfferMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferEscrow", "deprecate").
			retractOfferDirectOfferEscrowed("user2", "user1", id)

		otu.alterMarketOption("DirectOfferEscrow", "enable")
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon accept offer action", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		status = otu.replaceID(status, []uint64{id})
		otu.AutoGoldRename("Royalties should be sent to correspondence upon accept offer action status", status)

		res := otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "minter",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "platform",
				"tenant":      "find",
			}))
		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer"})
		result = otu.replaceID(result, []uint64{id})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties should be sent to correspondence upon accept offer action events", result)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			setFindCut(0.035)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		status = otu.replaceID(status, []uint64{id})
		otu.AutoGoldRename("Royalties of find platform should be able to change status", status)

		res := otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      0.35,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "minter",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "platform",
				"tenant":      "find",
			}))
		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer"})
		result = otu.replaceID(result, []uint64{id})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties of find platform should be able to change events", result)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price).
			profileBan("user1")

		// Should not be able to make offer
		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

			// Should not be able to accept offer
		otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(ids[0])).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

			// Should be able to reject offer
		otu.O.TransactionFromFile("cancelMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(ids[0])).
			Test(otu.T).
			AssertSuccess()

		otu.removeProfileBan("user1").
			cancelAllDirectOfferMarketEscrowed("user1")

	})

	t.Run("Should be able to ban user, user can only retract offer", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price).
			profileBan("user2")

		// Should not be able to make offer
		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

			// Should not be able to accept offer
		otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(ids[0])).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

			// Should be able to reject offer
		otu.retractOfferDirectOfferEscrowed("user2", "user1", ids[0])

		otu.removeProfileBan("user2")
		otu.cancelAllDirectOfferMarketEscrowed("user1")

	})

	t.Run("Should be able to offer an NFT and fulfill it with id != uuid", func(t *testing.T) {

		otu.registerDUCInRegistry().
			sendExampleNFT("user1", "account").
			setDUCExampleNFT()

		saleItem := otu.directOfferMarketEscrowedExampleNFT("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketEscrowed("user1", saleItem[0], "user2", price)
		otu.cancelAllDirectOfferMarketEscrowed("user1")

	})

	t.Run("Should be able to direct offer and fulfill multiple NFT in one go", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		ids := otu.mintThreeExampleDandies()

		seller := "user1"
		name := "user2"
		otu.O.TransactionFromFile("bidMultipleMarketDirectOfferEscrowed").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				Account("account").
				StringArray(seller, seller, seller).
				StringArray("Dandy", "Dandy", "Dandy").
				UInt64Array(ids...).
				StringArray("Flow", "Flow", "Flow").
				UFix64Array(price, price, price).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
				"amount": price,
				"id":     ids[0],
				"buyer":  otu.accountAddress(name),
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
				"amount": price,
				"id":     ids[1],
				"buyer":  otu.accountAddress(name),
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
				"amount": price,
				"id":     ids[2],
				"buyer":  otu.accountAddress(name),
			}))

		name = "user1"
		buyer := "user2"

		otu.O.TransactionFromFile("fulfillMultipleMarketDirectOfferEscrowed").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(ids...)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
				"id":     ids[0],
				"seller": otu.accountAddress(name),
				"buyer":  otu.accountAddress(buyer),
				"amount": price,
				"status": "sold",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
				"id":     ids[1],
				"seller": otu.accountAddress(name),
				"buyer":  otu.accountAddress(buyer),
				"amount": price,
				"status": "sold",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
				"id":     ids[2],
				"seller": otu.accountAddress(name),
				"buyer":  otu.accountAddress(buyer),
				"amount": price,
				"status": "sold",
			}))

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

}
