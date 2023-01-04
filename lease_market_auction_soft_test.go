package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestLeaseMarketAuctionSoft(t *testing.T) {

	otu := NewOverflowTest(t)

	price := 10.0
	preIncrement := 5.0
	otu.setupMarketAndDandyDapper()
	otu.setFlowLeaseMarketOption("AuctionSoft").
		registerDUCInRegistry().
		setProfile("user1").
		setProfile("user2").
		createDapperUser("find")

	otu.registerDapperUserWithName("user1", "name1").
		registerDapperUserWithName("user1", "name2").
		registerDapperUserWithName("user1", "name3")

	otu.setUUID(400)

	t.Run("Should not be able to list an item for auction twice, and will give error message.", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price)

		otu.O.Tx("listLeaseForAuctionSoftDapper",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("price", price),
			WithArg("auctionReservePrice", price+5.0),
			WithArg("auctionDuration", 300.0),
			WithArg("auctionExtensionOnLateBid", 60.0),
			WithArg("minimumBidIncrement", 1.0),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Auction listing for this item is already created.")

		otu.delistAllLeaseForSoftAuction("user1")
	})

	t.Run("Should be able to sell at auction", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+5.0).
			fulfillLeaseMarketAuctionSoft("user2", "name1", 15.0)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to cancel listing if the pointer is no longer valid", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+5.0).
			moveNameTo("user1", "user2", "name1")

		otu.O.Tx("cancelLeaseMarketAuctionSoft",
			WithSigner("user1"),
			WithArg("leaseNames", `["name1"]`),
		).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"leaseName": "name1",
				"seller":    otu.O.Address("user1"),
				"buyer":     otu.O.Address("user2"),
				"amount":    15.0,
				"status":    "cancel_ghostlisting",
			})

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should not be able to list with price 0", func(t *testing.T) {

		otu.O.Tx(
			"listLeaseForAuctionSoftDapper",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("price", 0.0),
			WithArg("auctionReservePrice", price+5.0),
			WithArg("auctionDuration", 300.0),
			WithArg("auctionExtensionOnLateBid", 60.0),
			WithArg("minimumBidIncrement", 1.0),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Auction start price should be greater than 0")

	})

	t.Run("Should not be able to list with invalid reserve price", func(t *testing.T) {

		otu.O.Tx(
			"listLeaseForAuctionSoftDapper",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("price", price),
			WithArg("auctionReservePrice", price-5.0),
			WithArg("auctionDuration", 300.0),
			WithArg("auctionExtensionOnLateBid", 60.0),
			WithArg("minimumBidIncrement", 1.0),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Auction reserve price should be greater than Auction start price")

	})

	t.Run("Should not be able to list with invalid time", func(t *testing.T) {

		otu.O.Tx(
			"listLeaseForAuctionSoftDapper",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("price", price),
			WithArg("auctionReservePrice", price+5.0),
			WithArg("auctionDuration", 300.0),
			WithArg("auctionExtensionOnLateBid", 60.0),
			WithArg("minimumBidIncrement", 1.0),
			WithArg("auctionValidUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")

	})

	t.Run("Should be able to add bid at auction", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			increaseAuctionBidLeaseMarketSoft("user2", "name1", 5.0, price+10.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+10.0).
			fulfillLeaseMarketAuctionSoft("user2", "name1", price+10.0)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should not be able to bid expired auction listing", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			tickClock(1000.0)

		otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "This auction listing is already expired")

		otu.delistAllLeaseForSoftAuction("user1")
	})

	t.Run("Should not be able to bid your own listing", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price)

		otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "You cannot bid on your own resource")

		otu.delistAllLeaseForSoftAuction("user1")
	})

	t.Run("Should be able to cancel an auction", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price)

		name := "user1"

		otu.O.Tx("cancelLeaseMarketAuctionSoft",
			WithSigner(name),
			WithArg("leaseNames", `["name1"]`),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"leaseName": "name1",
				"seller":    otu.O.Address(name),
				"amount":    10.0,
				"status":    "cancel",
			})
	})

	t.Run("Should not be able to cancel an ended auction", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			tickClock(4000.0).
			saleLeaseListed("user1", "finished_completed", price+5.0)

		name := "user1"

		otu.O.Tx("cancelLeaseMarketAuctionSoft",
			WithSigner(name),
			WithArg("leaseNames", `["name1"]`),
		).
			AssertFailure(t, "Cannot cancel finished auction, fulfill it instead")

		otu.fulfillLeaseMarketAuctionSoft("user2", "name1", price+5.0).
			moveNameTo("user2", "user1", "name1")

	})

	t.Run("Cannot fulfill a not yet ended auction", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price)

		otu.auctionBidLeaseMarketSoft("user2", "name1", price+5.0)

		otu.tickClock(100.0)

		otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("account"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price+5.0),
		).
			AssertFailure(t, "Auction has not ended yet")

		otu.delistAllLeaseForSoftAuction("user1")
	})

	t.Run("Should allow seller to cancel auction if it failed to meet reserve price", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+1.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_failed", 11.0)

		buyer := "user2"
		name := "user1"

		otu.O.Tx("cancelLeaseMarketAuctionSoft",
			WithSigner(name),
			WithArg("leaseNames", `["name1"]`),
		).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"leaseName": "name1",
				"seller":    otu.O.Address(name),
				"buyer":     otu.O.Address(buyer),
				"amount":    11.0,
				"status":    "cancel_reserved_not_met",
			})
	})

	t.Run("Should be able to bid and increase bid by same user", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+preIncrement).
			saleLeaseListed("user1", "active_ongoing", price+preIncrement)

		otu.O.Tx("increaseBidLeaseMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", 0.1),
		).
			AssertFailure(t, "must be larger then previous bid+bidIncrement")

		otu.delistAllLeaseForSoftAuction("user1")
	})

	/* Tests on Rules */
	t.Run("Should not be able to list after deprecated", func(t *testing.T) {

		otu.alterLeaseMarketOption("AuctionSoft", "deprecate")

		otu.O.Tx("listLeaseForAuctionSoftDapper",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("price", price),
			WithArg("auctionReservePrice", price+preIncrement),
			WithArg("auctionDuration", 300.0),
			WithArg("auctionExtensionOnLateBid", 60.0),
			WithArg("minimumBidIncrement", 1.0),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.alterLeaseMarketOption("AuctionSoft", "enable")
	})

	t.Run("Should be able to bid, add bid , fulfill auction and delist after deprecated", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user1", "name1", price)

		otu.alterLeaseMarketOption("AuctionSoft", "deprecate")

		bitTx := otu.O.TxFN(
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		)

		bitTx("bidLeaseMarketAuctionSoftDapper").
			AssertSuccess(t)

		bitTx("increaseBidLeaseMarketAuctionSoft",
			WithArg("amount", price+10.0),
		).
			AssertSuccess(t)

		otu.tickClock(500.0)

		bitTx("fulfillLeaseMarketAuctionSoftDapper",
			WithPayloadSigner("account"),
			WithArg("amount", 30.0),
		).
			AssertSuccess(t)

		otu.alterLeaseMarketOption("AuctionSoft", "enable")

		otu.O.Tx("listLeaseForAuctionSoftDapper",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("price", price),
			WithArg("auctionReservePrice", price+5.0),
			WithArg("auctionDuration", 300.0),
			WithArg("auctionExtensionOnLateBid", 60.0),
			WithArg("minimumBidIncrement", 1.0),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertSuccess(t)

		otu.alterLeaseMarketOption("AuctionSoft", "deprecate")

		otu.O.Tx("cancelLeaseMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("leaseNames", `["name1"]`),
		).
			AssertSuccess(t)

		otu.alterLeaseMarketOption("AuctionSoft", "enable").
			moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should no be able to list, bid, add bid , fulfill auction and delist after stopped", func(t *testing.T) {

		otu.alterLeaseMarketOption("AuctionSoft", "stop")

		otu.O.Tx("listLeaseForAuctionSoftDapper",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "FUT"),
			WithArg("price", price),
			WithArg("auctionReservePrice", price+5.0),
			WithArg("auctionDuration", 300.0),
			WithArg("auctionExtensionOnLateBid", 60.0),
			WithArg("minimumBidIncrement", 1.0),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("AuctionSoft", "enable").
			listLeaseForSoftAuction("user1", "name1", price).
			alterLeaseMarketOption("AuctionSoft", "stop")

		otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("AuctionSoft", "enable").
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			alterLeaseMarketOption("AuctionSoft", "stop")

		otu.O.Tx("increaseBidLeaseMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price+10.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterLeaseMarketOption("AuctionSoft", "stop")

		otu.O.Tx("cancelLeaseMarketAuctionSoft",
			WithSigner("user1"),
			WithArg("leaseNames", `["name1"]`),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.tickClock(500.0)

		otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("account"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price+5.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		/* Reset */
		otu.alterLeaseMarketOption("AuctionSoft", "enable")

		otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("account"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price+5.0),
		).
			AssertSuccess(t)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should not be able to bid below listing price", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price)

		otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", 1.0),
		).
			AssertFailure(t, "You need to bid more then the starting price of 10.00000000")

		otu.delistAllLeaseForSoftAuction("user1")

	})

	t.Run("Should not be able to bid less the previous bidder", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0)

		otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
			WithSigner("user3"),
			WithArg("leaseName", "name1"),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "bid 5.00000000 must be larger then previous bid+bidIncrement 16.00000000")

		otu.delistAllLeaseForSoftAuction("user1")
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon fulfill action", func(t *testing.T) {

		price = 5.0

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0)

		otu.tickClock(500.0)

		otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("account"),
			WithArg("leaseName", "name1"),
			WithArg("amount", 10.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("user5-dapper"),
				"amount":      0.65,
				"royaltyName": "find",
			})

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		price = 5.0

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			setFindLeaseCutDapper(0.1)

		otu.tickClock(500.0)

		otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("account"),
			WithArg("leaseName", "name1"),
			WithArg("amount", 10.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.O.Address("user5-dapper"),
				"amount":      1.0,
				"royaltyName": "find",
			})

		otu.moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			listLeaseForSoftAuction("user1", "name2", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			tickClock(400.0).
			leaseProfileBan("user1")

		otu.O.Tx("listLeaseForAuctionSoftDapper",
			WithSigner("user1"),
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
			WithSigner("user2"),
			WithArg("leaseName", "name2"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("account"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price+5.0),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("cancelLeaseMarketAuctionSoft",
			WithSigner("user1"),
			WithArg("leaseNames", `["name2"]`),
		).
			AssertSuccess(t)

		otu.removeLeaseProfileBan("user1")

		otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("account"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price+5.0),
		).
			AssertSuccess(t)

		otu.delistAllLeaseForSoftAuction("user1").
			moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should be able to ban user, user cannot bid NFT.", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			listLeaseForSoftAuction("user1", "name2", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			tickClock(400.0).
			leaseProfileBan("user2")

		otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithArg("leaseName", "name2"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("account"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price+5.0),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		/* Reset */
		otu.removeLeaseProfileBan("user2")

		otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("account"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price+5.0),
		).
			AssertSuccess(t)

		otu.delistAllLeaseForSoftAuction("user1").
			moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should emit previous bidder if outbid", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			saleLeaseListed("user1", "active_ongoing", price+5.0)

		otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
			WithSigner("user3"),
			WithArg("leaseName", "name1"),
			WithArg("amount", 20.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"amount":        20.0,
				"leaseName":     "name1",
				"buyer":         otu.O.Address("user3"),
				"previousBuyer": otu.O.Address("user2"),
				"status":        "active_ongoing",
			})

		otu.delistAllLeaseForSoftAuction("user1")
	})

	t.Run("Should be able to list an NFT for auction and bid it with DUC", func(t *testing.T) {

		otu.createDapperUser("user1").
			createDapperUser("user2")

		otu.setDUCLease()

		otu.listLeaseForSoftAuctionDUC("user1", "name1", price)

		otu.saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoftDUC("user2", "name1", price+5.0)

		otu.O.Tx("increaseBidLeaseMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", 5.0),
		).
			AssertSuccess(t)

		otu.tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+10.0).
			fulfillLeaseMarketAuctionSoftDUC("user2", "name1", price+10.0)

		otu.moveNameTo("user2", "user1", "name1")
	})

}
