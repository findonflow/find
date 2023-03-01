package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestMarketDirectOfferEscrow(t *testing.T) {
	otu := NewOverflowTest(t)
	price := 10.0

	mintFund := otu.O.TxFN(
		WithSigner("account"),
		WithArg("amount", 10000.0),
		WithArg("recipient", "user2"),
	)

	id := otu.setupMarketAndDandy()
	otu.registerFtInRegistry().
		setFlowDandyMarketOption("DirectOfferEscrow").
		setProfile("user1").
		setProfile("user2")

	mintFund("devMintFusd").AssertSuccess(t)

	mintFund("devMintFlow").AssertSuccess(t)

	mintFund("devMintUsdc").AssertSuccess(t)

	otu.setUUID(600)

	eventIdentifier := otu.identifier("FindMarketDirectOfferEscrow", "DirectOffer")
	royaltyIdentifier := otu.identifier("FindMarket", "RoyaltyPaid")

	bidTx := otu.O.TxFN(
		WithSigner("user2"),
		WithArg("user", "user1"),
		WithArg("nftAliasOrIdentifier", "Dandy"),
		WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("amount", 0.0),
	)

	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to add direct offer and then sell even the seller didn't link provider correctly", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price).
			unlinkDandyProvider("user1").
			acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to add direct offer and then sell even the buyer didn't link receiver correctly", func(t *testing.T) {

		otu.unlinkDandyReceiver("user2").
			directOfferMarketEscrowed("user2", "user1", id, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to offer with price 0", func(t *testing.T) {

		bidTx("bidMarketDirectOfferEscrowed",
			WithArg("amount", 0.0),
			WithArg("validUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Offer price should be greater than 0")

	})

	t.Run("Should not be able to offer with invalid time", func(t *testing.T) {

		bidTx("bidMarketDirectOfferEscrowed",
			WithArg("amount", price),
			WithArg("validUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")

	})

	t.Run("Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			sendDandy("user3", "user1", id)

		otu.setUUID(1000)

		otu.O.Tx("cancelMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t)

		otu.sendDandy("user1", "user3", id)

	})

	t.Run("Should be able to retract offer if the pointer is no longer valid", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			sendDandy("user3", "user1", id)

		otu.setUUID(1200)

		otu.O.Tx("retractOfferMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("id", id),
		).
			AssertSuccess(t)

		otu.sendDandy("user1", "user3", id)

	})

	t.Run("Should be able to increase offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0)

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to reject offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	t.Run("Should be able to retract offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			retractOfferDirectOfferEscrowed("user2", "user1", id)

		otu.cancelAllDirectOfferMarketEscrowed("user1")

	})

	t.Run("Should not be able to offer your own NFT", func(t *testing.T) {

		bidTx("bidMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("validUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "You cannot bid on your own resource")

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to accept expired offers", func(t *testing.T) {

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

		otu.cancelAllDirectOfferMarketEscrowed("user1")

	})

	//return money when outbid

	t.Run("Should return money when outbid", func(t *testing.T) {

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

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	/* Tests on Rules */
	t.Run("Should not be able to direct offer after deprecated", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferEscrow", "deprecate")

		bidTx("bidMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterMarketOption("DirectOfferEscrow", "enable")
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to increase offer if deprecated but able to accept offer", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.alterMarketOption("DirectOfferEscrow", "deprecate")

		otu.O.Tx("increaseBidMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("id", id),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.saleItemListed("user1", "active_ongoing", 10.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 10.0)

		otu.alterMarketOption("DirectOfferEscrow", "enable")

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 10.0)
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to reject offer when deprecated", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferEscrow", "deprecate").
			rejectDirectOfferEscrowed("user1", id, 10.0)
		otu.alterMarketOption("DirectOfferEscrow", "enable")
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to direct offer after stopped", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferEscrow", "stop")

		bidTx("bidMarketDirectOfferEscrowed").
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferEscrow", "enable")
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to increase offer nor buy if stopped", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		otu.alterMarketOption("DirectOfferEscrow", "stop")

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

		otu.alterMarketOption("DirectOfferEscrow", "enable").
			cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to able to direct offer, add bit and accept offer after enabled", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferEscrow", "deprecate").
			alterMarketOption("DirectOfferEscrow", "enable").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0)
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to able to direct offerand reject after enabled", func(t *testing.T) {

		otu.alterMarketOption("DirectOfferEscrow", "deprecate").
			alterMarketOption("DirectOfferEscrow", "enable").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			rejectDirectOfferEscrowed("user1", id, 10.0)
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferEscrow", "deprecate")

		bidTx("bidMarketDirectOfferEscrowed",
			WithSigner("user3"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterMarketOption("DirectOfferEscrow", "stop")

		bidTx("bidMarketDirectOfferEscrowed",
			WithSigner("user3"),
			WithArg("amount", price+10.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferEscrow", "enable").
			cancelAllDirectOfferMarketEscrowed("user1")

	})

	t.Run("Should be able to retract offer when deprecated and stopped", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price).
			alterMarketOption("DirectOfferEscrow", "stop")

		otu.alterMarketOption("DirectOfferEscrow", "deprecate").
			retractOfferDirectOfferEscrowed("user2", "user1", id)

		otu.alterMarketOption("DirectOfferEscrow", "enable")
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon accept offer action", func(t *testing.T) {

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

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

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

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", price)
		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price).
			profileBan("user1")

		// Should not be able to make offer
		bidTx("bidMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("id", ids[1]),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Seller banned by Tenant")

		// Should not be able to accept offer
		otu.O.Tx("fulfillMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("id", ids[0]),
		).
			AssertFailure(t, "Seller banned by Tenant")

		// Should be able to reject offer
		otu.O.Tx("cancelMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("ids", ids[0:0]),
		).
			AssertSuccess(t)

		otu.removeProfileBan("user1").
			cancelAllDirectOfferMarketEscrowed("user1")

	})

	t.Run("Should be able to ban user, user can only retract offer", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price).
			profileBan("user2")

		// Should not be able to make offer
		bidTx("bidMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("id", ids[1]),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Buyer banned by Tenant")

			// Should not be able to accept offer
		otu.O.Tx("fulfillMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("id", ids[0]),
		).
			AssertFailure(t, "Buyer banned by Tenant")

			// Should be able to reject offer
		otu.retractOfferDirectOfferEscrowed("user2", "user1", ids[0])

		otu.removeProfileBan("user2")
		otu.cancelAllDirectOfferMarketEscrowed("user1")

	})

	t.Run("Should be able to offer an NFT and fulfill it with id != uuid", func(t *testing.T) {

		otu.registerDUCInRegistry().
			setDUCExampleNFT().
			sendExampleNFT("user1", "find")

		saleItem := otu.directOfferMarketEscrowedExampleNFT("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price)
		otu.acceptDirectOfferMarketEscrowed("user1", saleItem[0], "user2", price)
		otu.cancelAllDirectOfferMarketEscrowed("user1")

		otu.sendExampleNFT("user1", "user2")

	})

	t.Run("Should be able to direct offer and fulfill multiple NFT in one go", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		ids := otu.mintThreeExampleDandies()

		// seller := "user1"
		name := "user2"

		otu.O.Tx("bidMultipleMarketDirectOfferEscrowed",
			WithSigner(name),
			WithArg("users", `["user1","user1","user1"]`),
			WithArg("nftAliasOrIdentifiers", []string{dandyNFTType(otu), dandyNFTType(otu), dandyNFTType(otu)}),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", `["Flow", "Flow", "Flow"]`),
			WithArg("amounts", `[10.0, 10.0, 10.0]`),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount": price,
				"id":     ids[0],
				"buyer":  otu.O.Address(name),
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount": price,
				"id":     ids[1],
				"buyer":  otu.O.Address(name),
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount": price,
				"id":     ids[2],
				"buyer":  otu.O.Address(name),
			})

		name = "user1"
		buyer := "user2"

		otu.O.Tx("fulfillMultipleMarketDirectOfferEscrowed",
			WithSigner(name),
			WithArg("ids", ids),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     ids[0],
				"seller": otu.O.Address(name),
				"buyer":  otu.O.Address(buyer),
				"amount": price,
				"status": "sold",
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     ids[1],
				"seller": otu.O.Address(name),
				"buyer":  otu.O.Address(buyer),
				"amount": price,
				"status": "sold",
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     ids[2],
				"seller": otu.O.Address(name),
				"buyer":  otu.O.Address(buyer),
				"amount": price,
				"status": "sold",
			})

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to direct offer to 9 items at max in one go", func(t *testing.T) {

		number := 9

		ids := otu.mintThreeExampleDandies()

		seller := "user1"
		name := "user2"

		sellers := []string{seller}
		dandy := []string{dandyNFTType(otu)}
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

		otu.O.Tx("bidMultipleMarketDirectOfferEscrowed",
			WithSigner(name),
			WithArg("users", sellers),
			WithArg("nftAliasOrIdentifiers", dandy),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", flow),
			WithArg("amounts", prices),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should be able to fulfill 4 items at max in one go", func(t *testing.T) {

		number := 4

		ids := otu.mintThreeExampleDandies()

		seller := "user1"
		name := "user2"

		sellers := []string{seller}
		dandy := []string{dandyNFTType(otu)}
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

		otu.O.Tx("bidMultipleMarketDirectOfferEscrowed",
			WithSigner(name),
			WithArg("users", sellers),
			WithArg("nftAliasOrIdentifiers", dandy),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", flow),
			WithArg("amounts", prices),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		name = "user1"

		otu.O.Tx("fulfillMultipleMarketDirectOfferEscrowed",
			WithSigner(name),
			WithArg("ids", ids),
		).
			AssertSuccess(t)

		otu.cancelAllDirectOfferMarketEscrowed("user1")
	})

	t.Run("Should not be able to make offer on soul bound items", func(t *testing.T) {
		otu.sendSoulBoundNFT("user1", "find")
		// set market rules
		otu.O.Tx("adminSetSellExampleNFTForFlow",
			WithSigner("find"),
			WithArg("tenant", "find"),
		)

		otu.O.Tx("bidMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("nftAliasOrIdentifier", exampleNFTType(otu)),
			WithArg("id", 1),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).AssertFailure(t, "This item is soul bounded and cannot be traded")

	})

	t.Run("not be able to buy an NFT with changed royalties, but should be able to cancel listing", func(t *testing.T) {

		saleItem := otu.directOfferMarketEscrowedExampleNFT("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price)

		otu.changeRoyaltyExampleNFT("user1", 0, true)

		otu.O.Tx("fulfillMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("id", saleItem[0]),
		).
			AssertFailure(t, "The total Royalties to be paid is changed after listing.")

		otu.O.Tx("cancelMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("ids", saleItem[0:1]),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"status": "rejected",
			})
	})

	t.Run("should be able to get listings with royalty problems and cancel", func(t *testing.T) {

		otu.directOfferMarketEscrowedExampleNFT("user2", "user1", 0, price)

		otu.saleItemListed("user1", "active_ongoing", price)

		otu.changeRoyaltyExampleNFT("user1", 0, false)

		ids, err := otu.O.Script("getRoyaltyChangedIds",
			WithArg("user", "user1"),
		).
			GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.O.Tx("cancelMarketListings",
			WithSigner("user1"),
			WithArg("ids", ids),
		).
			AssertSuccess(t)
	})

}
