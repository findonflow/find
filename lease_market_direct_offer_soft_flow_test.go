package test_main

import (
	"testing"
)

func TestLeaseMarketDirectOfferSoftFlow(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	price := 10.0


	ot.Run(t, "Should be able to add direct offer and then sell", func(t *testing.T) {
		otu.directOfferLeaseMarketSoftFlow("user2", "user1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoftFlow("user2", "user1", "user1", price).
			saleLeaseListed("user1", "active_finished", price).
			fulfillLeaseMarketDirectOfferSoftFlow("user2", "user1", price)
	})
}
