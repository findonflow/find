package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestMarketDirectOfferSoft(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

  price := 10.0
  id := dapperDandyId
	eventIdentifier := otu.identifier("FindMarketDirectOfferSoft", "DirectOffer")
	royaltyIdentifier := otu.identifier("FindMarket", "RoyaltyPaid")

	bidTx := otu.O.TxFN(
		WithSigner("user6"),
		WithArg("user", "user5"),
		WithArg("nftAliasOrIdentifier", "Dandy"),
		WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("amount", 10.0),
		WithArg("validUntil", otu.currentTime()+10.0),
	)

	ot.Run(t,"Should be able to add direct offer and then sell", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user5", id, "user6", price).
			saleItemListed("user5", "active_finished", price).
			fulfillMarketDirectOfferSoft("user6", id, price)
	})

	ot.Run(t,"Should be able to add direct offer and then sell even the buyer is without collection", func(t *testing.T) {

		otu.destroyDandyCollection("user6").
			directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user5", id, "user6", price).
			saleItemListed("user5", "active_finished", price).
			fulfillMarketDirectOfferSoft("user6", id, price)
	})

	ot.Run(t,"Should not be able to offer with price 0", func(t *testing.T) {

		bidTx("bidMarketDirectOfferSoftDapper",
			WithArg("amount", 0.0),
		).
			AssertFailure(t, "Offer price should be greater than 0")

	})

	ot.Run(t,"Should not be able to offer with invalid time", func(t *testing.T) {

		bidTx("bidMarketDirectOfferSoftDapper",
			WithArg("amount", price),
			WithArg("validUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")

	})

	ot.Run(t,"Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			sendDandy("user6", "user5", id)


		otu.O.Tx("cancelMarketDirectOfferSoft",
			WithSigner("user5"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t)
	})

	ot.Run(t,"Should be able to retract offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			sendDandy("user6", "user5", id)

		otu.O.Tx("retractOfferMarketDirectOfferSoft",
			WithSigner("user6"),
			WithArg("id", id),
		).
			AssertSuccess(t)
	})

	ot.Run(t,"Should be able to increase offer", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			increaseDirectOfferMarketSoft("user6", id, 5.0, 15.0).
			saleItemListed("user5", "active_ongoing", 15.0)

		otu.cancelAllDirectOfferMarketSoft("user5")
	})

	ot.Run(t,"Should be able to reject offer", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			rejectDirectOfferSoft("user5", id, 10.0)
	})

	ot.Run(t,"Should be able to retract offer", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			retractOfferDirectOfferSoft("user6", "user5", id)
	})

	ot.Run(t,"Should not be able to offer your own NFT", func(t *testing.T) {

		bidTx("bidMarketDirectOfferSoftDapper",
			WithSigner("user5"),
			WithArg("validUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "You cannot bid on your own resource")

	})

	ot.Run(t,"Should not be able to accept expired offer", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			tickClock(200.0)

		otu.O.Tx("acceptDirectOfferSoftDapper",
			WithSigner("user5"),
			WithArg("id", id),
		).
			AssertFailure(t, "This direct offer is already expired")

		otu.cancelAllDirectOfferMarketSoft("user5")

	})

	ot.Run(t,"Should not be able to add direct offer when deprecated", func(t *testing.T) {

		otu.alterMarketOptionDapper("deprecate")

		bidTx("bidMarketDirectOfferSoftDapper",
			WithSigner("user6"),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterMarketOptionDapper("enable")
	})

	ot.Run(t,"Should not be able to increase bid but able to fulfill offer when deprecated", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			alterMarketOptionDapper("deprecate")

		otu.O.Tx("increaseBidMarketDirectOfferSoft",
			WithSigner("user6"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.acceptDirectOfferMarketSoft("user5", id, "user6", price).
			saleItemListed("user5", "active_finished", price).
			fulfillMarketDirectOfferSoft("user6", id, price)

		otu.alterMarketOptionDapper("enable").
			sendDandy("user5", "user6", id)

	})

	ot.Run(t,"Should be able to reject offer when deprecated", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			alterMarketOptionDapper("deprecate").
			rejectDirectOfferSoft("user5", id, 10.0)

		otu.alterMarketOptionDapper("enable")
	})

	ot.Run(t,"Should not be able to add direct offer after stopped", func(t *testing.T) {

		otu.alterMarketOptionDapper("stop")

		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user6"),
			WithArg("user", "user5"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOptionDapper("enable")
	})

	ot.Run(t,"Should not be able to increase bid nor accept offer after stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			alterMarketOptionDapper("stop")

		otu.O.Tx("increaseBidMarketDirectOfferSoft",
			WithSigner("user6"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.O.Tx("acceptDirectOfferSoftDapper",
			WithSigner("user5"),
			WithArg("id", id),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOptionDapper("enable").
			cancelAllDirectOfferMarketSoft("user5")
	})

	ot.Run(t,"Should not be able to fulfill offer after stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user5", id, "user6", price).
			saleItemListed("user5", "active_finished", price).
			alterMarketOptionDapper("stop")

		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

			/* Reset */
		otu.alterMarketOptionDapper("enable")
		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t)
		otu.sendDandy("user5", "user6", id)

	})

	ot.Run(t,"Should be able to direct offer, increase offer and fulfill offer after enabled", func(t *testing.T) {

		otu.alterMarketOptionDapper("stop").
			alterMarketOptionDapper("enable").
			directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user5", id, "user6", price).
			saleItemListed("user5", "active_finished", price).
			fulfillMarketDirectOfferSoft("user6", id, price)

		otu.sendDandy("user5", "user6", id)
	})

	ot.Run(t,"Should be able to reject offer after enabled", func(t *testing.T) {

		otu.alterMarketOptionDapper("stop").
			alterMarketOptionDapper("enable").
			directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			rejectDirectOfferSoft("user5", id, 10.0)
	})

	ot.Run(t,"Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			alterMarketOptionDapper("deprecate")

		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user3"),
			WithArg("user", "user5"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterMarketOptionDapper("stop")

		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user3"),
			WithArg("user", "user5"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOptionDapper("enable").
			cancelAllDirectOfferMarketSoft("user5")
	})

	ot.Run(t,"Should be able to retract offer when deprecated or stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price)

		otu.alterMarketOptionDapper("stop")

		otu.alterMarketOptionDapper("deprecate").
			retractOfferDirectOfferSoft("user6", "user5", id)

		otu.alterMarketOptionDapper("enable").
			cancelAllDirectOfferMarketSoft("user5")
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	ot.Run(t,"Royalties should be sent to correspondence upon accept offer action", func(t *testing.T) {

		price = 10.0

		otu.directOfferMarketSoft("user6", "user5", id, price).
			saleItemListed("user5", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user5", id, "user6", price)

		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "find",
			}).
      /*TODO dont know why this does not work here, is this an error
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user5"),
				"amount":      0.5,
				"findName":    "user5",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "find",
			}).*/
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "find",
			})

		otu.sendDandy("user5", "user6", id)

	})

	ot.Run(t,"Should return money when outbid", func(t *testing.T) {

		otu.directOfferMarketSoft("user6", "user5", id, price)

		otu.saleItemListed("user5", "active_ongoing", price)

		newPrice := 11.0
		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user3"),
			WithArg("user", "user5"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", newPrice),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount":        newPrice,
				"id":            id,
				"buyer":         otu.O.Address("user3"),
				"previousBuyer": otu.O.Address("user6"),
				"status":        "active_offered",
			})

		otu.cancelAllDirectOfferMarketSoft("user5")
	})

	ot.Run(t,"Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {
		saleItemID := otu.directOfferMarketSoftDUC("user6", "user5", id, price)

		otu.saleItemListed("user5", "active_ongoing", price).
			acceptDirectOfferMarketSoftDUC("user5", saleItemID[0], "user6", price).
			saleItemListed("user5", "active_finished", price).
			fulfillMarketDirectOfferSoftDUC("user6", saleItemID[0], price)
	})

}
