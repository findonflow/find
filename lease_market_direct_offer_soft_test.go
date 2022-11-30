package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestLeaseMarketDirectOfferSoft(t *testing.T) {
	otu := NewOverflowTest(t)

	mintFund := otu.O.TxFN(
		WithSigner("account"),
		WithArg("amount", 10000.0),
		WithArg("recipient", "user2"),
	)

	otu.setupMarketAndDandy()
	otu.registerFtInRegistry().
		setFlowLeaseMarketOption("DirectOfferSoft").
		setProfile("user1").
		setProfile("user2")
	price := 10.0

	mintFund("devMintFusd").AssertSuccess(t)

	mintFund("devMintFlow").AssertSuccess(t)

	mintFund("devMintUsdc").AssertSuccess(t)

	otu.registerUserWithName("user1", "name1").
		registerUserWithName("user1", "name2").
		registerUserWithName("user1", "name3")

	otu.setUUID(400)

	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			saleLeaseListed("user1", "active_finished", price).
			fulfillLeaseMarketDirectOfferSoft("user2", "name1", price)

		otu.moveNameTo("user2", "user1", "name1").
			sendFT("user1", "user2", "Flow", price)
	})

	t.Run("Should not be able to offer with price 0", func(t *testing.T) {

		otu.O.Tx(
			"bidLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", 0.0),
			WithArg("validUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Offer price should be greater than 0")

	})

	t.Run("Should not be able to offer with invalid time", func(t *testing.T) {

		otu.O.Tx(
			"bidLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")

	})

	t.Run("Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			moveNameTo("user1", "user2", "name1")

		otu.O.Tx("cancelLeaseMarketDirectOfferSoft",
			WithSigner("user1"),
			WithArg("leaseNames", `["name1"]`),
		).
			AssertSuccess(t)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to retract offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			moveNameTo("user1", "user2", "name1")

		otu.O.Tx("retractOfferLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
		).
			AssertSuccess(t)

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

		otu.O.Tx("bidLeaseMarketDirectOfferSoft",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "You cannot bid on your own resource")

	})

	t.Run("Should not be able to accept expired offer", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			tickClock(200.0)

		otu.O.Tx("acceptLeaseDirectOfferSoft",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
		).
			AssertFailure(t, "This direct offer is already expired")

		otu.cancelAllDirectOfferLeaseMarketSoft("user1")

	})

	t.Run("Should not be able to add direct offer when deprecated", func(t *testing.T) {

		otu.alterLeaseMarketOption("DirectOfferSoft", "deprecate")

		otu.O.Tx("bidLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable")
	})

	t.Run("Should not be able to increase bid but able to fulfill offer when deprecated", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("DirectOfferSoft", "deprecate")

		otu.O.Tx("increaseBidLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

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

		otu.O.Tx("bidLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable")
	})

	t.Run("Should not be able to increase bid nor accept offer after stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("DirectOfferSoft", "stop")

		otu.O.Tx("increaseBidLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.O.Tx("acceptLeaseDirectOfferSoft",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable").
			cancelAllDirectOfferLeaseMarketSoft("user1")
	})

	t.Run("Should not be able to fulfill offer after stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			saleLeaseListed("user1", "active_finished", price).
			alterLeaseMarketOption("DirectOfferSoft", "stop")

		otu.O.Tx("fulfillLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

			/* Reset */
		otu.alterLeaseMarketOption("DirectOfferSoft", "enable")

		otu.O.Tx("fulfillLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertSuccess(t)

		otu.moveNameTo("user2", "user1", "name1").
			sendFT("user1", "user2", "Flow", price)

	})

	t.Run("Should not be able to reject offer after stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("DirectOfferSoft", "stop")

		otu.O.Tx("cancelLeaseMarketDirectOfferSoft",
			WithSigner("user1"),
			WithArg("leaseNames", `["name1"]`),
		).
			AssertFailure(t, "Tenant has stopped this item")

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

		otu.O.Tx("bidLeaseMarketDirectOfferSoft",
			WithSigner("user3"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "stop")

		otu.O.Tx("bidLeaseMarketDirectOfferSoft",
			WithSigner("user3"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("DirectOfferSoft", "enable").
			cancelAllDirectOfferLeaseMarketSoft("user1")
	})

	t.Run("Should be able to retract offer when deprecated , but not when stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price)

		otu.alterLeaseMarketOption("DirectOfferSoft", "stop")

		otu.O.Tx("retractOfferLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
		).
			AssertFailure(t, "Tenant has stopped this item")

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

		otu.O.Tx("fulfillLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.25,
				"leaseName":   "name1",
				"royaltyName": "find",
				"tenant":      "findLease",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.5,
				"leaseName":   "name1",
				"royaltyName": "network",
				"tenant":      "findLease",
			})

		otu.moveNameTo("user2", "user1", "name1").
			sendFT("user1", "user2", "Flow", price)

	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		price = 10.0

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			setFindLeaseCut(0.035)

		otu.O.Tx("fulfillLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.35,
				"leaseName":   "name1",
				"royaltyName": "find",
				"tenant":      "findLease",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.5,
				"leaseName":   "name1",
				"royaltyName": "network",
				"tenant":      "findLease",
			})

		otu.moveNameTo("user2", "user1", "name1").
			sendFT("user1", "user2", "Flow", price)

	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			directOfferLeaseMarketSoft("user2", "name2", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			leaseProfileBan("user1")

		otu.O.Tx("bidLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name3"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("acceptLeaseDirectOfferSoft",
			WithSigner("user1"),
			WithArg("leaseName", "name2"),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("fulfillLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("cancelLeaseMarketDirectOfferSoft",
			WithSigner("user1"),
			WithArg("leaseNames", `["name2"]`),
		).
			AssertSuccess(t)

		otu.removeLeaseProfileBan("user1").
			cancelAllDirectOfferLeaseMarketSoft("user1")

	})

	t.Run("Should be able to ban user, user can only retract offer", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price).
			directOfferLeaseMarketSoft("user2", "name2", price).
			acceptLeaseDirectOfferMarketSoft("user2", "user1", "name1", price).
			leaseProfileBan("user2")

		otu.O.Tx("bidLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name3"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		otu.O.Tx("acceptLeaseDirectOfferSoft",
			WithSigner("user1"),
			WithArg("leaseName", "name2"),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		otu.O.Tx("fulfillLeaseMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		//Should be able to retract offer
		otu.retractOfferDirectOfferLeaseSoft("user2", "user1", "name2")

		otu.removeLeaseProfileBan("user2").
			cancelAllDirectOfferLeaseMarketSoft("user1")

	})

	t.Run("Should return money when outbid", func(t *testing.T) {

		otu.directOfferLeaseMarketSoft("user2", "name1", price)

		otu.saleLeaseListed("user1", "active_ongoing", price)

		newPrice := 11.0

		otu.O.Tx("bidLeaseMarketDirectOfferSoft",
			WithSigner("user3"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", newPrice),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"amount":        newPrice,
				"leaseName":     "name1",
				"buyer":         otu.O.Address("user3"),
				"previousBuyer": otu.O.Address("user2"),
				"status":        "active_offered",
			})

		otu.sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferLeaseMarketSoft("user1")
	})

	t.Run("Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {

		otu.createDapperUser("user1").
			createDapperUser("user2")

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
