package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
	. "github.com/bjartek/overflow"
)

func TestMarketDirectOfferSoft(t *testing.T) {
	otu := NewOverflowTest(t)

	mintFund := otu.O.TxFN(
		WithSigner("account"),
		WithArg("amount", 10000.0),
		WithArg("recipient", "user2"),
	)

	id := otu.setupMarketAndDandy()
	otu.registerFtInRegistry().
		setFlowDandyMarketOption("DirectOfferSoft").
		setProfile("user1").
		setProfile("user2")
	price := 10.0

	mintFund("testMintFusd").AssertSuccess(t)

	mintFund("testMintFlow").AssertSuccess(t)

	mintFund("testMintUsdc").AssertSuccess(t)

	otu.setUUID(300)

	bidTx := otu.O.TxFN(
		WithSigner("user2"),
		WithArg("marketplace", "account"),
		WithArg("user", "user1"),
		WithArg("nftAliasOrIdentifier", "Dandy"),
		WithArg("nftAliasOrIdentifier", "A.f8d6e0586b0a20c7.Dandy.NFT"),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("amount", 0.0),
		WithArg("validUntil", otu.currentTime()+10.0),
	)

	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price).
			saleItemListed("user1", "active_finished", price).
			fulfillMarketDirectOfferSoft("user2", id, price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)
	})

	t.Run("Should be able to add direct offer and then sell even the buyer is without collection", func(t *testing.T) {

		otu.destroyDandyCollection("user2").
			directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price).
			saleItemListed("user1", "active_finished", price).
			fulfillMarketDirectOfferSoft("user2", id, price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)
	})

	t.Run("Should not be able to offer with price 0", func(t *testing.T) {

		// otu.O.Tx(
		// 	"bidMarketDirectOfferSoft",
		// 	WithSigner("user2"),
		// 	WithArg("marketplace", "account"),
		// 	WithArg("user", "user1"),
		// 	WithArg("nftAliasOrIdentifier", "Dandy"),
		// 	WithArg("nftAliasOrIdentifier", "A.f8d6e0586b0a20c7.Dandy.NFT"),
		// 	WithArg("id", id),
		// 	WithArg("ftAliasOrIdentifier", "Flow"),
		// 	WithArg("amount", 0.0),
		// 	WithArg("validUntil", otu.currentTime()+10.0),
		// ).
		// 	AssertFailure(t, "Offer price should be greater than 0")

		bidTx("bidMarketDirectOfferSoft",
			WithArg("amount", 0.0),
		).
			AssertFailure(t, "Offer price should be greater than 0")

	})

	t.Run("Should not be able to offer with invalid time", func(t *testing.T) {

		// otu.O.Tx(
		// 	"bidMarketDirectOfferSoft",
		// 	WithSigner("user2"),
		// 	WithArg("marketplace", "account"),
		// 	WithArg("user", "user1"),
		// 	WithArg("nftAliasOrIdentifier", "A.f8d6e0586b0a20c7.Dandy.NFT"),
		// 	WithArg("id", id),
		// 	WithArg("ftAliasOrIdentifier", "Flow"),
		// 	WithArg("amount", price),
		// 	WithArg("validUntil", 0.0),
		// ).
		// 	AssertFailure(t, "Valid until is before current time")

		bidTx("bidMarketDirectOfferSoft",
			WithArg("amount", price),
			WithArg("validUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")

	})

	t.Run("Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			sendDandy("user2", "user1", id)

		otu.setUUID(600)

		// otu.O.TransactionFromFile("cancelMarketDirectOfferSoft").
		// 	SignProposeAndPayAs("user1").
		// 	Args(otu.O.Arguments().
		// 		Account("account").
		// 		UInt64Array(id)).
		// 	Test(otu.T).
		// 	AssertSuccess()

		otu.O.Tx("cancelMarketDirectOfferSoft",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t)

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should be able to retract offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			sendDandy("user2", "user1", id)

		otu.setUUID(900)

		// otu.O.TransactionFromFile("retractOfferMarketDirectOfferSoft").
		// 	SignProposeAndPayAs("user2").
		// 	Args(otu.O.Arguments().
		// 		Account("account").
		// 		UInt64(id)).
		// 	Test(otu.T).
		// 	AssertSuccess()

		otu.O.Tx("retractOfferMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
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

		// otu.O.TransactionFromFile("bidMarketDirectOfferSoft").
		// 	SignProposeAndPayAs("user1").
		// 	Args(otu.O.Arguments().
		// 		Account("account").
		// 		String("user1").
		// 		String("A.f8d6e0586b0a20c7.Dandy.NFT").
		// 		UInt64(id).
		// 		String("Flow").
		// 		UFix64(price).
		// 		UFix64(otu.currentTime() + 100.0)).
		// 	Test(otu.T).AssertFailure("You cannot bid on your own resource")

		bidTx("bidMarketDirectOfferSoft",
			WithSigner("user1"),
			WithArg("validUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "You cannot bid on your own resource")

	})

	t.Run("Should not be able to accept expired offer", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			tickClock(200.0)

			// otu.O.TransactionFromFile("acceptDirectOfferSoft").
			// 	SignProposeAndPayAs("user1").
			// 	Args(otu.O.Arguments().
			// 		Account("account").
			// 		UInt64(id)).
			// 	Test(otu.T).AssertFailure("This direct offer is already expired")

		otu.O.Tx("acceptDirectOfferSoft",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
		).
			AssertFailure(t, "This direct offer is already expired")

		otu.cancelAllDirectOfferMarketSoft("user1")

	})

	t.Run("Should not be able to add direct offer when deprecated", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferSoft", "deprecate")

		// otu.O.TransactionFromFile("bidMarketDirectOfferSoft").
		// 	SignProposeAndPayAs("user2").
		// 	Args(otu.O.Arguments().
		// 		Account("account").
		// 		String("user1").
		// 		String("A.f8d6e0586b0a20c7.Dandy.NFT").
		// 		UInt64(id).
		// 		String("Flow").
		// 		UFix64(price).
		// 		UFix64(otu.currentTime() + 100.0)).
		// 	Test(otu.T).
		// 	AssertFailure("Tenant has deprected mutation options on this item")

		bidTx("bidMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterMarketOption("DirectOfferSoft", "enable")
	})

	t.Run("Should not be able to increase bid but able to fulfill offer when deprecated", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferSoft", "deprecate")

		// otu.O.TransactionFromFile("increaseBidMarketDirectOfferSoft").
		// 	SignProposeAndPayAs("user2").
		// 	Args(otu.O.Arguments().
		// 		Account("account").
		// 		UInt64(id).
		// 		UFix64(price)).
		// 	Test(otu.T).
		// 	AssertFailure("Tenant has deprected mutation options on this item")

		otu.O.Tx("increaseBidMarketDirectOfferSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.acceptDirectOfferMarketSoft("user1", id, "user2", price).
			saleItemListed("user1", "active_finished", price).
			fulfillMarketDirectOfferSoft("user2", id, price)

		otu.alterMarketOption("DirectOfferSoft", "enable").
			sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

	})

	t.Run("Should be able to reject offer when deprecated", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferSoft", "deprecate").
			rejectDirectOfferSoft("user1", id, 10.0)

		otu.alterMarketOption("DirectOfferSoft", "enable")
	})

	t.Run("Should not be able to add direct offer after stopped", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("bidMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferSoft", "enable")
	})

	t.Run("Should not be able to increase bid nor accept offer after stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("increaseBidMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.O.TransactionFromFile("acceptDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferSoft", "enable").
			cancelAllDirectOfferMarketSoft("user1")
	})

	t.Run("Should not be able to fulfill offer after stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price).
			saleItemListed("user1", "active_finished", price).
			alterMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("fulfillMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

			/* Reset */
		otu.alterMarketOption("DirectOfferSoft", "enable")
		otu.O.TransactionFromFile("fulfillMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()
		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

	})

	t.Run("Should not be able to reject offer after stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("cancelMarketDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferSoft", "enable").
			cancelAllDirectOfferMarketSoft("user1")
	})

	t.Run("Should be able to direct offer, increase offer and fulfill offer after enabled", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferSoft", "stop").
			alterMarketOption("DirectOfferSoft", "enable").
			directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price).
			saleItemListed("user1", "active_finished", price).
			fulfillMarketDirectOfferSoft("user2", id, price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)
	})

	t.Run("Should be able to reject offer after enabled", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferSoft", "stop").
			alterMarketOption("DirectOfferSoft", "enable").
			directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferSoft("user1", id, 10.0)
	})

	t.Run("Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferSoft", "deprecate")

		otu.O.TransactionFromFile("bidMarketDirectOfferSoft").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(id).
				String("Flow").
				UFix64(price + 10.0).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.alterMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("bidMarketDirectOfferSoft").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(id).
				String("Flow").
				UFix64(price + 10.0).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferSoft", "enable").
			cancelAllDirectOfferMarketSoft("user1")
	})

	t.Run("Should be able to retract offer when deprecated , but not when stopped", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.alterMarketOption("DirectOfferSoft", "stop")

		otu.O.TransactionFromFile("retractOfferMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferSoft", "deprecate").
			retractOfferDirectOfferSoft("user2", "user1", id)

		otu.alterMarketOption("DirectOfferSoft", "enable").
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

		otu.O.TransactionFromFile("fulfillMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "find",
			})).
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "find",
			}))

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		price = 10.0

		otu.directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price).
			setFindCut(0.035)

		otu.O.TransactionFromFile("fulfillMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.35,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "find",
			})).
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "find",
			}))

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.directOfferMarketSoft("user2", "user1", ids[0], price).
			directOfferMarketSoft("user2", "user1", ids[1], price).
			acceptDirectOfferMarketSoft("user1", ids[0], "user2", price).
			profileBan("user1")

		otu.O.TransactionFromFile("bidMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[2]).
				String("Flow").
				UFix64(price).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		// Should not be able to accept offer
		otu.O.TransactionFromFile("acceptDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(ids[1])).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		// Should not be able to fulfill offer
		otu.O.TransactionFromFile("fulfillMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(ids[0]).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		//Should be able to cancel(reject) offer
		otu.O.TransactionFromFile("cancelMarketDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(ids[1])).
			Test(otu.T).
			AssertSuccess()

		otu.removeProfileBan("user1").
			cancelAllDirectOfferMarketSoft("user1")

	})

	t.Run("Should be able to ban user, user can only retract offer", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.directOfferMarketSoft("user2", "user1", ids[0], price).
			directOfferMarketSoft("user2", "user1", ids[1], price).
			acceptDirectOfferMarketSoft("user1", ids[0], "user2", price).
			profileBan("user2")

		otu.O.TransactionFromFile("bidMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[2]).
				String("Flow").
				UFix64(price).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

		// Should not be able to accept offer
		otu.O.TransactionFromFile("acceptDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(ids[1])).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

		// Should not be able to fulfill offer
		otu.O.TransactionFromFile("fulfillMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(ids[0]).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

		//Should be able to retract offer
		otu.retractOfferDirectOfferSoft("user2", "user1", ids[1])

		otu.removeProfileBan("user2").
			cancelAllDirectOfferMarketSoft("user1")

	})

	t.Run("Should return money when outbid", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)

		newPrice := 11.0
		otu.O.TransactionFromFile("bidMarketDirectOfferSoft").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(id).
				String("Flow").
				UFix64(newPrice).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"amount":        newPrice,
				"id":            id,
				"buyer":         otu.O.Address("user3"),
				"previousBuyer": otu.O.Address("user2"),
				"status":        "active_offered",
			}))

		otu.sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferMarketSoft("user1")
	})

	t.Run("Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {

		otu.registerDUCInRegistry().
			setDUCExampleNFT().
			sendExampleNFT("user1", "account")

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

		// otu.directOfferMarketSoft("user2", "user1", id, price).

		otu.O.TransactionFromFile("bidMultipleMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				StringArray("user1", "user1", "user1").
				StringArray("A.f8d6e0586b0a20c7.Dandy.NFT", "A.f8d6e0586b0a20c7.Dandy.NFT", "A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64Array(ids...).
				StringArray("Flow", "Flow", "Flow").
				UFix64Array(price, price, price).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"amount": price,
				"id":     ids[0],
				"buyer":  otu.O.Address("user2"),
			})).
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"amount": price,
				"id":     ids[1],
				"buyer":  otu.O.Address("user2"),
			})).
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"amount": price,
				"id":     ids[2],
				"buyer":  otu.O.Address("user2"),
			}))

		otu.O.TransactionFromFile("acceptMultipleDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(ids...)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"id":     ids[0],
				"seller": otu.O.Address("user1"),
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "active_accepted",
			})).
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"id":     ids[1],
				"seller": otu.O.Address("user1"),
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "active_accepted",
			})).
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"id":     ids[2],
				"seller": otu.O.Address("user1"),
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "active_accepted",
			}))

		otu.O.TransactionFromFile("fulfillMultipleMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(ids...).
				UFix64Array(price, price, price)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"id":     ids[0],
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "sold",
			})).
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"id":     ids[1],
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "sold",
			})).
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"id":     ids[2],
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "sold",
			}))

		otu.sendFT("user1", "user2", "Flow", price*3)
	})

	t.Run("Should be able to multiple offer to 10 items in one go", func(t *testing.T) {

		number := 10

		ids := otu.mintThreeExampleDandies()

		seller := "user1"

		sellers := []string{seller}
		dandy := []string{"A.f8d6e0586b0a20c7.Dandy.NFT"}
		flow := []string{"Flow"}
		prices := []float64{price}

		for len(ids) < number {
			id := otu.mintThreeExampleDandies()
			ids = append(ids, id...)
		}

		ids = ids[:number]

		for len(sellers) < len(ids) {
			sellers = append(sellers, sellers[0])
			dandy = append(dandy, dandy[0])
			flow = append(flow, flow[0])
			prices = append(prices, prices[0])
		}

		otu.O.TransactionFromFile("bidMultipleMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				StringArray(sellers...).
				StringArray(dandy...).
				UInt64Array(ids...).
				StringArray(flow...).
				UFix64Array(prices...).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess()
	})

	t.Run("Should be able to multiple offer to and fulfill 4 items in one go", func(t *testing.T) {

		otu.O.TransactionFromFile("testMintFusd").
			SignProposeAndPayAsService().
			Args(otu.O.Arguments().
				Account("user2").
				UFix64(1000.0)).
			Test(otu.T).
			AssertSuccess()

		number := 4

		ids := otu.mintThreeExampleDandies()

		seller := "user1"

		sellers := []string{seller}
		dandy := []string{"A.f8d6e0586b0a20c7.Dandy.NFT"}
		flow := []string{"Flow"}
		prices := []float64{price}

		for len(ids) < number {
			id := otu.mintThreeExampleDandies()
			ids = append(ids, id...)
		}

		ids = ids[:number]

		for len(sellers) < len(ids) {
			sellers = append(sellers, sellers[0])
			dandy = append(dandy, dandy[0])
			flow = append(flow, flow[0])
			prices = append(prices, prices[0])
		}

		otu.O.TransactionFromFile("bidMultipleMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				StringArray(sellers...).
				StringArray(dandy...).
				UInt64Array(ids...).
				StringArray(flow...).
				UFix64Array(prices...).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess()

		otu.O.TransactionFromFile("acceptMultipleDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(ids...)).
			Test(otu.T).AssertSuccess()

		otu.O.TransactionFromFile("fulfillMultipleMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(ids...).
				UFix64Array(prices...)).
			Test(otu.T).AssertSuccess()

	})

	t.Run("Should be able to list an NFT for sale and buy it with DUC with multiple direct offer transaction", func(t *testing.T) {

		// saleItemID := otu.directOfferMarketSoftDUC("user2", "user1", 0, price)

		res := otu.O.TransactionFromFile("bidMultipleMarketDirectOfferSoftDUC").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				Account("account").
				StringArray("user1").
				StringArray("A.f8d6e0586b0a20c7.ExampleNFT.NFT").
				UInt64Array(0).
				UFix64Array(price).
				UFix64(otu.currentTime() + 100.0)).
			Test(otu.T).AssertSuccess()

		saleItemID := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", "id")

		// otu.acceptDirectOfferMarketSoftDUC("user1", saleItemID[0], "user2", price).

		otu.O.TransactionFromFile("acceptMultipleDirectOfferSoftDUC").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				Account("account").
				UInt64Array(saleItemID[0])).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"id":     saleItemID[0],
				"seller": otu.O.Address("user1"),
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "active_accepted",
			}))

		otu.O.TransactionFromFile("fulfillMultipleMarketDirectOfferSoftDUC").
			SignProposeAndPayAs("user2").PayloadSigner("account").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(saleItemID[0]).
				UFix64Array(price)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
				"id":     saleItemID[0],
				"buyer":  otu.O.Address("user2"),
				"amount": price,
				"status": "sold",
			}))

	})

	t.Run("Should not be able to make offer on soul bound items", func(t *testing.T) {
		otu.sendSoulBoundNFT("user1", "account")
		// set market rules
		otu.O.Tx("adminSetSellExampleNFTForFlow",
			overflow.WithSigner("find"),
			overflow.WithArg("tenant", "account"),
		)

		otu.O.Tx("bidMarketDirectOfferSoft",
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

}
