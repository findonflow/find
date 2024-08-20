package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestLeaseMarketDirectOfferSoftFlow(t *testing.T) {
	otu := NewOverflowTest(t).
		setupFIND().
		createUser(100.0, "user1").registerUser("user1").
		createUser(100.0, "user2").registerUser("user2").
		createUser(100.0, "user3").registerUser("user3").
		registerFtInRegistry().
		setFlowLeaseMarketOption().
		setProfile("user1").
		setProfile("user2")

	price := 10.0

	otu.registerUserWithName("user1", "name1")
	otu.registerUserWithName("user1", "name2")
	otu.registerUserWithName("user1", "name3")

	otu.setUUID(500)

	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {
		otu.directOfferLeaseMarketSoftFlow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			acceptLeaseDirectOfferMarketSoftFlow("user2", "user1", "name1", price).
			saleLeaseListed("user1", "active_finished", price).
			fulfillLeaseMarketDirectOfferSoftFlow("user2", "name1", price)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to reject offer if the pointer is no longer valid", func(t *testing.T) {
		otu.directOfferLeaseMarketSoftFlow("user2", "name1", price).
			saleLeaseListed("user1", "active_ongoing", price).
			moveNameTo("user1", "user2", "name1")

		otu.O.Tx("cancelLeaseMarketDirectOfferSoft",
			WithSigner("user1"),
			WithArg("leaseNames", `["name1"]`),
		).
			AssertSuccess(t)

		otu.moveNameTo("user2", "user1", "name1")
	})
}
