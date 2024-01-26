package test_main

import (
	"testing"
	// . "github.com/bjartek/overflow"
)

func TestMarketAuctionSoft(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	price := 10.0
	//	preIncrement := 5.0

	id := dapperDandyId

	/*	eventIdentifier := otu.identifier("FindMarketAuctionSoft", "EnglishAuction")
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
		)
	*/

	ot.Run(t, "Should be able to sell at auction", func(t *testing.T) {
		otu.listNFTForSoftAuction("user5", id, price).
			saleItemListed("user5", "active_listed", price).
			auctionBidMarketSoft("user6", "user5", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user5", "finished_completed", price+5.0).
			fulfillMarketAuctionSoft("user6", id, 15.0)
	})

	/*

		ot.Run(t, "Should not be able to list an item for auction twice, and will give error message.", func(t *testing.T) {
			otu.listNFTForSoftAuction("user5", id, price).
				saleItemListed("user5", "active_listed", price)

			listingTx(
				WithArg("auctionValidUntil", otu.currentTime()+10.0),
			).
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
				destroyDandyCollection("user6").
				auctionBidMarketSoft("user6", "user5", id, price+5.0).
				tickClock(400.0).
				saleItemListed("user5", "finished_completed", price+5.0).
				sendDandy("user6", "user5", id)

			otu.setUUID(800)

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
				WithArg("auctionValidUntil", otu.currentTime()+10.0),
			).
				AssertFailure(t, "Auction start price should be greater than 0")
		})

		ot.Run(t, "Should not be able to list with invalid reserve price", func(t *testing.T) {
			listingTx(
				WithArg("price", price),
				WithArg("auctionReservePrice", price-5.0),
				WithArg("auctionValidUntil", otu.currentTime()+10.0),
			).
				AssertFailure(t, "Auction reserve price should be greater than Auction start price")
		})

		ot.Run(t, "Should not be able to list with invalid time", func(t *testing.T) {
			listingTx(
				WithArg("auctionReservePrice", price),
				WithArg("auctionValidUntil", 10.0),
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

			otu.O.Tx("bidMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithArg("user", "user5"),
				WithArg("id", id),
				WithArg("amount", price),
			).
				AssertFailure(t, "This auction listing is already expired")
		})

		ot.Run(t, "Should not be able to bid your own listing", func(t *testing.T) {
			otu.listNFTForSoftAuction("user5", id, price).
				saleItemListed("user5", "active_listed", price)

			otu.O.Tx("bidMarketAuctionSoftDapper",
				WithSigner("user5"),
				WithArg("user", "user5"),
				WithArg("id", id),
				WithArg("amount", price),
			).
				AssertFailure(t, "You cannot bid on your own resource")
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

			otu.setUUID(1000)

			otu.auctionBidMarketSoft("user6", "user5", id, price+5.0)

			otu.tickClock(100.0)

			otu.O.Tx("fulfillMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithPayloadSigner("dapper"),
				WithArg("id", id),
				WithArg("amount", price+5.0),
			).
				AssertFailure(t, "Auction has not ended yet")
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

			listingTx(
				WithArg("auctionValidUntil", otu.currentTime()+10.0),
			).
				AssertFailure(t, "Tenant has deprected mutation options on this item")

			otu.alterMarketOptionDapper("enable")
		})

		ot.Run(t, "Should be able to bid, add bid , fulfill auction and delist after deprecated", func(t *testing.T) {
			otu.listNFTForSoftAuction("user5", id, price)

			otu.alterMarketOptionDapper("deprecate")

			otu.O.Tx("bidMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithArg("user", "user5"),
				WithArg("id", id),
				WithArg("amount", price),
			).
				AssertSuccess(t)

			otu.O.Tx("increaseBidMarketAuctionSoft",
				WithSigner("user6"),
				WithArg("id", id),
				WithArg("amount", price+10.0),
			).
				AssertSuccess(t)

			otu.tickClock(500.0)

			otu.O.Tx("fulfillMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithPayloadSigner("dapper"),
				WithArg("id", id),
				WithArg("amount", 30.0),
			).
				AssertSuccess(t)

			otu.alterMarketOptionDapper("enable")

			listingTx(
				WithSigner("user6"),
				WithArg("auctionValidUntil", otu.currentTime()+10.0),
			).
				AssertSuccess(t)

			otu.auctionBidMarketSoft("user5", "user6", id, price+5.0)

			otu.alterMarketOptionDapper("deprecate")

			otu.O.Tx("cancelMarketAuctionSoft",
				WithSigner("user6"),
				WithArg("ids", []uint64{id}),
			).
				AssertSuccess(t)
		})

		ot.Run(t, "Should no be able to list, bid, add bid , fulfill auction after stopped", func(t *testing.T) {
			otu.alterMarketOptionDapper("stop")

			listingTx(
				WithSigner("user5"),
				WithArg("auctionValidUntil", otu.currentTime()+10.0),
			).
				AssertFailure(t, "Tenant has stopped this item")

			otu.alterMarketOptionDapper("enable").
				listNFTForSoftAuction("user5", id, price).
				alterMarketOptionDapper("stop")

			otu.O.Tx("bidMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithArg("user", "user5"),
				WithArg("id", id),
				WithArg("amount", price),
			).
				AssertFailure(t, "Tenant has stopped this item")

			otu.alterMarketOptionDapper("enable").
				auctionBidMarketSoft("user6", "user5", id, price+5.0).
				alterMarketOptionDapper("stop")

			otu.O.Tx("increaseBidMarketAuctionSoft",
				WithSigner("user6"),
				WithArg("id", id),
				WithArg("amount", price+10.0),
			).
				AssertFailure(t, "Tenant has stopped this item")

			otu.alterMarketOptionDapper("stop")

			otu.tickClock(500.0)

			otu.O.Tx("fulfillMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithPayloadSigner("dapper"),
				WithArg("id", id),
				WithArg("amount", price+5.0),
			).
				AssertFailure(t, "Tenant has stopped this item")
		})

		ot.Run(t, "Should not be able to bid below listing price", func(t *testing.T) {
			otu.listNFTForSoftAuction("user5", id, price).
				saleItemListed("user5", "active_listed", price)

			otu.O.Tx("bidMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithArg("user", "user5"),
				WithArg("id", id),
				WithArg("amount", 1.0),
			).
				AssertFailure(t, "You need to bid more then the starting price of 10.00000000")

			otu.delistAllNFTForSoftAuction("user5")
		})

		ot.Run(t, "Should not be able to bid less the previous bidder", func(t *testing.T) {
			otu.listNFTForSoftAuction("user5", id, price).
				saleItemListed("user5", "active_listed", price).
				auctionBidMarketSoft("user6", "user5", id, price+5.0)

			otu.O.Tx("bidMarketAuctionSoftDapper",
				WithSigner("user3"),
				WithArg("user", "user5"),
				WithArg("id", id),
				WithArg("amount", 5.0),
			).
				AssertFailure(t, "bid 5.00000000 must be larger then previous bid+bidIncrement 16.00000000")

			otu.delistAllNFTForSoftAuction("user5")
		})


		// platform 0.15
		// artist 0.05
		// find 0.025
		// tenant nil
		ot.Run(t, "Royalties should be sent to correspondence upon fulfill action", func(t *testing.T) {
			price = 5.0

			otu.listNFTForSoftAuction("user5", id, price).
				saleItemListed("user5", "active_listed", price).
				auctionBidMarketSoft("user6", "user5", id, price+5.0)

			otu.tickClock(500.0)

			otu.O.Tx("fulfillMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithPayloadSigner("dapper"),
				WithArg("id", id),
				WithArg("amount", 10.0),
			).
				AssertSuccess(t).
				AssertEvent(t, royaltyIdentifier, map[string]interface{}{
					"address":     otu.O.Address("find"),
					"amount":      0.25,
					"royaltyName": "find",
				}).
				AssertEvent(t, royaltyIdentifier, map[string]interface{}{
					"address":     otu.O.Address("user5"),
					"amount":      0.5,
					"royaltyName": "creator",
				}).
				AssertEvent(t, royaltyIdentifier, map[string]interface{}{
					"address":     otu.O.Address("find"),
					"amount":      0.25,
					"royaltyName": "find forge",
				})
		})

		ot.Run(t, "Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {
			price = 10.0

			ids := otu.mintThreeExampleDandies()

			otu.listNFTForSoftAuction("user5", ids[0], price).
				listNFTForSoftAuction("user5", ids[1], price).
				auctionBidMarketSoft("user6", "user5", ids[0], price+5.0).
				tickClock(400.0).
				profileBan("user5")

			// Should not be able to list
			listingTx(
				WithArg("auctionValidUntil", otu.currentTime()+10.0),
			).
				AssertFailure(t, "Seller banned by Tenant")

			otu.O.Tx("bidMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithArg("user", "user5"),
				WithArg("id", ids[1]),
				WithArg("amount", price),
			).
				AssertFailure(t, "Seller banned by Tenant")

			otu.O.Tx("fulfillMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithPayloadSigner("dapper"),
				WithArg("id", ids[0]),
				WithArg("amount", price+5.0),
			).
				AssertFailure(t, "Seller banned by Tenant")

			otu.O.Tx("cancelMarketAuctionSoft",
				WithSigner("user5"),
				WithArg("ids", ids[1:1]),
			).
				AssertSuccess(t)

			otu.removeProfileBan("user5")

			otu.O.Tx("fulfillMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithPayloadSigner("dapper"),
				WithArg("id", ids[0]),
				WithArg("amount", price+5.0),
			).
				AssertSuccess(t)

			otu.delistAllNFTForSoftAuction("user5")
		})

		ot.Run(t, "Should be able to ban user, user cannot bid NFT.", func(t *testing.T) {
			price = 10.0

			ids := otu.mintThreeExampleDandies()

			otu.listNFTForSoftAuction("user5", ids[0], price).
				listNFTForSoftAuction("user5", ids[1], price).
				auctionBidMarketSoft("user6", "user5", ids[0], price+5.0).
				tickClock(400.0).
				profileBan("user6")

			otu.O.Tx("bidMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithArg("user", "user5"),
				WithArg("id", ids[1]),
				WithArg("amount", price),
			).
				AssertFailure(t, "Buyer banned by Tenant")

			otu.O.Tx("fulfillMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithPayloadSigner("dapper"),
				WithArg("id", ids[0]),
				WithArg("amount", price+5.0),
			).
				AssertFailure(t, "Buyer banned by Tenant")
		})

		ot.Run(t, "Should emit previous bidder if outbid", func(t *testing.T) {
			otu.listNFTForSoftAuction("user5", id, price).
				saleItemListed("user5", "active_listed", price).
				auctionBidMarketSoft("user6", "user5", id, price+5.0).
				saleItemListed("user5", "active_ongoing", 15.0)

			otu.O.Tx("bidMarketAuctionSoftDapper",
				WithSigner("user3"),
				WithArg("user", "user5"),
				WithArg("id", id),
				WithArg("amount", 20.0),
			).
				AssertSuccess(t).
				AssertEvent(t, eventIdentifier, map[string]interface{}{
					"amount":        20.0,
					"id":            id,
					"buyer":         otu.O.Address("user3"),
					"previousBuyer": otu.O.Address("user6"),
					"status":        "active_ongoing",
				})
		})

		ot.Run(t, "Should be able to list an NFT for auction and bid it with DUC", func(t *testing.T) {
			saleItemID := otu.listNFTForSoftAuctionDUC("user5", 0, price)

			otu.saleItemListed("user5", "active_listed", price).
				auctionBidMarketSoftDUC("user6", "user5", saleItemID[0], price+5.0).
				tickClock(400.0).
				saleItemListed("user5", "finished_completed", price+5.0).
				fulfillMarketAuctionSoftDUC("user6", saleItemID[0], 15.0)
		})
	*/
}
