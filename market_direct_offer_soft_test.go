package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
)

func TestMarketDirectOfferSoft(t *testing.T) {
	otu := NewOverflowTest(t)

	id := otu.setupMarketAndDandyDapper()
	otu.registerDandyInNFTRegistry().
		registerDUCInRegistry().
		setFlowDandyMarketOption("DirectOfferSoft").
		setProfile("user1").
		setProfile("user2").
		createDapperUser("find").
		createDapperUser("find-admin")

	price := 10.0

	otu.setUUID(600)

	eventIdentifier := otu.identifier("FindMarketDirectOfferSoft", "DirectOffer")
	royaltyIdentifier := otu.identifier("FindMarket", "RoyaltyPaid")

	bidTx := otu.O.TxFN(
		WithSigner("user2"),
		WithArg("marketplace", "find"),
		WithArg("user", "user1"),
		WithArg("nftAliasOrIdentifier", "Dandy"),
		WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("amount", 0.0),
		WithArg("validUntil", otu.currentTime()+10.0),
	)

	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price).
			saleItemListed("user1", "active_finished", price).
			fulfillMarketDirectOfferSoft("user2", id, price)

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should be able to add direct offer and then sell even the buyer is without collection", func(t *testing.T) {

		otu.destroyDandyCollection("user2").
			directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price).
			saleItemListed("user1", "active_finished", price).
			fulfillMarketDirectOfferSoft("user2", id, price)

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should not be able to offer with price 0", func(t *testing.T) {

		bidTx("bidMarketDirectOfferSoftDapper",
			WithArg("amount", 0.0),
		).
			AssertFailure(t, "Offer price should be greater than 0")

	})

	t.Run("Should not be able to offer with invalid time", func(t *testing.T) {

		bidTx("bidMarketDirectOfferSoftDapper",
			WithArg("amount", price),
			WithArg("validUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")

	})

	t.Run("Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			sendDandy("user2", "user1", id)

		otu.setUUID(1000)

		otu.O.Tx("cancelMarketDirectOfferSoft",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t)

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should be able to retract offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			sendDandy("user2", "user1", id)

		otu.setUUID(1400)

		otu.O.Tx("retractOfferMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
		).
			AssertSuccess(t)
		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should be able to increase offer", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketSoft("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0)

		otu.cancelAllDirectOfferMarketSoft("user1")
	})

	t.Run("Should be able to reject offer", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferSoft("user1", id, 10.0)
	})

	t.Run("Should be able to retract offer", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			retractOfferDirectOfferSoft("user2", "user1", id)
	})

	t.Run("Should not be able to offer your own NFT", func(t *testing.T) {

		bidTx("bidMarketDirectOfferSoftDapper",
			WithSigner("user1"),
			WithArg("validUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "You cannot bid on your own resource")

	})

	t.Run("Should not be able to accept expired offer", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			tickClock(200.0)

		otu.O.Tx("acceptDirectOfferSoftDapper",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
		).
			AssertFailure(t, "This direct offer is already expired")

		otu.cancelAllDirectOfferMarketSoft("user1")

	})

	t.Run("Should not be able to add direct offer when deprecated", func(t *testing.T) {

		otu.alterMarketOptionDapper("DirectOfferSoft", "deprecate")

		bidTx("bidMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterMarketOptionDapper("DirectOfferSoft", "enable")
	})

	t.Run("Should not be able to increase bid but able to fulfill offer when deprecated", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOptionDapper("DirectOfferSoft", "deprecate")

		otu.O.Tx("increaseBidMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.acceptDirectOfferMarketSoft("user1", id, "user2", price).
			saleItemListed("user1", "active_finished", price).
			fulfillMarketDirectOfferSoft("user2", id, price)

		otu.alterMarketOptionDapper("DirectOfferSoft", "enable").
			sendDandy("user1", "user2", id)

	})

	t.Run("Should be able to reject offer when deprecated", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOptionDapper("DirectOfferSoft", "deprecate").
			rejectDirectOfferSoft("user1", id, 10.0)

		otu.alterMarketOptionDapper("DirectOfferSoft", "enable")
	})

	t.Run("Should not be able to add direct offer after stopped", func(t *testing.T) {

		otu.alterMarketOptionDapper("DirectOfferSoft", "stop")

		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOptionDapper("DirectOfferSoft", "enable")
	})

	t.Run("Should not be able to increase bid nor accept offer after stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOptionDapper("DirectOfferSoft", "stop")

		otu.O.Tx("increaseBidMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.O.Tx("acceptDirectOfferSoftDapper",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOptionDapper("DirectOfferSoft", "enable").
			cancelAllDirectOfferMarketSoft("user1")
	})

	t.Run("Should not be able to fulfill offer after stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price).
			saleItemListed("user1", "active_finished", price).
			alterMarketOptionDapper("DirectOfferSoft", "stop")

		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

			/* Reset */
		otu.alterMarketOptionDapper("DirectOfferSoft", "enable")
		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t)
		otu.sendDandy("user1", "user2", id)

	})

	t.Run("Should be able to direct offer, increase offer and fulfill offer after enabled", func(t *testing.T) {

		otu.alterMarketOptionDapper("DirectOfferSoft", "stop").
			alterMarketOptionDapper("DirectOfferSoft", "enable").
			directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price).
			saleItemListed("user1", "active_finished", price).
			fulfillMarketDirectOfferSoft("user2", id, price)

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should be able to reject offer after enabled", func(t *testing.T) {

		otu.alterMarketOptionDapper("DirectOfferSoft", "stop").
			alterMarketOptionDapper("DirectOfferSoft", "enable").
			directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferSoft("user1", id, 10.0)
	})

	t.Run("Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOptionDapper("DirectOfferSoft", "deprecate")

		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user3"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterMarketOptionDapper("DirectOfferSoft", "stop")

		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user3"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOptionDapper("DirectOfferSoft", "enable").
			cancelAllDirectOfferMarketSoft("user1")
	})

	t.Run("Should be able to retract offer when deprecated or stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.alterMarketOptionDapper("DirectOfferSoft", "stop")

		otu.alterMarketOptionDapper("DirectOfferSoft", "deprecate").
			retractOfferDirectOfferSoft("user2", "user1", id)

		otu.alterMarketOptionDapper("DirectOfferSoft", "enable").
			cancelAllDirectOfferMarketSoft("user1")
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon accept offer action", func(t *testing.T) {

		price = 10.0

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price)

		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find-admin"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "onefootball",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.65,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "onefootball",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.65,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "onefootball",
			})

		otu.sendDandy("user1", "user2", id)

	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		price = 10.0

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price).
			setFindCutDapper(0.035)

		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find-admin"),
				"amount":      0.35,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "onefootball",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.65,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "onefootball",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.65,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "onefootball",
			})

		otu.sendDandy("user1", "user2", id)

	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.directOfferMarketSoft("user2", "user1", ids[0], price).
			directOfferMarketSoft("user2", "user1", ids[1], price).
			acceptDirectOfferMarketSoft("user1", ids[0], "user2", price).
			profileBan("user1")

		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", ids[2]),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Seller banned by Tenant")

			// Should not be able to accept offer
		otu.O.Tx("acceptDirectOfferSoftDapper",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("id", ids[1]),
		).
			AssertFailure(t, "Seller banned by Tenant")

			// Should not be able to fulfill offer
		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("id", ids[0]),
			WithArg("amount", price),
		).
			AssertFailure(t, "Seller banned by Tenant")

		//Should be able to cancel(reject) offer
		otu.O.Tx("cancelMarketDirectOfferSoft",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", ids[1:2]),
		).
			AssertSuccess(t)

		otu.removeProfileBan("user1").
			cancelAllDirectOfferMarketSoft("user1")

	})

	t.Run("Should be able to ban user, user can only retract offer", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.directOfferMarketSoft("user2", "user1", ids[0], price).
			directOfferMarketSoft("user2", "user1", ids[1], price).
			acceptDirectOfferMarketSoft("user1", ids[0], "user2", price).
			profileBan("user2")

		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", ids[2]),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Buyer banned by Tenant")

			// Should not be able to accept offer
		otu.O.Tx("acceptDirectOfferSoftDapper",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("id", ids[1]),
		).
			AssertFailure(t, "Buyer banned by Tenant")

			// Should not be able to fulfill offer
		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("id", ids[0]),
			WithArg("amount", price),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		//Should be able to retract offer
		otu.retractOfferDirectOfferSoft("user2", "user1", ids[1])

		otu.removeProfileBan("user2").
			cancelAllDirectOfferMarketSoft("user1")

	})

	t.Run("Should return money when outbid", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)

		newPrice := 11.0
		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user3"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
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
				"previousBuyer": otu.O.Address("user2"),
				"status":        "active_offered",
			})

		otu.cancelAllDirectOfferMarketSoft("user1")
	})

	t.Run("Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {

		otu.setDUCExampleNFT().
			sendExampleNFT("user1", "find")

		saleItemID := otu.directOfferMarketSoftDUC("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoftDUC("user1", saleItemID[0], "user2", price).
			saleItemListed("user1", "active_finished", price).
			fulfillMarketDirectOfferSoftDUC("user2", saleItemID[0], price)

		otu.sendExampleNFT("user1", "user2")
	})

	t.Run("Should be able to offer an NFT and fulfill it with id != uuid", func(t *testing.T) {

		saleItemID := otu.directOfferMarketSoftExampleNFT("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", saleItemID[0], "user2", price).
			saleItemListed("user1", "active_finished", price).
			fulfillMarketDirectOfferSoft("user2", saleItemID[0], price)

		otu.sendExampleNFT("user1", "user2")
	})

	t.Run("Should be able to multiple offer and fulfill", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.O.Tx("bidMultipleMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("users", []string{"user1", "user1", "user1"}),
			WithArg("nftAliasOrIdentifiers", []string{dandyNFTType(otu), dandyNFTType(otu), dandyNFTType(otu)}),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", []string{"FUT", "FUT", "FUT"}),
			WithArg("amounts", []float64{price, price, price}),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount": price,
				"id":     ids[0],
				"buyer":  otu.O.Address("user2"),
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount": price,
				"id":     ids[1],
				"buyer":  otu.O.Address("user2"),
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount": price,
				"id":     ids[2],
				"buyer":  otu.O.Address("user2"),
			})

		otu.O.Tx("acceptMultipleDirectOfferSoftDapper",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", ids),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     ids[0],
				"seller": otu.O.Address("user1"),
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "active_accepted",
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     ids[1],
				"seller": otu.O.Address("user1"),
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "active_accepted",
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     ids[2],
				"seller": otu.O.Address("user1"),
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "active_accepted",
			})

		otu.O.Tx("fulfillMultipleMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("ids", ids),
			WithArg("amounts", []float64{price, price, price}),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     ids[0],
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "sold",
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     ids[1],
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "sold",
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     ids[2],
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "sold",
			})

	})

	ftIden, err := otu.O.QualifiedIdentifier("FlowUtilityToken", "Vault")
	assert.NoError(t, err)
	t.Run("Should be able to multiple offer to 10 items in one go", func(t *testing.T) {

		number := 10

		ids := otu.mintThreeExampleDandies()

		seller := "user1"

		sellers := []string{seller}
		dandy := []string{dandyNFTType(otu)}
		duc := []string{ftIden}
		prices := []float64{price}

		for len(ids) < number {
			id := otu.mintThreeExampleDandies()
			ids = append(ids, id...)
		}

		ids = ids[:number]

		for len(sellers) < len(ids) {
			sellers = append(sellers, sellers[0])
			dandy = append(dandy, dandy[0])
			duc = append(duc, duc[0])
			prices = append(prices, prices[0])
		}

		otu.O.Tx("bidMultipleMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("users", sellers),
			WithArg("nftAliasOrIdentifiers", dandy),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", duc),
			WithArg("amounts", prices),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)
	})

	t.Run("Should be able to multiple offer to and fulfill 4 items in one go", func(t *testing.T) {

		number := 4

		ids := otu.mintThreeExampleDandies()

		seller := "user1"

		sellers := []string{seller}
		dandy := []string{dandyNFTType(otu)}
		duc := []string{ftIden}
		prices := []float64{price}

		for len(ids) < number {
			id := otu.mintThreeExampleDandies()
			ids = append(ids, id...)
		}

		ids = ids[:number]

		for len(sellers) < len(ids) {
			sellers = append(sellers, sellers[0])
			dandy = append(dandy, dandy[0])
			duc = append(duc, duc[0])
			prices = append(prices, prices[0])
		}

		otu.O.Tx("bidMultipleMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("users", sellers),
			WithArg("nftAliasOrIdentifiers", dandy),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", duc),
			WithArg("amounts", prices),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		otu.O.Tx("acceptMultipleDirectOfferSoftDapper",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", ids),
		).
			AssertSuccess(t)

		otu.O.Tx("fulfillMultipleMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("ids", ids),
			WithArg("amounts", prices),
		).
			AssertSuccess(t)

	})

	t.Run("Should be able to list an NFT for sale and buy it with DUC with multiple direct offer transaction", func(t *testing.T) {

		ftIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
		assert.NoError(t, err)

		saleItemID := otu.O.Tx("bidMultipleMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("users", []string{"user1"}),
			WithArg("nftAliasOrIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("ids", []uint64{0}),
			WithArg("ftAliasOrIdentifiers", []string{ftIden}),
			WithArg("amounts", `[10.0]`),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t).
			GetIdsFromEvent(eventIdentifier, "id")

		otu.O.Tx("acceptMultipleDirectOfferSoftDapper",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", saleItemID),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     saleItemID[0],
				"seller": otu.O.Address("user1"),
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "active_accepted",
			})

		otu.O.Tx("fulfillMultipleMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("ids", saleItemID[:1]),
			WithArg("amounts", []float64{price}),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     saleItemID[0],
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "sold",
			})
		otu.sendExampleNFT("user1", "user2")
	})

	t.Run("Should not be able to make offer on soul bound items", func(t *testing.T) {
		otu.sendSoulBoundNFT("user1", "find")
		// set market rules
		otu.O.Tx("adminSetSellExampleNFTForFUT",
			WithSigner("find"),
			WithArg("tenant", "find"),
		)

		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("nftAliasOrIdentifier", exampleNFTType(otu)),
			WithArg("id", 1),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).AssertFailure(t, "This item is soul bounded and cannot be traded")

	})

	t.Run("not be able to buy an NFT with changed royalties, but should be able to cancel listing", func(t *testing.T) {

		saleItemID := otu.directOfferMarketSoftExampleNFT("user2", "user1", 0, price)

		otu.acceptDirectOfferMarketSoft("user1", saleItemID[0], "user2", price)

		otu.changeRoyaltyExampleNFT("user1", 0, true)

		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("id", saleItemID[0]),
			WithArg("amount", price),
		).
			AssertFailure(t, "The total Royalties to be paid is changed after listing.")

		otu.O.Tx("cancelMarketDirectOfferSoft",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", saleItemID[0:1]),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"status": "cancel_rejected",
			})

	})

	t.Run("should be able to get listings with royalty problems and cancel", func(t *testing.T) {

		saleItemID := otu.directOfferMarketSoftExampleNFT("user2", "user1", 0, price)

		otu.acceptDirectOfferMarketSoft("user1", saleItemID[0], "user2", price)

		otu.changeRoyaltyExampleNFT("user1", 0, false)

		ids, err := otu.O.Script("getRoyaltyChangedIds",
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
		).
			GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.O.Tx("cancelMarketListings",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", ids),
		).
			AssertSuccess(t)

	})

}
