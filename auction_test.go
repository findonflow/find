package main

import (
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestAuction(t *testing.T) {

	t.Run("Should list a name for sale", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

		createUser(g, t, "100.0", "user1")
		registerUser(g, t, "user1")

		g.TransactionFromFile("sell").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"name":      "user1",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

	})

	t.Run("Should be able to sell lease", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

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
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
				"name":      "user1",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "10.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":          "user1",
			}))

		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("86401.0").Test(t).AssertSuccess()

		g.TransactionFromFile("fullfill").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sold", map[string]interface{}{
				"amount":        "10.00000000",
				"expireAt":      "31536001.00000000",
				"newOwner":      "0xf3fcd2c1a78f5eee",
				"previousOwner": "0x179b6b1cb6755e31",
				"name":           "user1",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "9.75000000",
				"to":     "0x179b6b1cb6755e31",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "0.25000000",
				"to":     "0x1cf0e2f2f715450",
			}))

	})

	t.Run("Should not start auction if bid lower then sale price", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

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
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"name":      "user1",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.BlindBid", map[string]interface{}{
				"amount": "5.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":    "user1",
			}))

	})

	t.Run("Should start auction if we start out with smaller bid and then increase it", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

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
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"name":      "user1",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.BlindBid", map[string]interface{}{
				"amount": "5.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":    "user1",
			}))

		g.TransactionFromFile("increaseBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "10.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":          "user1",
			}))

	})

	t.Run("Should be able to manually start auction with lower bid", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

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
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"name":      "user1",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.BlindBid", map[string]interface{}{
				"amount": "5.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":    "user1",
			}))

		g.TransactionFromFile("startAuction").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "5.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":          "user1",
			}))

	})

	t.Run("Should be able to cancel blind bid", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

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
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"name":      "user1",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.BlindBid", map[string]interface{}{
				"amount": "5.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":    "user1",
			}))

		g.TransactionFromFile("cancelBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.BlindBidCanceled", map[string]interface{}{
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":    "user1",
			}))

	})

	t.Run("Should not be able to cancel bid when auction has started", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

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
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"name":      "user1",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.BlindBid", map[string]interface{}{
				"amount": "5.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":    "user1",
			}))

		g.TransactionFromFile("startAuction").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "5.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":          "user1",
			}))

		g.TransactionFromFile("cancelBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			Test(t).
			AssertFailure("Cannot cancel a bid that is in an auction")
	})

	t.Run("Should return money if outbid", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

		createUser(g, t, "100.0", "user1")
		registerUser(g, t, "user1")
		createUser(g, t, "100.0", "user2")
		registerUser(g, t, "user2")

		createUser(g, t, "100.0", "user3")
		registerUser(g, t, "user3")

		g.TransactionFromFile("sell").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"name":      "user1",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "10.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":          "user1",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user3").
			StringArgument("user1").
			UFix64Argument("15.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "10.00000000",
				"to":     "0xf3fcd2c1a78f5eee",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionBid", map[string]interface{}{
				"amount":       "15.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xe03daebed8ca0615",
				"name":          "user1",
			}))

	})

	t.Run("Should extend auction on late bid", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

		createUser(g, t, "100.0", "user1")
		registerUser(g, t, "user1")
		createUser(g, t, "100.0", "user2")
		registerUser(g, t, "user2")

		createUser(g, t, "100.0", "user3")
		registerUser(g, t, "user3")

		g.TransactionFromFile("sell").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"name":      "user1",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "10.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":          "user1",
			}))

		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("86380.0").Test(t).AssertSuccess()
		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user3").
			StringArgument("user1").
			UFix64Argument("15.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "10.00000000",
				"to":     "0xf3fcd2c1a78f5eee",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionBid", map[string]interface{}{
				"amount":       "15.00000000",
				"auctionEndAt": "86681.00000000", //auction is extended
				"bidder":       "0xe03daebed8ca0615",
				"name":          "user1",
			}))

	})

	t.Run("Should not be able to cancel finished auction", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

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
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
				"name":      "user1",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "10.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":          "user1",
			}))

		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("86402.0").Test(t).AssertSuccess()

		g.TransactionFromFile("cancelAuction").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertFailure("Cannot cancel finished auction")

	})

	t.Run("Should be able to cancel unfinished auction", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

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
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
				"name":      "user1",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "10.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":          "user1",
			}))

		g.TransactionFromFile("cancelAuction").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "10.00000000",
				"to":     "0xf3fcd2c1a78f5eee",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensWithdrawn", map[string]interface{}{
				"amount": "10.00000000",
				"from":   "0xf3fcd2c1a78f5eee",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionCancelled", map[string]interface{}{
				"amount": "10.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":    "user1",
			}))
	})

	t.Run("Should be able to reject blind bid", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

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
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
				"name":      "user1",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.BlindBid", map[string]interface{}{
				"amount": "5.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":    "user1",
			}))

		g.TransactionFromFile("cancelAuction").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
				"to":     "0xf3fcd2c1a78f5eee",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensWithdrawn", map[string]interface{}{
				"amount": "5.00000000",
				"from":   "0xf3fcd2c1a78f5eee",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.BlindBidRejected", map[string]interface{}{
				"amount": "5.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":    "user1",
			}))
	})

	t.Run("Should not be able to bid on lease that is free, and not cleaned up", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

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
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.ForSale", map[string]interface{}{
				"active":   "true",
				"amount":   "10.00000000",
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
				"name":      "user1",
			}))

		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("71536001.00000000").Test(t).AssertSuccess()
		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("71536001.00000000").Test(t).AssertSuccess()

		g.TransactionFromFile("update_status").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.JanitorLock", map[string]interface{}{
				"lockedUntil": "150848003.00000000",
				"name":         "user1",
			}))
		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("71536001.00000000").Test(t).AssertSuccess()

		g.TransactionFromFile("update_status").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.JanitorFree", map[string]interface{}{
				"name": "user1",
			}))

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertFailure("cannot bid on name that is free")

	})
	//TODO; if bid on item and it gets cleaned up bid should be paid back
	//TODO: make test methods
}
