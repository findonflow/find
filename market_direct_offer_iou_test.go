package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
)

func TestMarketDirectOfferIOU(t *testing.T) {
	otu := NewOverflowTest(t)
	price := 10.0

	mintFund := otu.O.TxFN(
		WithSigner("account"),
		WithArg("amount", 10000.0),
		WithArg("recipient", "user2"),
	)

	id := otu.setupMarketAndDandy()
	otu.registerFtInRegistry().
		setFlowDandyMarketOption("DirectOffer").
		setProfile("user1").
		setProfile("user2")

	mintFund("testMintFusd").AssertSuccess(t)

	mintFund("testMintFlow").AssertSuccess(t)

	mintFund("testMintUsdc").AssertSuccess(t)

	otu.setUUID(400)

	bidTx := otu.O.TxFN(
		WithSigner("user2"),
		WithArg("marketplace", "account"),
		WithArg("user", "user1"),
		WithArg("nftAliasOrIdentifier", "Dandy"),
		WithArg("nftAliasOrIdentifier", "A.f8d6e0586b0a20c7.Dandy.NFT"),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("amount", 0.0),
	)

	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketIOU("user1", id, "user2", price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should be able to add direct offer and then sell even the seller didn't link provider correctly", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price).
			unlinkDandyProvider("user1").
			acceptDirectOfferMarketIOU("user1", id, "user2", price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should be able to add direct offer and then sell even the buyer didn't link receiver correctly", func(t *testing.T) {

		otu.unlinkDandyReceiver("user2").
			directOfferMarketIOU("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketIOU("user1", id, "user2", price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should be able to add direct offer and then sell even the buyer is without collection", func(t *testing.T) {

		otu.destroyDandyCollection("user2").
			directOfferMarketIOU("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketIOU("user1", id, "user2", price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should not be able to offer with price 0", func(t *testing.T) {

		bidTx("bidMarketDirectOfferIOU",
			WithArg("amount", 0.0),
			WithArg("validUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Offer price should be greater than 0")

	})

	t.Run("Should not be able to offer with invalid time", func(t *testing.T) {

		bidTx("bidMarketDirectOfferIOU",
			WithArg("amount", price),
			WithArg("validUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")

	})

	t.Run("Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			sendDandy("user3", "user1", id)

		otu.setUUID(600)

		otu.O.Tx("cancelMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t)

		otu.sendDandy("user1", "user3", id)

	})

	t.Run("Should be able to retract offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			sendDandy("user3", "user1", id)

		otu.setUUID(900)

		otu.O.Tx("retractOfferMarketDirectOfferIOU",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
		).
			AssertSuccess(t)

		otu.sendDandy("user1", "user3", id)

	})

	t.Run("Should be able to increase offer", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketIOU("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			acceptDirectOfferMarketIOU("user1", id, "user2", 15.0)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0)

		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should be able to reject offer", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferIOU("user1", id, 10.0)
	})

	t.Run("Should be able to retract offer", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			retractOfferDirectOfferIOU("user2", "user1", id)

		otu.cancelAllDirectOfferMarketIOU("user1")

	})

	t.Run("Should not be able to offer your own NFT", func(t *testing.T) {

		bidTx("bidMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("validUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "You cannot bid on your own resource")

		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should not be able to accept expired offers", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketIOU("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			tickClock(200.0)

		otu.O.Tx("fulfillMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
		).
			AssertFailure(t, "This direct offer is already expired")

		otu.cancelAllDirectOfferMarketIOU("user1")

	})

	//return money when outbid

	t.Run("Should return money when outbid", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)
		newPrice := 11.0

		bidTx("bidMarketDirectOfferIOU",
			WithSigner("user3"),
			WithArg("amount", newPrice),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketDirectOfferIOU.DirectOffer", map[string]interface{}{
				"amount":        newPrice,
				"id":            id,
				"previousBuyer": otu.O.Address("user2"),
			}).
			AssertEvent(t, "A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
				"amount": price,
				"to":     otu.O.Address("user2"),
			})

		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	/* Tests on Rules */
	t.Run("Should not be able to direct offer after deprecated", func(t *testing.T) {

		otu.alterMarketOption("DirectOffer", "deprecate")

		bidTx("bidMarketDirectOfferIOU",
			WithSigner("user2"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterMarketOption("DirectOffer", "enable")
		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should not be able to increase offer if deprecated but able to accept offer", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.alterMarketOption("DirectOffer", "deprecate")

		otu.O.Tx("increaseBidMarketDirectOfferIOU",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.saleItemListed("user1", "active_ongoing", 10.0).
			acceptDirectOfferMarketIOU("user1", id, "user2", 10.0)

		otu.alterMarketOption("DirectOffer", "enable")

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 10.0)
		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should be able to reject offer when deprecated", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOffer", "deprecate").
			rejectDirectOfferIOU("user1", id, 10.0)
		otu.alterMarketOption("DirectOffer", "enable")
		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should not be able to direct offer after stopped", func(t *testing.T) {

		otu.alterMarketOption("DirectOffer", "stop")

		bidTx("bidMarketDirectOfferIOU").
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("DirectOffer", "enable")
		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should not be able to increase offer nor buy if stopped", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.alterMarketOption("DirectOffer", "stop")

		otu.O.Tx("increaseBidMarketDirectOfferIOU",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.saleItemListed("user1", "active_ongoing", 10.0)

		otu.O.Tx("fulfillMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("DirectOffer", "enable").
			cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should be able to able to direct offer, add bit and accept offer after enabled", func(t *testing.T) {

		otu.alterMarketOption("DirectOffer", "deprecate").
			alterMarketOption("DirectOffer", "enable").
			directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketIOU("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			acceptDirectOfferMarketIOU("user1", id, "user2", 15.0)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0)
		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should be able to able to direct offerand reject after enabled", func(t *testing.T) {

		otu.alterMarketOption("DirectOffer", "deprecate").
			alterMarketOption("DirectOffer", "enable").
			directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferIOU("user1", id, 10.0)
		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOffer", "deprecate")

		bidTx("bidMarketDirectOfferIOU",
			WithSigner("user3"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterMarketOption("DirectOffer", "stop")

		bidTx("bidMarketDirectOfferIOU",
			WithSigner("user3"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("DirectOffer", "enable").
			cancelAllDirectOfferMarketIOU("user1")

	})

	t.Run("Should be able to retract offer when deprecated and stopped", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOffer", "stop")

		otu.alterMarketOption("DirectOffer", "deprecate").
			retractOfferDirectOfferIOU("user2", "user1", id)

		otu.alterMarketOption("DirectOffer", "enable")
		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon accept offer action", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.O.Tx("fulfillMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "find",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "find",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "find",
			})

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)
		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			setFindCut(0.035)

		otu.O.Tx("fulfillMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.35,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "find",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "find",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "find",
			})

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)
		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.directOfferMarketIOU("user2", "user1", ids[0], price).
			profileBan("user1")

		// Should not be able to make offer
		bidTx("bidMarketDirectOfferIOU",
			WithSigner("user2"),
			WithArg("id", ids[1]),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Seller banned by Tenant")

		// Should not be able to accept offer
		otu.O.Tx("fulfillMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("id", ids[0]),
		).
			AssertFailure(t, "Seller banned by Tenant")

		// Should be able to reject offer
		otu.O.Tx("cancelMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("ids", ids[0:0]),
		).
			AssertSuccess(t)

		otu.removeProfileBan("user1").
			cancelAllDirectOfferMarketIOU("user1")

	})

	t.Run("Should be able to ban user, user can only retract offer", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.directOfferMarketIOU("user2", "user1", ids[0], price).
			profileBan("user2")

		// Should not be able to make offer
		bidTx("bidMarketDirectOfferIOU",
			WithSigner("user2"),
			WithArg("id", ids[1]),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Buyer banned by Tenant")

			// Should not be able to accept offer
		otu.O.Tx("fulfillMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("id", ids[0]),
		).
			AssertFailure(t, "Buyer banned by Tenant")

			// Should be able to reject offer
		otu.retractOfferDirectOfferIOU("user2", "user1", ids[0])

		otu.removeProfileBan("user2")
		otu.cancelAllDirectOfferMarketIOU("user1")

	})

	t.Run("Should be able to offer an NFT and fulfill it with id != uuid", func(t *testing.T) {

		otu.registerDUCInRegistry().
			setDUCExampleNFT().
			sendExampleNFT("user1", "account")

		saleItem := otu.directOfferMarketIOUExampleNFT("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketIOU("user1", saleItem[0], "user2", price)
		otu.cancelAllDirectOfferMarketIOU("user1")

		otu.sendExampleNFT("user1", "user2")

	})

	t.Run("Should be able to list an NFT for auction and bid it with DUC", func(t *testing.T) {

		otu.O.Tx("adminInitDUC",
			WithSigner("account"),
			WithArg("dapperAddress", "account"),
		).AssertSuccess(t)

		saleItemID := otu.directOfferMarketIOUDUC("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketIOUDUC("user1", saleItemID[0], "user2", price)

		otu.sendExampleNFT("user1", "user2")
	})

	t.Run("Should return fund in IOU for DUC bids when cancelled", func(t *testing.T) {

		saleItemID := otu.directOfferMarketIOUDUC("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price)

		ducIOUId, err := otu.O.Tx("cancelMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("ids", saleItemID),
		).
			AssertSuccess(t).
			GetIdFromEvent("A.f8d6e0586b0a20c7.FindIOU.IOUDesposited", "uuid")

		assert.NoError(t, err)

		otu.O.Tx("redeemDapperIOU",
			WithSigner("user2"),
			WithPayloadSigner("account"),
			WithArg("id", ducIOUId),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOURedeemed", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.DapperUtilityCoin.Vault",
				"amount": price,
			})
	})

	t.Run("Should return fund in IOU for DUC bids when retracted", func(t *testing.T) {

		saleItemID := otu.directOfferMarketIOUDUC("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price)

		ducIOUId, err := otu.O.Tx("retractOfferMarketDirectOfferIOU",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", saleItemID[0]),
		).
			AssertSuccess(t).
			GetIdFromEvent("A.f8d6e0586b0a20c7.FindIOU.IOUDesposited", "uuid")

		assert.NoError(t, err)

		otu.O.Tx("redeemDapperIOU",
			WithSigner("user2"),
			WithPayloadSigner("account"),
			WithArg("id", ducIOUId),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOURedeemed", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.DapperUtilityCoin.Vault",
				"amount": price,
			})
	})

	t.Run("Should be able to direct offer and fulfill multiple NFT in one go", func(t *testing.T) {

		otu.directOfferMarketIOU("user2", "user1", id, price)

		ids := otu.mintThreeExampleDandies()

		// seller := "user1"
		name := "user2"

		otu.O.Tx("bidMultipleMarketDirectOfferIOU",
			WithSigner(name),
			WithArg("marketplace", "account"),
			WithArg("users", `["user1","user1","user1"]`),
			WithArg("nftAliasOrIdentifiers", `["A.f8d6e0586b0a20c7.Dandy.NFT", "A.f8d6e0586b0a20c7.Dandy.NFT", "A.f8d6e0586b0a20c7.Dandy.NFT"]`),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", `["Flow", "Flow", "Flow"]`),
			WithArg("amounts", `[10.0, 10.0, 10.0]`),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketDirectOfferIOU.DirectOffer", map[string]interface{}{
				"amount": price,
				"id":     ids[0],
				"buyer":  otu.O.Address(name),
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketDirectOfferIOU.DirectOffer", map[string]interface{}{
				"amount": price,
				"id":     ids[1],
				"buyer":  otu.O.Address(name),
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketDirectOfferIOU.DirectOffer", map[string]interface{}{
				"amount": price,
				"id":     ids[2],
				"buyer":  otu.O.Address(name),
			})

		name = "user1"
		buyer := "user2"

		otu.O.Tx("fulfillMultipleMarketDirectOfferIOU",
			WithSigner(name),
			WithArg("marketplace", "account"),
			WithArg("ids", ids),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketDirectOfferIOU.DirectOffer", map[string]interface{}{
				"id":     ids[0],
				"seller": otu.O.Address(name),
				"buyer":  otu.O.Address(buyer),
				"amount": price,
				"status": "sold",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketDirectOfferIOU.DirectOffer", map[string]interface{}{
				"id":     ids[1],
				"seller": otu.O.Address(name),
				"buyer":  otu.O.Address(buyer),
				"amount": price,
				"status": "sold",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketDirectOfferIOU.DirectOffer", map[string]interface{}{
				"id":     ids[2],
				"seller": otu.O.Address(name),
				"buyer":  otu.O.Address(buyer),
				"amount": price,
				"status": "sold",
			})

		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should be able to direct offer to 9 items at max in one go", func(t *testing.T) {

		number := 9

		ids := otu.mintThreeExampleDandies()

		seller := "user1"
		name := "user2"

		sellers := []string{seller}
		dandy := []string{"A.f8d6e0586b0a20c7.Dandy.NFT"}
		flow := []string{"Flow"}
		prices := "[" + "10.0"

		for len(ids) < number {
			id := otu.mintThreeExampleDandies()
			ids = append(ids, id...)
		}

		for len(sellers) < len(ids) {
			sellers = append(sellers, sellers[0])
			dandy = append(dandy, dandy[0])
			flow = append(flow, flow[0])
			prices = prices + ", 10.0"
		}

		prices = prices + "]"

		otu.O.Tx("bidMultipleMarketDirectOfferIOU",
			WithSigner(name),
			WithArg("marketplace", "account"),
			WithArg("users", sellers),
			WithArg("nftAliasOrIdentifiers", dandy),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", flow),
			WithArg("amounts", prices),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should be able to fulfill 4 items at max in one go", func(t *testing.T) {

		number := 4

		ids := otu.mintThreeExampleDandies()

		seller := "user1"
		name := "user2"

		sellers := []string{seller}
		dandy := []string{"A.f8d6e0586b0a20c7.Dandy.NFT"}
		flow := []string{"Flow"}
		prices := "[ 10.0 "

		for len(ids) < number {
			id := otu.mintThreeExampleDandies()
			ids = append(ids, id...)
		}

		ids = ids[:number]

		for len(sellers) < len(ids) {
			sellers = append(sellers, sellers[0])
			dandy = append(dandy, dandy[0])
			flow = append(flow, flow[0])
			prices = prices + ", 10.0"
		}

		prices = prices + "]"

		otu.O.Tx("bidMultipleMarketDirectOfferIOU",
			WithSigner(name),
			WithArg("marketplace", "account"),
			WithArg("users", sellers),
			WithArg("nftAliasOrIdentifiers", dandy),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", flow),
			WithArg("amounts", prices),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		name = "user1"

		otu.O.Tx("fulfillMultipleMarketDirectOfferIOU",
			WithSigner(name),
			WithArg("marketplace", "account"),
			WithArg("ids", ids),
		).
			AssertSuccess(t)

		otu.cancelAllDirectOfferMarketIOU("user1")
	})

	t.Run("Should not be able to make offer on soul bound items", func(t *testing.T) {
		otu.sendSoulBoundNFT("user1", "account")
		// set market rules
		otu.O.Tx("adminSetSellExampleNFTForFlow",
			overflow.WithSigner("find"),
			overflow.WithArg("tenant", "account"),
		)

		otu.O.Tx("bidMarketDirectOfferIOU",
			overflow.WithSigner("user2"),
			overflow.WithArg("marketplace", "account"),
			overflow.WithArg("user", "user1"),
			overflow.WithArg("nftAliasOrIdentifier", "A.f8d6e0586b0a20c7.ExampleNFT.NFT"),
			overflow.WithArg("id", 1),
			overflow.WithArg("ftAliasOrIdentifier", "Flow"),
			overflow.WithArg("amount", price),
			overflow.WithArg("validUntil", otu.currentTime()+100.0),
		).AssertFailure(t, "This item is soul bounded and cannot be traded")

	})

	t.Run("not be able to buy an NFT with changed royalties, but should be able to cancel listing", func(t *testing.T) {

		saleItem := otu.directOfferMarketIOUExampleNFT("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price)

		otu.changeRoyaltyExampleNFT("user1", 0)

		otu.O.Tx("fulfillMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("id", saleItem[0]),
		).
			AssertFailure(t, "The total Royalties to be paid is changed after listing.")

		otu.O.Tx("cancelMarketDirectOfferIOU",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("ids", saleItem[0:1]),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketDirectOfferIOU.DirectOffer", map[string]interface{}{
				"status": "rejected",
			})
	})

	t.Run("should be able to get listings with royalty problems and cancel", func(t *testing.T) {

		otu.directOfferMarketIOUExampleNFT("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price)

		otu.changeRoyaltyExampleNFT("user1", 0)

		ids, err := otu.O.Script("getRoyaltyChangedIds",
			WithArg("marketplace", "account"),
			WithArg("user", "user1"),
		).
			GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.O.Tx("cancelMarketListings",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("ids", ids),
		).
			AssertSuccess(t)
	})

}
