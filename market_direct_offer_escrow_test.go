package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
)

func TestMarketDirectOfferEscrow(t *testing.T) {

	price := 10.0
	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

	})

	t.Run("Should be able to add direct offer and then sell even the buyer is without collection", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			destroyDandyCollection("user2").
			directOfferMarketEscrowed("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

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
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)
	})

	t.Run("Should be able to reject offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	t.Run("Should be able to retract offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			retractOfferDirectOfferEscrowed("user2", "user1", id)

	})

	t.Run("Should not be able to offer your own NFT", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow")

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

	})

	t.Run("Should not be able to accept expired offers", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
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

	})

	//return money when outbid

	t.Run("Should return money when outbid", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

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
				UFix64(100.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
				"amount":        fmt.Sprintf("%.8f", newPrice),
				"id":            fmt.Sprintf("%d", id),
				"buyer":         otu.accountAddress("user3"),
				"previousBuyer": otu.accountAddress("user2"),
				"status":        "active_offered",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
				"amount": fmt.Sprintf("%.8f", price),
				"to":     otu.accountAddress("user2"),
			}))

	})

	/* Tests on Rules */
	t.Run("Should not be able to direct offer after deprecated", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow")

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

	})

	t.Run("Should not be able to increase offer if deprecated but able to accept offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
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
	})

	t.Run("Should be able to reject offer when deprecated", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferEscrow", "deprecate").
			rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	t.Run("Should not be able to direct offer after stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow")

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

	})

	t.Run("Should not be able to increase offer nor buy if stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
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
	})

	t.Run("Should not be able to reject offer after stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.TransactionFromFile("cancelMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")
	})

	t.Run("Should be able to able to direct offer, add bit and accept offer after enabled", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			alterMarketOption("DirectOfferEscrow", "deprecate").
			alterMarketOption("DirectOfferEscrow", "enable").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)
	})

	t.Run("Should be able to able to direct offerand reject after enabled", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			alterMarketOption("DirectOfferEscrow", "deprecate").
			alterMarketOption("DirectOfferEscrow", "enable").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	t.Run("Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
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
	})

	t.Run("Should be able to retract offer when deprecated, but not when stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
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
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon accept offer action", func(t *testing.T) {
		otu := NewOverflowTest(t)
		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			setProfile("user1").
			setProfile("user2").
			saleItemListed("user1", "active_ongoing", price)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		status = otu.replaceID(status, []uint64{id})
		otu.AutoGold("status", status)

		res := otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      "0.50000000",
				"findName":    "user1",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "minter",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "platform",
				"tenant":      "find",
			}))
		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer"})
		result = otu.replaceID(result, []uint64{id})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGold("events", result)

	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {
		otu := NewOverflowTest(t)
		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			setProfile("user1").
			setProfile("user2").
			setFindCut(0.035)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		status = otu.replaceID(status, []uint64{id})
		otu.AutoGold("status", status)

		res := otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.35000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      "0.50000000",
				"findName":    "user1",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "minter",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "platform",
				"tenant":      "find",
			}))
		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer"})
		result = otu.replaceID(result, []uint64{id})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGold("events", result)

	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {
		otu := NewOverflowTest(t)

		otu.setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			createUser(100.0, "user3").
			registerUser("user2").
			registerUser("user3")

		ids := otu.mintThreeExampleDandies()

		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", ids[0], price).
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
	})

	t.Run("Should be able to ban user, user can only retract offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		otu.setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			createUser(100.0, "user3").
			registerUser("user2").
			registerUser("user3")

		ids := otu.mintThreeExampleDandies()

		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", ids[0], price).
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
	})
}
