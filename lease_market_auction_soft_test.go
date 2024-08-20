package test_main

import (
	"testing"
)

func TestLeaseMarketAuctionSoftFlow(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	price := 10.0

	ot.Run(t, "Should be able to sell at auction", func(t *testing.T) {

		otu.listLeaseForSoftAuctionFlow("user1", "user1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoftFlow("user2", "user1", price+5.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+5.0).
			fulfillLeaseMarketAuctionSoftFlow("user2", "user1", 15.0)
	})
}
