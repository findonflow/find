package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestMarketAuctionSoft(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	price := 10.0
	preIncrement := 5.0

	id := dapperDandyId

	eventIdentifier := otu.identifier("FindMarketAuctionSoft", "EnglishAuction")
	royaltyIdentifier := otu.identifier("FindMarket", "RoyaltyPaid")

	listingTx := otu.O.TxFileNameFN(
		"listNFTForAuctionSoftDapper",
		WithSigner("user5"),
		WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+10.0),
	)

	fulfillTx := otu.O.TxFileNameFN("fulfillMarketAuctionSoftDapper",
		WithSigner("user6"),
		WithPayloadSigner("dapper"),
		WithArg("id", id),
		WithArg("amount", price+5.0),
	)

	bidTx := otu.O.TxFileNameFN("bidMarketAuctionSoftDapper",
		WithSigner("user6"),
		WithArg("user", "user5"),
		WithArg("id", id),
		WithArg("amount", price),
	)

	ot.Run(t, "Should be able to sell at auction", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			auctionBidMarketSoft("user6", "user5", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user5", "finished_completed", price+5.0).
			fulfillMarketAuctionSoft("user6", id, 15.0)
	})

	ot.Run(t, "Should not be able to list an item for auction twice, and will give error message.", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price)

		listingTx().
			AssertFailure(t, "Auction listing for this item is already created.")
	})

	ot.Run(t, "Should be able to sell and buy at auction even buyer is without the collection.", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			destroyDandyCollection("user6").
			auctionBidMarketSoft("user6", "user5", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user5", "finished_completed", price+5.0).
			fulfillMarketAuctionSoft("user6", id, 15.0)
	})

	ot.Run(t, "Should be able to cancel listing if the pointer is no longer valid", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			auctionBidMarketSoft("user6", "user5", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user5", "finished_completed", price+5.0).
			sendDandy("user6", "user5", id)

		otu.O.Tx("cancelMarketAuctionSoft",
			WithSigner("user5"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     id,
				"seller": otu.O.Address("user5"),
				"buyer":  otu.O.Address("user6"),
				"amount": 15.0,
				"status": "cancel_ghostlisting",
			})
	})

	ot.Run(t, "Should not be able to list with price 0", func(t *testing.T) {
		listingTx(
			WithArg("price", 0.0),
		).
			AssertFailure(t, "Auction start price should be greater than 0")
	})

	ot.Run(t, "Should not be able to list with invalid reserve price", func(t *testing.T) {
		listingTx(
			WithArg("price", price),
			WithArg("auctionReservePrice", price-5.0),
		).
			AssertFailure(t, "Auction reserve price should be greater than Auction start price")
	})

	ot.Run(t, "Should not be able to list with invalid time", func(t *testing.T) {
		otu.tickClock(400.0)

		listingTx(
			WithArg("auctionReservePrice", price),
			WithArg("auctionValidUntil", 1.0),
		).
			AssertFailure(t, "Valid until is before current time")
	})

	ot.Run(t, "Should be able to add bid at auction", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			auctionBidMarketSoft("user6", "user5", id, price+5.0).
			increaseAuctionBidMarketSoft("user6", id, 5.0, price+10.0).
			tickClock(400.0).
			saleItemListed("user5", "finished_completed", price+10.0).
			fulfillMarketAuctionSoft("user6", id, price+10.0)
	})

	ot.Run(t, "Should not be able to bid expired auction listing", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			tickClock(200.0)

		bidTx().AssertFailure(t, "This auction listing is already expired")
	})

	ot.Run(t, "Should not be able to bid your own listing", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price)

		bidTx(WithSigner("user5")).AssertFailure(t, "You cannot bid on your own resource")
	})

	ot.Run(t, "Should be able to cancel an auction", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price)

		name := "user5"

		otu.O.Tx("cancelMarketAuctionSoft",
			WithSigner(name),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     id,
				"seller": otu.O.Address(name),
				"amount": 10.0,
				"status": "cancel",
			})
	})

	ot.Run(t, "Should not be able to cancel an ended auction", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			auctionBidMarketSoft("user6", "user5", id, price+5.0).
			tickClock(4000.0).
			saleItemListed("user5", "finished_completed", price+5.0)

		name := "user5"

		otu.O.Tx("cancelMarketAuctionSoft",
			WithSigner(name),
			WithArg("ids", []uint64{id}),
		).
			AssertFailure(t, "Cannot cancel finished auction, fulfill it instead")

		otu.fulfillMarketAuctionSoft("user6", id, price+5.0)
	})

	ot.Run(t, "Cannot fulfill a not yet ended auction", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price)

		otu.auctionBidMarketSoft("user6", "user5", id, price+5.0)

		otu.tickClock(100.0)

		fulfillTx().AssertFailure(t, "Auction has not ended yet")
	})

	ot.Run(t, "Should allow seller to cancel auction if it failed to meet reserve price", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			auctionBidMarketSoft("user6", "user5", id, price+1.0).
			tickClock(400.0).
			saleItemListed("user5", "finished_failed", 11.0)

		buyer := "user6"
		name := "user5"

		otu.O.Tx("cancelMarketAuctionSoft",
			WithSigner(name),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     id,
				"seller": otu.O.Address(name),
				"buyer":  otu.O.Address(buyer),
				"amount": 11.0,
				"status": "cancel_reserved_not_met",
			})
	})

	ot.Run(t, "Should be able to bid and increase bid by same user", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			auctionBidMarketSoft("user6", "user5", id, price+preIncrement).
			saleItemListed("user5", "active_ongoing", price+preIncrement)

		otu.O.Tx("increaseBidMarketAuctionSoft",
			WithSigner("user6"),
			WithArg("id", id),
			WithArg("amount", 0.1),
		).
			AssertFailure(t, "must be larger then previous bid+bidIncrement")

		otu.delistAllNFTForSoftAuction("user5")
	})

	ot.Run(t, "Should not be able to list after deprecated", func(t *testing.T) {
		otu.alterMarketOptionDapper("deprecate")

		listingTx().
			AssertFailure(t, "Tenant has deprected mutation options on this item")
	})

	ot.Run(t, "Should not be able to bid below listing price", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price)

		bidTx(
			WithArg("amount", 1.0),
		).
			AssertFailure(t, "You need to bid more then the starting price of 10.00000000")
	})

	ot.Run(t, "Should not be able to bid less the previous bidder", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			auctionBidMarketSoft("user6", "user5", id, price+5.0)

		bidTx(
			WithSigner("user7"),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "bid 5.00000000 must be larger then previous bid+bidIncrement 16.00000000")
	})

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	ot.Run(t, "Royalties should be sent to correspondence upon fulfill action", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			auctionBidMarketSoft("user6", "user5", id, price+5.0)

		otu.tickClock(500.0)

		fulfillTx(
			WithArg("amount", 15.0),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.375,
				"royaltyName": "find",
			}).
			/* //todo: dont know why this is not emitted here?
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user5"),
				"amount":      0.5,
				"royaltyName": "creator",
			}).
			*/
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.375,
				"royaltyName": "find forge",
			})
	})

	ot.Run(t, "Should emit previous bidder if outbid", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			auctionBidMarketSoft("user6", "user5", id, price+5.0).
			saleItemListed("user5", "active_ongoing", 15.0)

		bidTx(
			WithSigner("user7"),
			WithArg("amount", 20.0),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount":        20.0,
				"id":            id,
				"buyer":         otu.O.Address("user7"),
				"previousBuyer": otu.O.Address("user6"),
				"status":        "active_ongoing",
			})
	})

	ot.Run(t, "Should be able to list an NFT for auction and bid it with DUC", func(t *testing.T) {
		saleItemID := otu.listNFTForSoftAuctionDUC("user5", id, price)

		otu.saleItemListed("user5", "active_listed", price).
			auctionBidMarketSoftDUC("user6", "user5", saleItemID[0], price+5.0).
			tickClock(400.0).
			saleItemListed("user5", "finished_completed", price+5.0).
			fulfillMarketAuctionSoftDUC("user6", saleItemID[0], 15.0)
	})
}
