package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow/v2"
)

func TestMarketAuctionEscrow(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	price := 10.0
	id := dandyIds[0]
	preIncrement := 5.0
	eventIdentifier := otu.identifier("FindMarketAuctionEscrow", "EnglishAuction")
	royaltyIdentifier := otu.identifier("FindMarket", "RoyaltyPaid")

	increaseAuctionBidTx := otu.O.TxFileNameFN("increaseBidMarketAuctionEscrowed",
		WithSigner("user2"),
		WithArg("id", id),
		WithArg("amount", preIncrement),
		WithAssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"amount": price + preIncrement,
			"id":     id,
			"buyer":  otu.O.Address("user2"),
			"status": "active_ongoing",
		}))

	listingTx := otu.O.TxFN(
		WithSigner("user1"),
		WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionStartTime", nil),
		WithArg("auctionValidUntil", otu.currentTime()+10.0),
	)
	ot.Run(t, "Should be able to sell at auction", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+5.0).
			fulfillMarketAuctionEscrow("user1", id, "user2", price+5.0)
	})

	ot.Run(t, "Should not be able to list an item for auction twice, and will give error message.", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		listingTx("listNFTForAuctionEscrowed",
			WithSigner("user1"),
			WithArg("id", id),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Auction listing for this item is already created.")
	})

	ot.Run(t, "Should be able to cancel listing if the pointer is no longer valid", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			tickClock(400.0).
			sendDandy("user5", "user1", id)

		otu.O.Tx("cancelMarketAuctionEscrowed",
			WithSigner("user1"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t).
			AssertEvent(t, "EnglishAuction", map[string]interface{}{
				"id":     id,
				"seller": otu.O.Address("user1"),
				"buyer":  otu.O.Address("user2"),
				"amount": 15.0,
				"status": "cancel_ghostlisting",
			})
	})

	ot.Run(t, "Should not be able to list with price 0", func(t *testing.T) {
		listingTx("listNFTForAuctionEscrowed",
			WithArg("price", 0.0),
		).AssertFailure(t, "Auction start price should be greater than 0")
	})

	ot.Run(t, "Should not be able to list with invalid reserve price", func(t *testing.T) {
		listingTx("listNFTForAuctionEscrowed",
			WithArg("auctionReservePrice", price-5.0),
		).
			AssertFailure(t, "Auction reserve price should be greater than Auction start price")
	})

	ot.Run(t, "Should not be able to list with invalid time", func(t *testing.T) {
		listingTx("listNFTForAuctionEscrowed",
			WithArg("auctionValidUntil", otu.currentTime()-1.0),
		).
			AssertFailure(t, "Valid until is before current time")
	})

	ot.Run(t, "Should be able to sell at auction, buyer fulfill", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		otu.tickClock(400.0)

		otu.saleItemListed("user1", "finished_completed", price+5.0)
		otu.fulfillMarketAuctionEscrowFromBidder("user2", id, price+5.0)
	})

	ot.Run(t, "Should not be able to bid expired auction listing", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			tickClock(101.0)

		otu.O.Tx("bidMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "This auction listing is already expired")
	})

	ot.Run(t, "Should not be able to bid your own listing", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.Tx("bidMarketAuctionEscrowed",
			WithSigner("user1"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "You cannot bid on your own resource")
	})

	ot.Run(t, "Should return funds if auction does not meet reserve price", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+1.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_failed", 11.0)

		buyer := "user2"
		name := "user1"

		otu.O.Tx("fulfillMarketAuctionEscrowed",
			WithSigner(name),
			WithArg("owner", name),
			WithArg("id", id),
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

	ot.Run(t, "Should be able to cancel the auction", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		name := "user1"

		otu.O.Tx("cancelMarketAuctionEscrowed",
			WithSigner(name),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     id,
				"seller": otu.O.Address(name),
				"amount": 10.0,
				"status": "cancel_listing",
			})
	})

	ot.Run(t, "Should not be able to cancel the auction if it is ended", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+5.0)

		name := "user1"

		otu.O.Tx("cancelMarketAuctionEscrowed",
			WithSigner(name),
			WithArg("ids", []uint64{id}),
		).
			AssertFailure(t, "Cannot cancel finished auction, fulfill it instead")

		otu.O.Tx("fulfillMarketAuctionEscrowed",
			WithSigner(name),
			WithArg("owner", name),
			WithArg("id", id),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should not be able to fulfill a not yet live / ended auction", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.Tx("fulfillMarketAuctionEscrowed",
			WithSigner("user1"),
			WithArg("owner", "user1"),
			WithArg("id", id),
		).
			AssertFailure(t, "This auction is not live")

		otu.auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		otu.tickClock(100.0)

		otu.O.Tx("fulfillMarketAuctionEscrowed",
			WithSigner("user1"),
			WithArg("owner", "user1"),
			WithArg("id", id),
		).
			AssertFailure(t, "Auction has not ended yet")
	})

	ot.Run(t, "Should return funds if auction is cancelled", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+1.0).
			saleItemListed("user1", "active_ongoing", 11.0).
			tickClock(2.0)

		buyer := "user2"
		name := "user1"

		otu.O.Tx("cancelMarketAuctionEscrowed",
			WithSigner(name),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"id":     id,
				"seller": otu.O.Address(name),
				"buyer":  otu.O.Address(buyer),
				"amount": 11.0,
				"status": "cancel_listing",
			})
	})

	ot.Run(t, "Should be able to bid and increase bid by same user", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)

		increaseAuctionBidTx()
		// increaseAuctioBidMarketEscrow("user2", id, 5.0, 20.0).
		otu.saleItemListed("user1", "active_ongoing", 15.0)
	})

	ot.Run(t, "Should not be able to add bid that is not above minimumBidIncrement", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+preIncrement).
			saleItemListed("user1", "active_ongoing", price+preIncrement)

		increaseAuctionBidTx(
			WithArg("amount", 0.1),
			WithRequireFailure(t, "must be larger then previous bid+bidIncrement"),
		)
	})

	ot.Run(t, "Should not be able to list after deprecated", func(t *testing.T) {
		otu.alterMarketOption("deprecate")

		listingTx("listNFTForAuctionEscrowed",
			WithSigner("user1"),
			WithArg("id", id),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")
	})

	ot.Run(t, "Should be able to bid, add bid , fulfill auction and delist after deprecated", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price)

		otu.alterMarketOption("deprecate")

		otu.O.Tx("bidMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t)

		increaseAuctionBidTx()

		otu.tickClock(500.0)

		otu.O.Tx("fulfillMarketAuctionEscrowedFromBidder",
			WithSigner("user2"),
			WithArg("id", id),
		).
			AssertSuccess(t)

		otu.alterMarketOption("enable")

		listingTx("listNFTForAuctionEscrowed",
			WithSigner("user2"),
			WithArg("id", id),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertSuccess(t)

		otu.auctionBidMarketEscrow("user1", "user2", id, price+5.0)

		otu.alterMarketOption("deprecate")

		otu.O.Tx("cancelMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should no be able to list, bid, add bid , fulfill auction after stopped", func(t *testing.T) {
		otu.alterMarketOption("stop")

		listingTx("listNFTForAuctionEscrowed",
			WithSigner("user1"),
			WithArg("id", id),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("enable").
			listNFTForEscrowedAuction("user1", id, price).
			alterMarketOption("stop")

		otu.O.Tx("bidMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("enable").
			auctionBidMarketEscrow("user2", "user1", id, price).
			alterMarketOption("stop")

		increaseAuctionBidTx(WithRequireFailure(t, "Tenant has stopped this item"))

		otu.alterMarketOption("stop")

		otu.tickClock(500.0)

		otu.O.Tx("fulfillMarketAuctionEscrowedFromBidder",
			WithSigner("user2"),
			WithArg("id", id),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("enable")

		otu.O.Tx("fulfillMarketAuctionEscrowedFromBidder",
			WithSigner("user2"),
			WithArg("id", id),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should not be able to bid below listing price", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.Tx("bidMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", 1.0),
		).
			AssertFailure(t, "You need to bid more then the starting price of 10.00000000")
	})

	ot.Run(t, "Should not be able to bid less the previous bidder", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		otu.O.Tx("bidMarketAuctionEscrowed",
			WithSigner("user3"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "bid 5.00000000 must be larger then previous bid+bidIncrement 16.00000000")
	})

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	ot.Run(t, "Royalties should be sent to correspondence upon fulfill action", func(t *testing.T) {
		price = 5.0
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		otu.tickClock(500.0)

		otu.O.Tx("fulfillMarketAuctionEscrowedFromBidder",
			WithSigner("user2"),
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

	ot.Run(t, "Royalties of find platform should be able to change", func(t *testing.T) {
		price = 5.0
		otu.listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			setFindCut(0.035)

		otu.tickClock(500.0)

		otu.O.Tx("fulfillMarketAuctionEscrowedFromBidder",
			WithSigner("user2"),
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

	ot.Run(t, "Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {
		price = 10.0
		ids := dandyIds

		otu.listNFTForEscrowedAuction("user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			auctionBidMarketEscrow("user2", "user1", ids[0], price+5.0).
			tickClock(400.0).
			profileBan("user1")

			// Should not be able to list
		listingTx("listNFTForAuctionEscrowed",
			WithSigner("user1"),
			WithArg("id", ids[2]),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("bidMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", ids[1]),
			WithArg("amount", price),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("fulfillMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("owner", "user1"),
			WithArg("id", ids[0]),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("cancelMarketAuctionEscrowed",
			WithSigner("user1"),
			WithArg("ids", []uint64{ids[1]}),
		).
			AssertSuccess(t)

		otu.removeProfileBan("user1")

		otu.O.Tx("fulfillMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("owner", "user1"),
			WithArg("id", ids[0]),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should emit previous bidder if outbid", func(t *testing.T) {
		otu.listNFTForEscrowedAuction("user1", id, price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		otu.O.Tx("bidMarketAuctionEscrowed",
			WithSigner("user3"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", 20.0),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount":        20.0,
				"id":            id,
				"buyer":         otu.O.Address("user3"),
				"previousBuyer": otu.O.Address("user2"),
				"status":        "active_ongoing",
			})
	})

	/*
		* TODO: maybe fix later
				t.Run("not be able to buy an NFT with changed royalties, but should be able to cancel listing", func(t *testing.T) {

					saleItem := otu.listExampleNFTForEscrowedAuction("user1", 2, price)

					otu.saleItemListed("user1", "active_listed", price).
						auctionBidMarketEscrow("user2", "user1", saleItem[0], price+5.0).
						tickClock(400.0).
						saleItemListed("user1", "finished_completed", price+5.0)

					otu.changeRoyaltyExampleNFT("user1", 2, false)

					ids, err := otu.O.Script("getRoyaltyChangedIds",
						WithArg("user", "user1"),
					).
						GetAsJson()

					if err != nil {
						panic(err)
					}

					otu.O.Tx("relistMarketListings",
						WithSigner("user1"),
						WithArg("ids", ids),
					).
						AssertSuccess(t)

				})

				t.Run("should be able to get listings with royalty problems and cancel", func(t *testing.T) {
					otu.changeRoyaltyExampleNFT("user1", 2, true)

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

	*/
	ot.Run(t, "Should be able to list a timed auction with future start time", func(t *testing.T) {
		listingTx("listNFTForAuctionEscrowed",
			WithArg("auctionStartTime", otu.currentTime()+10.0),
			WithArg("auctionValidUntil", nil),
		).
			AssertSuccess(t).
			AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
				"status":              "inactive_listed",
				"amount":              price,
				"startsAt":            otu.currentTime() + 10.0,
				"auctionReservePrice": price + 5.0,
				"id":                  id,
				"seller":              otu.O.Address("user1"),
			})
	})

	ot.Run(t, "Should be able to list a timed auction with current start time", func(t *testing.T) {
		listingTx("listNFTForAuctionEscrowed",
			WithArg("auctionStartTime", otu.currentTime()),
			WithArg("auctionValidUntil", nil),
		).
			AssertSuccess(t).
			AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
				"status":              "active_ongoing",
				"amount":              price,
				"startsAt":            otu.currentTime(),
				"auctionReservePrice": price + 5.0,
				"id":                  id,
				"seller":              otu.O.Address("user1"),
			})
	})

	ot.Run(t, "Should be able to list a timed auction with previous start time", func(t *testing.T) {
		listingTx("listNFTForAuctionEscrowed",
			WithArg("auctionStartTime", otu.currentTime()-1.0),
			WithArg("auctionValidUntil", nil),
		).
			AssertSuccess(t).
			AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
				"status":              "active_ongoing",
				"amount":              price,
				"startsAt":            otu.currentTime(),
				"auctionReservePrice": price + 5.0,
				"id":                  id,
				"seller":              otu.O.Address("user1"),
			})
	})

	ot.Run(t, "Should be able to bid a timed auction that is started", func(t *testing.T) {
		listingTx("listNFTForAuctionEscrowed",
			WithArg("auctionStartTime", otu.currentTime()),
			WithArg("auctionValidUntil", nil),
		).
			AssertSuccess(t)

		otu.auctionBidMarketEscrow("user2", "user1", id, price+5.0)
	})

	ot.Run(t, "Should not be able to bid a timed auction that is not yet started", func(t *testing.T) {
		listingTx("listNFTForAuctionEscrowed",
			WithArg("auctionStartTime", otu.currentTime()+10.0),
			WithArg("auctionValidUntil", nil),
		).
			AssertSuccess(t)

		otu.O.Tx("bidMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price+5.0),
		).
			AssertFailure(t, fmt.Sprintf("Auction is not yet started, please place your bid after %2f", otu.currentTime()+10.0))
	})

	ot.Run(t, "Should be able to sell and buy at auction even the buyer didn't link receiver correctly", func(t *testing.T) {
		listingTx("listNFTForAuctionEscrowed",
			WithArg("auctionStartTime", otu.currentTime()),
			WithArg("auctionValidUntil", nil),
		).
			AssertSuccess(t)

		otu.saleItemListed("user1", "active_ongoing", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+5.0).
			fulfillMarketAuctionEscrow("user1", id, "user2", price+5.0)
	})
}
