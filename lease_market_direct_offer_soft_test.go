package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
)

func TestLeaseMarketDirectOfferSoft(t *testing.T) {
	otu := NewOverflowTest(t)

	otu.setupMarketAndDandy()
	otu.registerFtInRegistry().
		setFlowLeaseMarketOption("DirectOfferSoft").
		setProfile("user1").
		setProfile("user2")
	price := 10.0

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

	otu.registerUserWithName("user1", "name1").
		registerUserWithName("user1", "name2").
		registerUserWithName("user1", "name3")

	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			saleLeaseListed("user1", "active_finished", price).
			fulfillLeaseMarketDirectOfferSoft("user2", "name1", price)

		otu.moveNameTo("user2", "user1", "name1").
			sendFT("user1", "user2", "Flow", price)
	})

	t.Run("Should be able to add direct offer and then sell even the buyer is without collection", func(t *testing.T) {

		otu.destroyLeaseCollection("user2").
			directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			saleLeaseListed("user1", "active_finished", price).
			fulfillLeaseMarketDirectOfferSoft("user2", "name1", price)

		otu.moveNameTo("user2", "user1", "name1").
			sendFT("user1", "user2", "Flow", price)
	})

	t.Run("Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			moveNameTo("user1", "user2", "name1")

		otu.O.TransactionFromFile("cancelLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				StringArray("name1")).
			Test(otu.T).
			AssertSuccess()

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to retract offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			moveNameTo("user1", "user2", "name1")

		otu.O.TransactionFromFile("retractOfferLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1")).
			Test(otu.T).
			AssertSuccess()

		otu.moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should be able to increase offer", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			increaseDirectOfferLeaseMarketSoft("user2", "name1", 5.0, 15.0).
			saleLeaseListed("user1", "active_ongoing", 15.0)

		otu.cancelAllDirectOfferLeaseMarketSoft("user1")
	})

	t.Run("Should be able to reject offer", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			rejectDirectOfferLeaseSoft("user1", "name1", 10.0)
	})

	t.Run("Should be able to retract offer", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			retractOfferDirectOfferLeaseSoft("user2", "user1", "name1")
	})

	t.Run("Should not be able to offer your own NFT", func(t *testing.T) {

		otu.O.TransactionFromFile("bidLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name1").
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).AssertFailure("You cannot bid on your own resource")

	})

	t.Run("Should not be able to accept expired offer", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			tickClock(200.0)

		otu.O.TransactionFromFile("acceptLeaseDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name1")).
			Test(otu.T).AssertFailure("This direct offer is already expired")

		otu.cancelAllDirectOfferLeaseMarketSoft("user1")

	})

	t.Run("Should not be able to add direct offer when deprecated", func(t *testing.T) {

		otu.alterLeaseMarketOption("DirectOfferSoft", "deprecate")

		otu.O.TransactionFromFile("bidLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable")
	})

	t.Run("Should not be able to increase bid but able to fulfill offer when deprecated", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("DirectOfferSoft", "deprecate")

		otu.O.TransactionFromFile("increaseBidLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			saleLeaseListed("user1", "active_finished", price).
			fulfillLeaseMarketDirectOfferSoft("user2", "name1", price)

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable").
			moveNameTo("user2", "user1", "name1").
			sendFT("user1", "user2", "Flow", price)

	})

	t.Run("Should be able to reject offer when deprecated", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("DirectOfferSoft", "deprecate").
			rejectDirectOfferLeaseSoft("user1", "name1", 10.0)

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable")
	})

	t.Run("Should not be able to add direct offer after stopped", func(t *testing.T) {

		otu.alterLeaseMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("bidLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable")
	})

	t.Run("Should not be able to increase bid nor accept offer after stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("increaseBidLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.O.TransactionFromFile("acceptLeaseDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name1")).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable").
			cancelAllDirectOfferLeaseMarketSoft("user1")
	})

	t.Run("Should not be able to fulfill offer after stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			saleLeaseListed("user1", "active_finished", price).
			alterLeaseMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("fulfillLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

			/* Reset */
		otu.alterLeaseMarketOption("DirectOfferSoft", "enable")
		otu.O.TransactionFromFile("fulfillLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()
		otu.moveNameTo("user2", "user1", "name1").
			sendFT("user1", "user2", "Flow", price)

	})

	t.Run("Should not be able to reject offer after stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("cancelLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				StringArray("name1")).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable").
			cancelAllDirectOfferLeaseMarketSoft("user1")
	})

	t.Run("Should be able to direct offer, increase offer and fulfill offer after enabled", func(t *testing.T) {

		otu.alterLeaseMarketOption("DirectOfferSoft", "stop").
			alterLeaseMarketOption("DirectOfferSoft", "enable").
			directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			saleLeaseListed("user1", "active_finished", price).
			fulfillLeaseMarketDirectOfferSoft("user2", "name1", price)

		otu.moveNameTo("user2", "user1", "name1").
			sendFT("user1", "user2", "Flow", price)
	})

	t.Run("Should be able to reject offer after enabled", func(t *testing.T) {

		otu.alterLeaseMarketOption("DirectOfferSoft", "stop").
			alterLeaseMarketOption("DirectOfferSoft", "enable").
			directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			rejectDirectOfferLeaseSoft("user1", "name1", 10.0)
	})

	t.Run("Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("DirectOfferSoft", "deprecate")

		otu.O.TransactionFromFile("bidLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				String("name1").
				String("Flow").
				UFix64(price + 10.0).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("bidLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				String("name1").
				String("Flow").
				UFix64(price + 10.0).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable").
			cancelAllDirectOfferLeaseMarketSoft("user1")
	})

	t.Run("Should be able to retract offer when deprecated , but not when stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price)

		otu.alterLeaseMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("retractOfferLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1")).
			Test(otu.T).AssertFailure("Tenant has stopped this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "deprecate").
			retractOfferDirectOfferLeaseSoft("user2", "user1", "name1")

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable").
			cancelAllDirectOfferLeaseMarketSoft("user1")
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon accept offer action", func(t *testing.T) {

		price = 10.0

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		otu.AutoGoldRename("Royalties should be sent to correspondence upon accept offer action status", status)

		res := otu.O.TransactionFromFile("fulfillLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      0.25,
				"leaseName":   "name1",
				"royaltyName": "find",
				"tenant":      "findLease",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("find"),
				"amount":      0.5,
				"leaseName":   "name1",
				"royaltyName": "network",
				"tenant":      "findLease",
			}))

		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindLeaseMarketDirectOfferSoft.DirectOffer", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindLeaseMarketDirectOfferSoft.DirectOffer"})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties should be sent to correspondence upon accept offer action events", result)

		otu.moveNameTo("user2", "user1", "name1").
			sendFT("user1", "user2", "Flow", price)

	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		price = 10.0

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			setFindLeaseCut(0.035)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		otu.AutoGoldRename("Royalties of find platform should be able to change status", status)

		res := otu.O.TransactionFromFile("fulfillLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      0.35,
				"leaseName":   "name1",
				"royaltyName": "find",
				"tenant":      "findLease",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("find"),
				"amount":      0.5,
				"leaseName":   "name1",
				"royaltyName": "network",
				"tenant":      "findLease",
			}))

		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindLeaseMarketDirectOfferSoft.DirectOffer", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindLeaseMarketDirectOfferSoft.DirectOffer"})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties of find platform should be able to change events", result)

		otu.moveNameTo("user2", "user1", "name1").
			sendFT("user1", "user2", "Flow", price)

	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			directOfferLeaseMarketSoft("user2", "name2", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			leaseProfileBan("user1")

		otu.O.TransactionFromFile("bidLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name3").
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		// Should not be able to accept offer
		otu.O.TransactionFromFile("acceptLeaseDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name2")).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		// Should not be able to fulfill offer
		otu.O.TransactionFromFile("fulfillLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		//Should be able to cancel(reject) offer
		otu.O.TransactionFromFile("cancelLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				StringArray("name2")).
			Test(otu.T).
			AssertSuccess()

		otu.removeLeaseProfileBan("user1").
			cancelAllDirectOfferLeaseMarketSoft("user1")

	})

	t.Run("Should be able to ban user, user can only retract offer", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			directOfferLeaseMarketSoft("user2", "name2", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			leaseProfileBan("user2")

		otu.O.TransactionFromFile("bidLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name3").
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

		// Should not be able to accept offer
		otu.O.TransactionFromFile("acceptLeaseDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name2")).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

		// Should not be able to fulfill offer
		otu.O.TransactionFromFile("fulfillLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

		//Should be able to retract offer
		otu.retractOfferDirectOfferLeaseSoft("user2", "user1", "name2")

		otu.removeLeaseProfileBan("user2").
			cancelAllDirectOfferLeaseMarketSoft("user1")

	})

	t.Run("Should return money when outbid", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price)

		otu.saleLeaseListed("user1", "active_ongoing", price)

		newPrice := 11.0
		otu.O.TransactionFromFile("bidLeaseMarketDirectOfferSoft").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				String("name1").
				String("Flow").
				UFix64(newPrice).
				UFix64(100.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"amount":        newPrice,
				"leaseName":     "name1",
				"buyer":         otu.accountAddress("user3"),
				"previousBuyer": otu.accountAddress("user2"),
				"status":        "active_offered",
			}))

		otu.sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferLeaseMarketSoft("user1")
	})

	t.Run("Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {

		otu.registerDUCInRegistry().
			setDUCLease()

		otu.directOfferLeaseMarketSoftDUC("user2", "name1", price)

		otu.saleLeaseListed("user1", "active_ongoing", price).
			acceptDirectOfferLeaseMarketSoftDUC("user2", "user1", "name1", price).
			saleLeaseListed("user1", "active_finished", price).
			increaseDirectOfferLeaseMarketSoft("user2", "name1", 5.0, price+5.0).
			fulfillLeaseMarketDirectOfferSoftDUC("user2", "name1", price+5.0)

		otu.moveNameTo("user2", "user1", "name1")
	})

}
