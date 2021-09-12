package test_main

import (
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestAuction(t *testing.T) {

	t.Run("Should list a name for sale", func(t *testing.T) {

		NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			registerUser("user1").
			listForSale("user1")

	})

	t.Run("Should be able to sell lease from auction, buyer can fullfill auction", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			bid("user2", "user1", "10.0").
			expireAuction()

		gt.GWTF.TransactionFromFile("fullfill_auction").
			SignProposeAndPayAs("user2"). //the buy
			AccountArgument("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sold", map[string]interface{}{
				"amount":        "10.00000000",
				"expireAt":      "31536001.00000000",
				"newOwner":      "0xf3fcd2c1a78f5eee",
				"previousOwner": "0x179b6b1cb6755e31",
				"name":          "user1",
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

	t.Run("Should be able to sell lease from offer", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			blindBid("user2", "user1", "10.0")

		gt.GWTF.TransactionFromFile("fullfill").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sold", map[string]interface{}{
				"amount":        "10.00000000",
				"expireAt":      "31536001.00000000",
				"newOwner":      "0xf3fcd2c1a78f5eee",
				"previousOwner": "0x179b6b1cb6755e31",
				"name":          "user1",
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

		NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			blindBid("user2", "user1", "5.0")

	})

	t.Run("Should start auction if we start out with smaller bid and then increase it", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			blindBid("user2", "user1", "5.0")

		gt.GWTF.TransactionFromFile("increaseBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "10.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":         "user1",
			}))

	})

	t.Run("Should be able to manually start auction with lower bid", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			blindBid("user2", "user1", "5.0")

		gt.GWTF.TransactionFromFile("startAuction").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "5.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":         "user1",
			}))

	})

	t.Run("Should be able to cancel blind bid", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			blindBid("user2", "user1", "5.0")

		gt.GWTF.TransactionFromFile("cancelBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.BlindBidCanceled", map[string]interface{}{
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":   "user1",
			}))

	})

	t.Run("Should not be able to cancel bid when auction has started", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			bid("user2", "user1", "10.0")

		gt.GWTF.TransactionFromFile("cancelBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			Test(t).
			AssertFailure("Cannot cancel a bid that is in an auction")
	})

	t.Run("Should return money if outbid", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			createUser("100.0", "user3").
			registerUser("user1").
			registerUser("user2").
			registerUser("user3").
			listForSale("user1").
			bid("user2", "user1", "10.0")

		gt.GWTF.TransactionFromFile("bid").
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
				"name":         "user1",
			}))

	})

	t.Run("Should extend auction on late bid", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			createUser("100.0", "user3").
			registerUser("user1").
			registerUser("user2").
			registerUser("user3").
			listForSale("user1").
			bid("user2", "user1", "10.0")

		gt.tickClock("86380.0")

		gt.GWTF.TransactionFromFile("bid").
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
				"name":         "user1",
			}))

	})

	t.Run("Should not be able to cancel finished auction", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			bid("user2", "user1", "10.0").
			expireAuction().tickClock("2.0")

		gt.GWTF.TransactionFromFile("cancelAuction").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertFailure("Cannot cancel finished auction")

	})

	t.Run("Should be able to cancel unfinished auction", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			bid("user2", "user1", "10.0")

		gt.GWTF.TransactionFromFile("cancelAuction").
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
				"name":   "user1",
			}))
	})

	t.Run("Should be able to reject blind bid", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			blindBid("user2", "user1", "5.0")

		gt.GWTF.TransactionFromFile("cancelAuction").
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
				"name":   "user1",
			}))
	})

	t.Run("Should not be able to bid on lease that is free, and not cleaned up", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1")

		gt.expireLease().tickClock("2.0")

		gt.GWTF.TransactionFromFile("janitor").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Locked", map[string]interface{}{
				"lockedUntil": "39312003.00000000",
				"name":        "user1",
			}))

		gt.expireLock().tickClock("2.0")

		gt.GWTF.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertFailure("cannot bid on name that is free")

	})

}
