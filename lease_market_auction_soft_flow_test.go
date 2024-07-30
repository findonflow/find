package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestLeaseMarketAuctionSoftFlow(t *testing.T) {
	price := 10.0
	//	preIncrement := 5.0
	otu := NewOverflowTest(t).
		setupFIND().
		createUser(100.0, "user1").registerUser("user1").
		createUser(100.0, "user2").registerUser("user2").
		createUser(100.0, "user3").registerUser("user3").
		registerFtInRegistry().
		setFlowLeaseMarketOption().
		setProfile("user1").
		setProfile("user2")

	otu.registerUserWithName("user1", "name1")
	otu.registerUserWithName("user1", "name2")
	otu.registerUserWithName("user1", "name3")
	otu.setUUID(500)

	//	eventIdentifier := otu.identifier("FindLeaseMarketAuctionSoft", "EnglishAuction")
	//	royaltyIdentifier := otu.identifier("FindLeaseMarket", "RoyaltyPaid")

	t.Run("Should not be able to list an item for auction twice, and will give error message.", func(t *testing.T) {
		otu.listLeaseForSoftAuctionFlow("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price)

		otu.O.Tx("listLeaseForAuctionSoft",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", "Flow"),
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
		otu.listLeaseForSoftAuctionFlow("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoftFlow("user2", "name1", price+5.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+5.0).
			fulfillLeaseMarketAuctionSoftFlow("user2", "name1", 15.0)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to add bid at auction", func(t *testing.T) {
		otu.listLeaseForSoftAuctionFlow("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoftFlow("user2", "name1", price+5.0).
			increaseAuctionBidLeaseMarketSoft("user2", "name1", 5.0, price+10.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+10.0).
			fulfillLeaseMarketAuctionSoftFlow("user2", "name1", price+10.0)

		otu.moveNameTo("user2", "user1", "name1")
	})
}
