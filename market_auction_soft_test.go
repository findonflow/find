package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestMarketAuctionSoft(t *testing.T) {

	otu := NewOverflowTest(t)

	mintFund := otu.O.TxFN(
		WithSigner("account"),
		WithArg("amount", 10000.0),
		WithArg("recipient", "user2"),
	)

	price := 10.0
	preIncrement := 5.0
	id := otu.setupMarketAndDandy()
	otu.registerFtInRegistry().
		setFlowDandyMarketOption("AuctionSoft").
		setProfile("user1").
		setProfile("user2")

	mintFund("testMintFusd").AssertSuccess(t)

	mintFund("testMintFlow").AssertSuccess(t)

	mintFund("testMintUsdc").AssertSuccess(t)

	otu.setUUID(300)

	listingTx := otu.O.TxFN(
		WithSigner("user1"),
		WithArg("marketplace", "account"),
		WithArg("nftAliasOrIdentifier", "A.f8d6e0586b0a20c7.Dandy.NFT"),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
	)

	t.Run("Should not be able to list an item for auction twice, and will give error message.", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		listingTx("listNFTForAuctionSoft",
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Auction listing for this item is already created.")

		otu.delistAllNFTForSoftAuction("user1")
	})

	t.Run("Should be able to sell at auction", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+5.0).
			fulfillMarketAuctionSoft("user2", id, 15.0)

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should be able to sell and buy at auction even buyer is without the collection.", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			destroyDandyCollection("user2").
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+5.0).
			fulfillMarketAuctionSoft("user2", id, 15.0)

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should be able to cancel listing if the pointer is no longer valid", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			destroyDandyCollection("user2").
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+5.0).
			sendDandy("user2", "user1", id)

		otu.setUUID(400)

		otu.O.Tx("cancelMarketAuctionSoft",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"id":     id,
				"seller": otu.O.Address("user1"),
				"buyer":  otu.O.Address("user2"),
				"amount": 15.0,
				"status": "cancel_ghostlisting",
			})

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should not be able to list with price 0", func(t *testing.T) {

		listingTx("listNFTForAuctionSoft",
			WithArg("price", 0.0),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Auction start price should be greater than 0")
	})

	t.Run("Should not be able to list with invalid reserve price", func(t *testing.T) {

		listingTx("listNFTForAuctionSoft",
			WithArg("price", price),
			WithArg("auctionReservePrice", price-5.0),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Auction reserve price should be greater than Auction start price")
	})

	t.Run("Should not be able to list with invalid time", func(t *testing.T) {

		listingTx("listNFTForAuctionSoft",
			WithArg("auctionReservePrice", price),
			WithArg("auctionValidUntil", 10.0),
		).
			AssertFailure(t, "Valid until is before current time")
	})

	t.Run("Should be able to add bid at auction", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			increaseAuctionBidMarketSoft("user2", id, 5.0, price+10.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+10.0).
			fulfillMarketAuctionSoft("user2", id, price+10.0)

		otu.sendDandy("user1", "user2", id)
		otu.delistAllNFTForSoftAuction("user1")
	})

	t.Run("Should not be able to bid expired auction listing", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			tickClock(200.0)

		otu.O.Tx("bidMarketAuctionSoft" ,
			WithSigner("user2") ,
			WithArg("marketplace" , "account") ,
			WithArg("user" , "user1") ,
			WithArg("id" ,id) ,
			WithArg("amount" ,price) ,
		).
			AssertFailure(t, "This auction listing is already expired")

		otu.delistAllNFTForSoftAuction("user1")
	})

	t.Run("Should not be able to bid your own listing", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.Tx("bidMarketAuctionSoft",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "You cannot bid on your own resource")

		otu.delistAllNFTForSoftAuction("user1")
	})

	t.Run("Should be able to cancel an auction", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		name := "user1"

		otu.O.Tx("cancelMarketAuctionSoft",
			WithSigner(name),
			WithArg("marketplace", "account"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"id":     id,
				"seller": otu.O.Address(name),
				"amount": 10.0,
				"status": "cancel",
			})
	})

	t.Run("Should not be able to cancel an ended auction", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			tickClock(4000.0).
			saleItemListed("user1", "finished_completed", price+5.0)

		name := "user1"

		otu.O.Tx("cancelMarketAuctionSoft",
			WithSigner(name),
			WithArg("marketplace", "account"),
			WithArg("ids", []uint64{id}),
		).
			AssertFailure(t, "Cannot cancel finished auction, fulfill it instead")

		otu.fulfillMarketAuctionSoft("user2", id, price+5.0).
			sendDandy("user1", "user2", id)

	})

	t.Run("Cannot fulfill a not yet ended auction", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.setUUID(300)

		otu.auctionBidMarketSoft("user2", "user1", id, price+5.0)

		otu.tickClock(100.0)

		otu.O.Tx("fulfillMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", price+5.0),
		).
			AssertFailure(t, "Auction has not ended yet")

		otu.delistAllNFTForSoftAuction("user1")
	})

	t.Run("Should allow seller to cancel auction if it failed to meet reserve price", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+1.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_failed", 11.0)

		buyer := "user2"
		name := "user1"

		otu.O.Tx("cancelMarketAuctionSoft",
			WithSigner(name),
			WithArg("marketplace", "account"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"id":     id,
				"seller": otu.O.Address(name),
				"buyer":  otu.O.Address(buyer),
				"amount": 11.0,
				"status": "cancel_reserved_not_met",
			})
	})

	t.Run("Should be able to bid and increase bid by same user", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+preIncrement).
			saleItemListed("user1", "active_ongoing", price+preIncrement)

		otu.O.Tx("increaseBidMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", 0.1),
		).
			AssertFailure(t, "must be larger then previous bid+bidIncrement")

		otu.delistAllNFTForSoftAuction("user1")
	})

	/* Tests on Rules */
	t.Run("Should not be able to list after deprecated", func(t *testing.T) {

		otu.alterMarketOption("AuctionSoft", "deprecate")

		listingTx("listNFTForAuctionSoft",
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterMarketOption("AuctionSoft", "enable")
	})

	t.Run("Should be able to bid, add bid , fulfill auction and delist after deprecated", func(t *testing.T) {
		otu.listNFTForSoftAuction("user1", id, price)

		otu.alterMarketOption("AuctionSoft", "deprecate")

		otu.O.Tx("bidMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t)

		otu.O.Tx("increaseBidMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", price+10.0),
		).
			AssertSuccess(t)

		otu.tickClock(500.0)

		otu.O.Tx("fulfillMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", 30.0),
		).
			AssertSuccess(t)

		otu.alterMarketOption("AuctionSoft", "enable")

		listingTx("listNFTForAuctionSoft",
			WithSigner("user2"),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertSuccess(t)

		otu.auctionBidMarketSoft("user1", "user2", id, price+5.0)

		otu.alterMarketOption("AuctionSoft", "deprecate")

		otu.O.Tx("cancelMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t)

		otu.alterMarketOption("AuctionSoft", "enable").
			sendDandy("user1", "user2", id)

	})

	t.Run("Should no be able to list, bid, add bid , fulfill auction and delist after stopped", func(t *testing.T) {

		otu.alterMarketOption("AuctionSoft", "stop")

		listingTx("listNFTForAuctionSoft",
			WithSigner("user1"),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("AuctionSoft", "enable").
			listNFTForSoftAuction("user1", id, price).
			alterMarketOption("AuctionSoft", "stop")

		otu.O.Tx("bidMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("AuctionSoft", "enable").
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			alterMarketOption("AuctionSoft", "stop")

		otu.O.Tx("increaseBidMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", price+10.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("AuctionSoft", "stop")

		otu.O.Tx("cancelMarketAuctionSoft",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("ids", []uint64{id}),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.tickClock(500.0)

		otu.O.Tx("fulfillMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", price+5.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		/* Reset */
		otu.alterMarketOption("AuctionSoft", "enable")

		otu.O.Tx("fulfillMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", price+5.0),
		).
			AssertSuccess(t)

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should not be able to bid below listing price", func(t *testing.T) {
		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.Tx("bidMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", 1.0),
		).
			AssertFailure(t, "You need to bid more then the starting price of 10.00000000")

		otu.delistAllNFTForSoftAuction("user1")

	})

	t.Run("Should not be able to bid less the previous bidder", func(t *testing.T) {
		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0)

		otu.O.Tx("bidMarketAuctionSoft",
			WithSigner("user3"),
			WithArg("marketplace", "account"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "bid 5.00000000 must be larger then previous bid+bidIncrement 16.00000000")

		otu.delistAllNFTForSoftAuction("user1")
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon fulfill action", func(t *testing.T) {

		price = 5.0

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0)

		otu.tickClock(500.0)

		otu.O.Tx("fulfillMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", 10.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.25,
				"royaltyName": "find",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"royaltyName": "creator",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.25,
				"royaltyName": "find forge",
			})

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		price = 5.0

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			setFindCut(0.035)

		otu.tickClock(500.0)

		otu.O.Tx("fulfillMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", id),
			WithArg("amount", 10.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.35,
				"royaltyName": "find",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"royaltyName": "creator",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("account"),
				"amount":      0.25,
				"royaltyName": "find forge",
			})

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		price = 10.0

		ids := otu.mintThreeExampleDandies()

		otu.listNFTForSoftAuction("user1", ids[0], price).
			listNFTForSoftAuction("user1", ids[1], price).
			auctionBidMarketSoft("user2", "user1", ids[0], price+5.0).
			tickClock(400.0).
			profileBan("user1")

		// Should not be able to list
		listingTx("listNFTForAuctionSoft",
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("bidMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("user", "user1"),
			WithArg("id", ids[1]),
			WithArg("amount", price),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("fulfillMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", ids[0]),
			WithArg("amount", price+5.0),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("cancelMarketAuctionSoft",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("ids", ids[1:1]),
		).
			AssertSuccess(t)

		otu.removeProfileBan("user1")

		otu.O.Tx("fulfillMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", ids[0]),
			WithArg("amount", price+5.0),
		).
			AssertSuccess(t)

		otu.delistAllNFTForSoftAuction("user1")

	})

	t.Run("Should be able to ban user, user cannot bid NFT.", func(t *testing.T) {

		price = 10.0

		ids := otu.mintThreeExampleDandies()

		otu.listNFTForSoftAuction("user1", ids[0], price).
			listNFTForSoftAuction("user1", ids[1], price).
			auctionBidMarketSoft("user2", "user1", ids[0], price+5.0).
			tickClock(400.0).
			profileBan("user2")

		otu.O.Tx("bidMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("user", "user1"),
			WithArg("id", ids[1]),
			WithArg("amount", price),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		otu.O.Tx("fulfillMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", ids[0]),
			WithArg("amount", price+5.0),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		/* Reset */
		otu.removeProfileBan("user2")

		otu.O.Tx("fulfillMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("marketplace", "account"),
			WithArg("id", ids[0]),
			WithArg("amount", price+5.0),
		).
			AssertSuccess(t)

		otu.delistAllNFTForSoftAuction("user1")

	})

	t.Run("Should emit previous bidder if outbid", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			saleItemListed("user1", "active_ongoing", 15.0)

		otu.O.Tx("bidMarketAuctionSoft",
			WithSigner("user3"),
			WithArg("marketplace", "account"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", 20.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"amount":        20.0,
				"id":            id,
				"buyer":         otu.O.Address("user3"),
				"previousBuyer": otu.O.Address("user2"),
				"status":        "active_ongoing",
			})

		otu.delistAllNFTForSoftAuction("user1")
	})

	t.Run("Should be able to list an NFT for auction and bid it with DUC", func(t *testing.T) {

		otu.registerDUCInRegistry().
			setDUCExampleNFT().
			sendExampleNFT("user1", "account")

		saleItemID := otu.listNFTForSoftAuctionDUC("user1", 0, price)

		otu.saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoftDUC("user2", "user1", saleItemID[0], price+5.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+5.0).
			fulfillMarketAuctionSoftDUC("user2", saleItemID[0], 15.0)

		otu.sendExampleNFT("user1", "user2")
	})

	t.Run("Should be able to list an NFT for auction and bid it with id != uuid", func(t *testing.T) {

		saleItemID := otu.listExampleNFTForSoftAuction("user1", 0, price)

		otu.saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", saleItemID[0], price+5.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+5.0).
			fulfillMarketAuctionSoft("user2", saleItemID[0], 15.0)

		otu.sendExampleNFT("user1", "user2")
	})

	t.Run("Should not be able to list soul bound items", func(t *testing.T) {
		otu.sendSoulBoundNFT("user1", "account")
		// set market rules
		otu.O.Tx("adminSetSellExampleNFTForFlow",
			WithSigner("find"),
			WithArg("tenant", "account"),
		)

		otu.O.Tx("listNFTForAuctionSoft",
			WithSigner("user1"),
			WithArg("marketplace", "account"),
			WithArg("nftAliasOrIdentifier", "A.f8d6e0586b0a20c7.ExampleNFT.NFT"),
			WithArg("id", 1),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("price", price),
			WithArg("auctionReservePrice", price+5.0),
			WithArg("auctionDuration", 300.0),
			WithArg("auctionExtensionOnLateBid", 60.0),
			WithArg("minimumBidIncrement", 1.0),
			WithArg("auctionValidUntil", otu.currentTime()+100.0),
		).AssertFailure(t, "This item is soul bounded and cannot be traded")

	})

}
