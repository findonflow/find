package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestLeaseMarketDirectOfferSoft(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	price := 10.0

	eventIdentifier := otu.identifier("FindLeaseMarketDirectOfferSoft", "DirectOffer")
	royaltyIdentifier := otu.identifier("FindLeaseMarket", "RoyaltyPaid")

	bidTx := otu.O.TxFileNameFN(
		"bidLeaseMarketDirectOfferSoftDapper",
		WithSigner("user6"),
		WithArg("leaseName", "user5"),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+10.0),
	)

	ot.Run(t, "Should be able to add direct offer and then sell", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user6", "user5", "user5", price).
			saleLeaseListed("user5", "active_finished", price).
			fulfillLeaseMarketDirectOfferSoft("user6", "user5", price)
	})

	ot.Run(t, "Should not be able to offer with price 0", func(t *testing.T) {
		bidTx(WithArg("amount", 0.0)).AssertFailure(t, "Offer price should be greater than 0")
	})

	ot.Run(t, "Should not be able to offer with invalid time", func(t *testing.T) {
		bidTx(WithArg("validUntil", 0.0)).AssertFailure(t, "Valid until is before current time")
	})

	ot.Run(t, "Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			moveNameTo("user5", "user6", "user5")

		otu.O.Tx("cancelLeaseMarketDirectOfferSoft",
			WithSigner("user5"),
			WithArg("leaseNames", `["user5"]`),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should be able to retract offer if the pointer is no longer valid", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			moveNameTo("user5", "user6", "user5")

		otu.O.Tx("retractOfferLeaseMarketDirectOfferSoft",
			WithSigner("user6"),
			WithArg("leaseName", "user5"),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should be able to increase offer", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			increaseDirectOfferLeaseMarketSoft("user6", "user5", 5.0, 15.0).
			saleLeaseListed("user5", "active_ongoing", 15.0)
	})

	ot.Run(t, "Should be able to reject offer", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			rejectDirectOfferLeaseSoft("user5", "user5", 10.0)
	})

	ot.Run(t, "Should be able to retract offer", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			retractOfferDirectOfferLeaseSoft("user6", "user5", "user5")
	})

	ot.Run(t, "Should not be able to offer your own NFT", func(t *testing.T) {
		bidTx(WithSigner("user5")).
			AssertFailure(t, "You cannot bid on your own resource")
	})

	ot.Run(t, "Should not be able to accept expired offer", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			tickClock(200.0)

		otu.O.Tx("acceptLeaseDirectOfferSoftDapper",
			WithSigner("user5"),
			WithArg("leaseName", "user5"),
		).
			AssertFailure(t, "This direct offer is already expired")
	})

	ot.Run(t, "Should not be able to add direct offer when deprecated", func(t *testing.T) {
		otu.alterLeaseMarketOption("deprecate")
		bidTx().AssertFailure(t, "Tenant has deprected mutation options on this item")
	})

	ot.Run(t, "Should not be able to increase bid but able to fulfill offer when deprecated", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			alterLeaseMarketOption("deprecate")

		otu.O.Tx("increaseBidLeaseMarketDirectOfferSoft",
			WithSigner("user6"),
			WithArg("leaseName", "user5"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.acceptLeaseDirectOfferMarketSoft("user6", "user5", "user5", price).
			saleLeaseListed("user5", "active_finished", price).
			fulfillLeaseMarketDirectOfferSoft("user6", "user5", price)
	})

	ot.Run(t, "Should be able to reject offer when deprecated", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			alterLeaseMarketOption("deprecate").
			rejectDirectOfferLeaseSoft("user5", "user5", 10.0)
	})

	ot.Run(t, "Should not be able to add direct offer after stopped", func(t *testing.T) {
		otu.alterLeaseMarketOption("stop")

		bidTx().AssertFailure(t, "Tenant has stopped this item")
	})

	ot.Run(t, "Should not be able to increase bid nor accept offer after stopped", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			alterLeaseMarketOption("stop")

		otu.O.Tx("increaseBidLeaseMarketDirectOfferSoft",
			WithSigner("user6"),
			WithArg("leaseName", "user5"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.O.Tx("acceptLeaseDirectOfferSoftDapper",
			WithSigner("user5"),
			WithArg("leaseName", "user5"),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("enable").
			cancelAllDirectOfferLeaseMarketSoft("user5")
	})

	ot.Run(t, "Should not be able to fulfill offer after stopped", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user6", "user5", "user5", price).
			saleLeaseListed("user5", "active_finished", price).
			alterLeaseMarketOption("stop")

		otu.O.Tx("fulfillLeaseMarketDirectOfferSoftDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("leaseName", "user5"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")
	})

	ot.Run(t, "Should not be able to reject offer after stopped", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			alterLeaseMarketOption("stop")

		otu.O.Tx("cancelLeaseMarketDirectOfferSoft",
			WithSigner("user5"),
			WithArg("leaseNames", `["user5"]`),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("enable").
			cancelAllDirectOfferLeaseMarketSoft("user5")
	})

	ot.Run(t, "Should be able to direct offer, increase offer and fulfill offer after enabled", func(t *testing.T) {
		otu.alterLeaseMarketOption("stop").
			alterLeaseMarketOption("enable").
			directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user6", "user5", "user5", price).
			saleLeaseListed("user5", "active_finished", price).
			fulfillLeaseMarketDirectOfferSoft("user6", "user5", price)

		otu.moveNameTo("user6", "user5", "user5")
	})

	ot.Run(t, "Should be able to reject offer after enabled", func(t *testing.T) {
		otu.alterLeaseMarketOption("stop").
			alterLeaseMarketOption("enable").
			directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			rejectDirectOfferLeaseSoft("user5", "user5", 10.0)
	})

	ot.Run(t, "Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			alterLeaseMarketOption("deprecate")

		otu.O.Tx("bidLeaseMarketDirectOfferSoftDapper",
			WithSigner("user3"),
			WithArg("leaseName", "user5"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterLeaseMarketOption("stop")

		otu.O.Tx("bidLeaseMarketDirectOfferSoftDapper",
			WithSigner("user3"),
			WithArg("leaseName", "user5"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("enable").
			cancelAllDirectOfferLeaseMarketSoft("user5")
	})

	ot.Run(t, "Should be able to retract offer when deprecated , but not when stopped", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price)

		otu.alterLeaseMarketOption("stop")

		otu.O.Tx("retractOfferLeaseMarketDirectOfferSoft",
			WithSigner("user6"),
			WithArg("leaseName", "user5"),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("deprecate").
			retractOfferDirectOfferLeaseSoft("user6", "user5", "user5")

		otu.alterLeaseMarketOption("enable").
			cancelAllDirectOfferLeaseMarketSoft("user5")
	})

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	ot.Run(t, "Royalties should be sent to correspondence upon accept offer action", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			saleLeaseListed("user5", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoft("user6", "user5", "user5", price)

		otu.O.Tx("fulfillLeaseMarketDirectOfferSoftDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("leaseName", "user5"),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"leaseName":   "user5",
				"royaltyName": "find",
				"tenant":      "find",
			})
	})

	ot.Run(t, "Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			directOfferLeaseMarketSoft("user6", "name2", price).
			acceptLeaseDirectOfferMarketSoft("user6", "user5", "user5", price).
			leaseProfileBan("user5")

		otu.O.Tx("bidLeaseMarketDirectOfferSoftDapper",
			WithSigner("user6"),
			WithArg("leaseName", "name3"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("acceptLeaseDirectOfferSoftDapper",
			WithSigner("user5"),
			WithArg("leaseName", "name2"),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("fulfillLeaseMarketDirectOfferSoftDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("leaseName", "user5"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("cancelLeaseMarketDirectOfferSoft",
			WithSigner("user5"),
			WithArg("leaseNames", `["name2"]`),
		).
			AssertSuccess(t)

		otu.removeLeaseProfileBan("user5").
			cancelAllDirectOfferLeaseMarketSoft("user5")
	})

	ot.Run(t, "Should be able to ban user, user can only retract offer", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price).
			directOfferLeaseMarketSoft("user6", "name2", price).
			acceptLeaseDirectOfferMarketSoft("user6", "user5", "user5", price).
			leaseProfileBan("user6")

		otu.O.Tx("bidLeaseMarketDirectOfferSoftDapper",
			WithSigner("user6"),
			WithArg("leaseName", "name3"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		otu.O.Tx("acceptLeaseDirectOfferSoftDapper",
			WithSigner("user5"),
			WithArg("leaseName", "name2"),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		otu.O.Tx("fulfillLeaseMarketDirectOfferSoftDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("leaseName", "user5"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		// Should be able to retract offer
		otu.retractOfferDirectOfferLeaseSoft("user6", "user5", "name2")
	})

	ot.Run(t, "Should return money when outbid", func(t *testing.T) {
		otu.directOfferLeaseMarketSoft("user6", "user5", price)

		otu.saleLeaseListed("user5", "active_ongoing", price)

		newPrice := 11.0

		otu.O.Tx("bidLeaseMarketDirectOfferSoftDapper",
			WithSigner("user3"),
			WithArg("leaseName", "user5"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", newPrice),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount":        newPrice,
				"buyer":         otu.O.Address("user3"),
				"previousBuyer": otu.O.Address("user6"),
				"status":        "active_offered",
			})

		otu.cancelAllDirectOfferLeaseMarketSoft("user5")
	})

	ot.Run(t, "Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {
		otu.directOfferLeaseMarketSoftDUC("user6", "user5", price)

		otu.saleLeaseListed("user5", "active_ongoing", price).
			acceptDirectOfferLeaseMarketSoftDUC("user6", "user5", "user5", price).
			saleLeaseListed("user5", "active_finished", price).
			increaseDirectOfferLeaseMarketSoft("user6", "user5", 5.0, price+5.0).
			fulfillLeaseMarketDirectOfferSoftDUC("user6", "user5", price+5.0)
	})
}
