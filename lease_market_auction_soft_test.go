package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestLeaseMarketAuctionSoft(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	price := 10.0
	preIncrement := 5.0

	eventIdentifier := otu.identifier("FindLeaseMarketAuctionSoft", "EnglishAuction")
	royaltyIdentifier := otu.identifier("FindLeaseMarket", "RoyaltyPaid")

	bidTx := otu.O.TxFileNameFN("bidLeaseMarketAuctionSoftDapper",
		WithSigner("user6"),
		WithArg("leaseName", "user5"),
		WithArg("amount", price),
	)

	increaseBidTx := otu.O.TxFileNameFN("increaseBidLeaseMarketAuctionSoft",
		WithSigner("user6"),
		WithArg("leaseName", "user5"),
		WithArg("amount", preIncrement),
	)

	listTx := otu.O.TxFileNameFN("listLeaseForAuctionSoftDapper",
		WithSigner("user5"),
		WithArg("leaseName", "user5"),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+10.0),
	)
	ot.Run(t, "Should not be able to list an item for auction twice, and will give error message.", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price)

		listTx().AssertFailure(t, "Auction listing for this item is already created.")
	})

	ot.Run(t, "Should be able to sell at auction", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price).
			auctionBidLeaseMarketSoft("user6", "user5", price+5.0).
			tickClock(400.0).
			saleLeaseListed("user5", "finished_completed", price+5.0).
			fulfillLeaseMarketAuctionSoft("user6", "user5", 15.0)
	})

	ot.Run(t, "Should be able to cancel listing if the pointer is no longer valid", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price).
			auctionBidLeaseMarketSoft("user6", "user5", price+5.0).
			tickClock(400.0).
			saleLeaseListed("user5", "finished_completed", price+5.0).
			moveNameTo("user5", "user6", "user5")

		otu.O.Tx("cancelLeaseMarketAuctionSoft",
			WithSigner("user5"),
			WithArg("leaseNames", `["user5"]`),
		).AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"seller": otu.O.Address("user5"),
				"buyer":  otu.O.Address("user6"),
				"amount": 15.0,
				"status": "cancel_ghostlisting",
			})
	})

	ot.Run(t, "Should not be able to list with price 0", func(t *testing.T) {
		listTx(WithArg("price", 0.0)).
			AssertFailure(t, "Auction start price should be greater than 0")
	})

	ot.Run(t, "Should not be able to list with invalid reserve price", func(t *testing.T) {
		listTx(WithArg("auctionReservePrice", price-5.0)).
			AssertFailure(t, "Auction reserve price should be greater than Auction start price")
	})

	ot.Run(t, "Should not be able to list with invalid time", func(t *testing.T) {
		listTx(WithArg("auctionValidUntil", 0.0)).
			AssertFailure(t, "Valid until is before current time")
	})

	ot.Run(t, "Should be able to add bid at auction", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price).
			auctionBidLeaseMarketSoft("user6", "user5", price+5.0).
			increaseAuctionBidLeaseMarketSoft("user6", "user5", 5.0, price+10.0).
			tickClock(400.0).
			saleLeaseListed("user5", "finished_completed", price+10.0).
			fulfillLeaseMarketAuctionSoft("user6", "user5", price+10.0)
	})

	ot.Run(t, "Should not be able to bid expired auction listing", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price).
			tickClock(1000.0)

		bidTx().AssertFailure(t, "This auction listing is already expired")
	})

	ot.Run(t, "Should not be able to bid your own listing", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price)

		bidTx(WithSigner("user5")).
			AssertFailure(t, "You cannot bid on your own resource")
	})

	ot.Run(t, "Should be able to cancel an auction", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price)

		name := "user5"

		otu.O.Tx("cancelLeaseMarketAuctionSoft",
			WithSigner(name),
			WithArg("leaseNames", `["user5"]`),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"seller": otu.O.Address(name),
				"amount": 10.0,
				"status": "cancel",
			})
	})

	ot.Run(t, "Should not be able to cancel an ended auction", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price).
			auctionBidLeaseMarketSoft("user6", "user5", price+5.0).
			tickClock(4000.0).
			saleLeaseListed("user5", "finished_completed", price+5.0)

		name := "user5"

		otu.O.Tx("cancelLeaseMarketAuctionSoft",
			WithSigner(name),
			WithArg("leaseNames", `["user5"]`),
		).
			AssertFailure(t, "Cannot cancel finished auction, fulfill it instead")

		otu.fulfillLeaseMarketAuctionSoft("user6", "user5", price+5.0)
	})

	ot.Run(t, "Cannot fulfill a not yet ended auction", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price)

		otu.auctionBidLeaseMarketSoft("user6", "user5", price+5.0)

		otu.tickClock(100.0)

		otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("leaseName", "user5"),
			WithArg("amount", price+5.0),
		).
			AssertFailure(t, "Auction has not ended yet")
	})

	ot.Run(t, "Should allow seller to cancel auction if it failed to meet reserve price", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price).
			auctionBidLeaseMarketSoft("user6", "user5", price+1.0).
			tickClock(400.0).
			saleLeaseListed("user5", "finished_failed", 11.0)

		buyer := "user6"
		name := "user5"

		otu.O.Tx("cancelLeaseMarketAuctionSoft",
			WithSigner(name),
			WithArg("leaseNames", `["user5"]`),
		).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"seller": otu.O.Address(name),
				"buyer":  otu.O.Address(buyer),
				"amount": 11.0,
				"status": "cancel_reserved_not_met",
			})
	})

	ot.Run(t, "Should be able to bid and increase bid by same user", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price).
			auctionBidLeaseMarketSoft("user6", "user5", price+preIncrement).
			saleLeaseListed("user5", "active_ongoing", price+preIncrement)

		increaseBidTx(WithArg("amount", 0.1)).
			AssertFailure(t, "must be larger then previous bid+bidIncrement")
	})

	ot.Run(t, "Should not be able to list after deprecated", func(t *testing.T) {
		otu.alterLeaseMarketOption("deprecate")

		listTx().AssertFailure(t, "Tenant has deprected mutation options on this item")
	})

	ot.Run(t, "Should not be able to bid below listing price", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price)

		bidTx(WithArg("amount", 1.0)).
			AssertFailure(t, "You need to bid more then the starting price of 10.00000000")
	})

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	ot.Run(t, "Royalties should be sent to correspondence upon fulfill action", func(t *testing.T) {
		price = 5.0

		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price).
			auctionBidLeaseMarketSoft("user6", "user5", price+5.0)

		otu.tickClock(500.0)

		otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("leaseName", "user5"),
			WithArg("amount", 10.0),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"royaltyName": "find",
			})
	})
	/*

		t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

			otu.listLeaseForSoftAuction("user5", "user5", price).
				listLeaseForSoftAuction("user5", "name2", price).
				auctionBidLeaseMarketSoft("user6", "user5", price+5.0).
				tickClock(400.0).
				leaseProfileBan("user5")

			otu.O.Tx("listLeaseForAuctionSoftDapper",
				WithSigner("user5"),
				WithArg("leaseName", "name3"),
				WithArg("ftAliasOrIdentifier", "FUT"),
				WithArg("price", price),
				WithArg("auctionReservePrice", price+5.0),
				WithArg("auctionDuration", 300.0),
				WithArg("auctionExtensionOnLateBid", 60.0),
				WithArg("minimumBidIncrement", 1.0),
				WithArg("auctionValidUntil", otu.currentTime()+10.0),
			).
				AssertFailure(t, "Seller banned by Tenant")

			otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithArg("leaseName", "name2"),
				WithArg("amount", price),
			).
				AssertFailure(t, "Seller banned by Tenant")

			otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithPayloadSigner("dapper"),
				WithArg("leaseName", "user5"),
				WithArg("amount", price+5.0),
			).
				AssertFailure(t, "Seller banned by Tenant")

			otu.O.Tx("cancelLeaseMarketAuctionSoft",
				WithSigner("user5"),
				WithArg("leaseNames", `["name2"]`),
			).
				AssertSuccess(t)

			otu.removeLeaseProfileBan("user5")

			otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithPayloadSigner("dapper"),
				WithArg("leaseName", "user5"),
				WithArg("amount", price+5.0),
			).
				AssertSuccess(t)

			otu.delistAllLeaseForSoftAuction("user5").
				moveNameTo("user6", "user5", "user5")

		})

		t.Run("Should be able to ban user, user cannot bid NFT.", func(t *testing.T) {

			otu.listLeaseForSoftAuction("user5", "user5", price).
				listLeaseForSoftAuction("user5", "name2", price).
				auctionBidLeaseMarketSoft("user6", "user5", price+5.0).
				tickClock(400.0).
				leaseProfileBan("user6")

			otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithArg("leaseName", "name2"),
				WithArg("amount", price),
			).
				AssertFailure(t, "Buyer banned by Tenant")

			otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithPayloadSigner("dapper"),
				WithArg("leaseName", "user5"),
				WithArg("amount", price+5.0),
			).
				AssertFailure(t, "Buyer banned by Tenant")

			otu.removeLeaseProfileBan("user6")

			otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
				WithSigner("user6"),
				WithPayloadSigner("dapper"),
				WithArg("leaseName", "user5"),
				WithArg("amount", price+5.0),
			).
				AssertSuccess(t)

			otu.delistAllLeaseForSoftAuction("user5").
				moveNameTo("user6", "user5", "user5")

		})

	*/
	ot.Run(t, "Should emit previous bidder if outbid", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user5", "user5", price).
			saleLeaseListed("user5", "active_listed", price).
			auctionBidLeaseMarketSoft("user6", "user5", price+5.0).
			saleLeaseListed("user5", "active_ongoing", price+5.0)

		otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
			WithSigner("user7"),
			WithArg("leaseName", "user5"),
			WithArg("amount", 20.0),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount":        20.0,
				"buyer":         otu.O.Address("user7"),
				"previousBuyer": otu.O.Address("user6"),
				"status":        "active_ongoing",
			})
	})

	ot.Run(t, "Should be able to list an NFT for auction and bid it with DUC", func(t *testing.T) {
		otu.listLeaseForSoftAuctionDUC("user5", "user5", price)

		otu.saleLeaseListed("user5", "active_listed", price).
			auctionBidLeaseMarketSoftDUC("user6", "user5", price+5.0)

		otu.O.Tx("increaseBidLeaseMarketAuctionSoft",
			WithSigner("user6"),
			WithArg("leaseName", "user5"),
			WithArg("amount", 5.0),
		).
			AssertSuccess(t)

		otu.tickClock(400.0).
			saleLeaseListed("user5", "finished_completed", price+10.0).
			fulfillLeaseMarketAuctionSoftDUC("user6", "user5", price+10.0)
	})
}
