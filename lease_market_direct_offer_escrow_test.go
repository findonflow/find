package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestLeaseMarketDirectOfferEscrow(t *testing.T) {
	otu := NewOverflowTest(t)

	otu.setupMarketAndDandy()
	otu.registerFtInRegistry().
		setFlowLeaseMarketOption().
		setProfile("user1").
		setProfile("user2")

	price := 10.0

	otu.registerUserWithName("user1", "name1").
		registerUserWithName("user1", "name2").
		registerUserWithName("user1", "name3")

	otu.sendFT("user2", "account", "Flow", 1000.0)

	otu.setUUID(500)

	eventIdentifier := otu.identifier("FindLeaseMarketDirectOfferEscrow", "DirectOffer")
	royaltyIdentifier := otu.identifier("FindLeaseMarket", "RoyaltyPaid")

	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			fulfillLeaseDirectOfferMarketEscrow("user2", "user1", "name1", price)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should not be able to offer with price 0", func(t *testing.T) {

		otu.O.Tx(
			"bidLeaseMarketDirectOfferEscrow",
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
			"bidLeaseMarketDirectOfferEscrow",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")

	})

	t.Run("Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			moveNameTo("user1", "user2", "name1")

		otu.O.Tx("cancelLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseNames", `["name1"]`),
		).
			AssertSuccess(t)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to retract offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			moveNameTo("user1", "user2", "name1")

		otu.O.Tx("retractOfferLeaseMarketDirectOfferEscrow",
			WithSigner("user2"),
			WithArg("leaseNames", []string{"name1"}),
		).
			AssertSuccess(t)

		otu.moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should be able to increase offer", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			increaseDirectOfferLeaseMarketEscrow("user2", "name1", 5.0, 15.0).
			saleLeaseListed("user1", "active_ongoing", 15.0)

		otu.cancelAllDirectOfferLeaseMarketEscrow("user1")
	})

	t.Run("Should be able to reject offer", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			rejectDirectOfferLeaseEscrow("user1", "name1", 10.0)
	})

	t.Run("Should be able to retract offer", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			retractOfferDirectOfferLeaseEscrow("user2", "user1", "name1")
	})

	t.Run("Should not be able to offer your own NFT", func(t *testing.T) {

		otu.O.Tx("bidLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "You cannot bid on your own resource")

	})

	t.Run("Should not be able to accept expired offer", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			tickClock(200.0)

		otu.O.Tx("fulfillLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
		).
			AssertFailure(t, "This direct offer is already expired")

		otu.cancelAllDirectOfferLeaseMarketEscrow("user1")

	})

	t.Run("Should not be able to add direct offer when deprecated", func(t *testing.T) {

		otu.alterLeaseMarketOption("deprecate")

		otu.O.Tx("bidLeaseMarketDirectOfferEscrow",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterLeaseMarketOption("enable")
	})

	t.Run("Should not be able to increase bid but able to fulfill offer when deprecated", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("deprecate")

		otu.O.Tx("increaseBidLeaseMarketDirectOfferEscrow",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.fulfillLeaseDirectOfferMarketEscrow("user2", "user1", "name1", price)

		otu.alterLeaseMarketOption("enable").
			moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should be able to reject offer when deprecated", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("deprecate").
			rejectDirectOfferLeaseEscrow("user1", "name1", 10.0)

		otu.alterLeaseMarketOption("enable")
	})

	t.Run("Should not be able to add direct offer after stopped", func(t *testing.T) {

		otu.alterLeaseMarketOption("stop")

		otu.O.Tx("bidLeaseMarketDirectOfferEscrow",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("enable")
	})

	t.Run("Should not be able to increase bid nor accept offer after stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("stop")

		otu.O.Tx("increaseBidLeaseMarketDirectOfferEscrow",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.O.Tx("fulfillLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("enable").
			cancelAllDirectOfferLeaseMarketEscrow("user1")
	})

	t.Run("Should not be able to fulfill offer after stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("stop")

		otu.O.Tx("fulfillLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
		).
			AssertFailure(t, "Tenant has stopped this item")

			/* Reset */
		otu.alterLeaseMarketOption("enable")

		otu.O.Tx("fulfillLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
		).
			AssertSuccess(t)

		otu.moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should not be able to reject offer after stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("stop")

		otu.O.Tx("cancelLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseNames", `["name1"]`),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("enable").
			cancelAllDirectOfferLeaseMarketEscrow("user1")
	})

	t.Run("Should be able to direct offer, increase offer and fulfill offer after enabled", func(t *testing.T) {

		otu.alterLeaseMarketOption("stop").
			alterLeaseMarketOption("enable").
			directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			fulfillLeaseDirectOfferMarketEscrow("user2", "user1", "name1", price)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to reject offer after enabled", func(t *testing.T) {

		otu.alterLeaseMarketOption("stop").
			alterLeaseMarketOption("enable").
			directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			rejectDirectOfferLeaseEscrow("user1", "name1", 10.0)
	})

	t.Run("Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			alterLeaseMarketOption("deprecate")

		otu.O.Tx("bidLeaseMarketDirectOfferEscrow",
			WithSigner("user3"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterLeaseMarketOption("stop")

		otu.O.Tx("bidLeaseMarketDirectOfferEscrow",
			WithSigner("user3"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("enable").
			cancelAllDirectOfferLeaseMarketEscrow("user1")
	})

	t.Run("Should be able to retract offer when deprecated , but not when stopped", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price)

		otu.alterLeaseMarketOption("stop")

		otu.O.Tx("retractOfferLeaseMarketDirectOfferEscrow",
			WithSigner("user2"),
			WithArg("leaseNames", []string{"name1"}),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("deprecate").
			retractOfferDirectOfferLeaseEscrow("user2", "user1", "name1")

		otu.alterLeaseMarketOption("enable").
			cancelAllDirectOfferLeaseMarketEscrow("user1")
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon accept offer action", func(t *testing.T) {

		price = 10.0

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price)

		otu.O.Tx("fulfillLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"leaseName":   "name1",
				"royaltyName": "find",
				"tenant":      "find",
			})

		otu.moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			directOfferLeaseMarketEscrow("user2", "name2", price).
			leaseProfileBan("user1")

		otu.O.Tx("bidLeaseMarketDirectOfferEscrow",
			WithSigner("user2"),
			WithArg("leaseName", "name3"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("fulfillLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseName", "name2"),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("fulfillLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("cancelLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseNames", `["name2"]`),
		).
			AssertSuccess(t)

		otu.removeLeaseProfileBan("user1").
			cancelAllDirectOfferLeaseMarketEscrow("user1")

	})

	t.Run("Should be able to ban user, user can only retract offer", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price).
			directOfferLeaseMarketEscrow("user2", "name2", price).
			leaseProfileBan("user2")

		otu.O.Tx("bidLeaseMarketDirectOfferEscrow",
			WithSigner("user2"),
			WithArg("leaseName", "name3"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		otu.O.Tx("fulfillLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseName", "name2"),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		otu.O.Tx("fulfillLeaseMarketDirectOfferEscrow",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		//Should be able to retract offer
		otu.retractOfferDirectOfferLeaseEscrow("user2", "user1", "name2")

		otu.removeLeaseProfileBan("user2").
			cancelAllDirectOfferLeaseMarketEscrow("user1")

	})

	t.Run("Should return money when outbid", func(t *testing.T) {

		otu.directOfferLeaseMarketEscrow("user2", "name1", price)

		otu.saleLeaseListed("user1", "active_ongoing", price)

		newPrice := 11.0

		otu.O.Tx("bidLeaseMarketDirectOfferEscrow",
			WithSigner("user3"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", newPrice),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount":        newPrice,
				"buyer":         otu.O.Address("user3"),
				"previousBuyer": otu.O.Address("user2"),
				"status":        "active_offered",
			})

		otu.cancelAllDirectOfferLeaseMarketEscrow("user1")
	})

}
