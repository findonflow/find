package test_main

import (
	"testing"

	. "github.com/bjartek/overflow/v2"
)

func TestMarketDirectOfferEscrow(t *testing.T) {

	otu := &OverflowTestUtils{T: t, O: ot.O}
	price := 10.0

  id := dandyIds[0]
	eventIdentifier := otu.identifier("FindMarketDirectOfferEscrow", "DirectOffer")
	royaltyIdentifier := otu.identifier("FindMarket", "RoyaltyPaid")

	bidTx := otu.O.TxFN(
		WithSigner("user2"),
		WithArg("user", "user1"),
		WithArg("nftAliasOrIdentifier", "Dandy"),
		WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("amount", 10.0),
	)

	ot.Run(t, "Should be able to add direct offer and then sell", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price)
		otu.saleItemListed("user1", "active_ongoing", price) 
		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

	})

	ot.Run(t,"Should be able to add direct offer and then sell even the seller didn't link provider correctly", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price).
			unlinkDandyProvider("user1").
			acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

	})

	ot.Run(t,"Should be able to add direct offer and then sell even the buyer didn't link receiver correctly", func(t *testing.T) {

		otu.unlinkDandyReceiver("user2").
			directOfferMarketEscrowed("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)
	})

	ot.Run(t,"Should not be able to offer with price 0", func(t *testing.T) {

		bidTx("bidMarketDirectOfferEscrowed",
			WithArg("amount", 0.0),
			WithArg("validUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Offer price should be greater than 0")

	})

	ot.Run(t,"Should not be able to offer with invalid time", func(t *testing.T) {

		bidTx("bidMarketDirectOfferEscrowed",
			WithArg("amount", price),
			WithArg("validUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")

	})

	ot.Run(t,"Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			sendDandy("user5", "user1", id)

		otu.O.Tx("cancelMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t)
	})

	ot.Run(t,"Should be able to retract offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			sendDandy("user5", "user1", id)

		otu.O.Tx("retractOfferMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("id", id),
		).
			AssertSuccess(t)
	})

	ot.Run(t,"Should be able to increase offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)
	})

	ot.Run(t,"Should be able to reject offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	ot.Run(t,"Should be able to retract offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			retractOfferDirectOfferEscrowed("user2", "user1", id)
	})

	ot.Run(t,"Should not be able to offer your own NFT", func(t *testing.T) {

		bidTx("bidMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("validUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "You cannot bid on your own resource")
	})

	ot.Run(t,"Should not be able to accept expired offers", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			tickClock(200.0)

		otu.O.Tx("fulfillMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("id", id),
		).
			AssertFailure(t, "This direct offer is already expired")
	})

	//return money when outbid

	ot.Run(t,"Should return money when outbid", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)
		newPrice := 11.0

		bidTx("bidMarketDirectOfferEscrowed",
			WithSigner("user3"),
			WithArg("amount", newPrice),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount":        newPrice,
				"id":            id,
				"previousBuyer": otu.O.Address("user2"),
			}).
			AssertEvent(t, otu.identifier("FlowToken", "TokensDeposited"), map[string]interface{}{
				"amount": price,
				"to":     otu.O.Address("user2"),
			})
	})

	ot.Run(t,"Should not be able to direct offer after deprecated", func(t *testing.T) {

		otu.alterMarketOption("deprecate")

		bidTx("bidMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")
	})

	ot.Run(t,"Should not be able to increase offer if deprecated but able to accept offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.alterMarketOption("deprecate")

		otu.O.Tx("increaseBidMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("id", id),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.saleItemListed("user1", "active_ongoing", 10.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 10.0)
	})

	ot.Run(t,"Should be able to reject offer when deprecated", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("deprecate").
			rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	ot.Run(t,"Should not be able to direct offer after stopped", func(t *testing.T) {

		otu.alterMarketOption("stop")

		bidTx("bidMarketDirectOfferEscrowed",
			WithArg("validUntil", otu.currentTime()+200.0),
		).
			AssertFailure(t, "Tenant has stopped this item")
	})

	ot.Run(t,"Should not be able to increase offer nor buy if stopped", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.alterMarketOption("stop")

		otu.O.Tx("increaseBidMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("id", id),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.saleItemListed("user1", "active_ongoing", 10.0)

		otu.O.Tx("fulfillMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("id", id),
		).
			AssertFailure(t, "Tenant has stopped this item")
	})

	ot.Run(t,"Should be able to able to direct offer, add bit and accept offer after enabled", func(t *testing.T) {

		otu.alterMarketOption("deprecate").
			alterMarketOption("enable").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)
	})

	ot.Run(t,"Should be able to able to direct offerand reject after enabled", func(t *testing.T) {

		otu.alterMarketOption("deprecate").
			alterMarketOption("enable").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	ot.Run(t,"Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("deprecate")

		bidTx("bidMarketDirectOfferEscrowed",
			WithSigner("user3"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterMarketOption("stop")

		bidTx("bidMarketDirectOfferEscrowed",
			WithSigner("user3"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")
	})

	ot.Run(t,"Should be able to retract offer when deprecated and stopped", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("stop")

		otu.alterMarketOption("deprecate").
			retractOfferDirectOfferEscrowed("user2", "user1", id)

	})

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	ot.Run(t,"Royalties should be sent to correspondence upon accept offer action", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.O.Tx("fulfillMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("id", id),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "find",
			})
	})

	ot.Run(t,"Royalties of find platform should be able to change", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			setFindCut(0.035)

		otu.O.Tx("fulfillMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("id", id),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.35,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "find",
			})
	})


}
