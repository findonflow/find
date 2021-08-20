package main

import (
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestAuction(t *testing.T) {

	t.Run("Should list a tag for sale", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIN(g, t, "5.0")

		createUser(g, t, "100.0", "user1")
		registerUser(g, t, "user1")

		g.TransactionFromFile("sell").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIN.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"tag":      "user1",
				"expireAt": "6.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

	})

	t.Run("Should not start auction if bid lower then sale price", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIN(g, t, "5.0")

		createUser(g, t, "100.0", "user1")
		registerUser(g, t, "user1")
		createUser(g, t, "100.0", "user2")
		registerUser(g, t, "user2")

		g.TransactionFromFile("sell").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIN.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"tag":      "user1",
				"expireAt": "6.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIN.BlindBid", map[string]interface{}{
				"amount": "5.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"tag":    "user1",
			}))

	})

	t.Run("Should start auction if we start out with smaller bid and then increase it", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIN(g, t, "5.0")

		createUser(g, t, "100.0", "user1")
		registerUser(g, t, "user1")
		createUser(g, t, "100.0", "user2")
		registerUser(g, t, "user2")

		g.TransactionFromFile("sell").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIN.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"tag":      "user1",
				"expireAt": "6.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

		res := g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIN.BlindBid", map[string]interface{}{
				"amount": "5.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"tag":    "user1",
			}))

		res = g.TransactionFromFile("increaseBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIN.AuctionStarted", map[string]interface{}{
				"amount":       "10.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"tag":          "user1",
			}))

		for _, ev := range res.Events {
			t.Log(ev.String())
		}
	})

	t.Run("Should be able to manually start auction with lower bid", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIN(g, t, "5.0")

		createUser(g, t, "100.0", "user1")
		registerUser(g, t, "user1")
		createUser(g, t, "100.0", "user2")
		registerUser(g, t, "user2")

		g.TransactionFromFile("sell").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIN.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"tag":      "user1",
				"expireAt": "6.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIN.BlindBid", map[string]interface{}{
				"amount": "5.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"tag":    "user1",
			}))

		res := g.TransactionFromFile("startAuction").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIN.AuctionStarted", map[string]interface{}{
				"amount":       "5.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"tag":          "user1",
			}))

		for _, ev := range res.Events {
			t.Log(ev.String())
		}
	})

}
