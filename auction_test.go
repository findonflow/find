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

	t.Run("Should be able to sell lease from auction, buyer can fulfill auction", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			createUser("100.0", "user3").
			registerUser("user1").
			registerUser("user2").
			registerUser("user3").
			listForAuction("user1").
			bid("user2", "user1", "8.0").
			auctionBid("user3", "user1", "20.0").
			expireAuction()

		gt.GWTF.TransactionFromFile("fulfillAuction").
			SignProposeAndPayAs("user3"). //the buy
			AccountArgument("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sold", map[string]interface{}{
				"amount":        "20.00000000",
				"expireAt":      "31536001.00000000",
				"newOwner":      "0xe03daebed8ca0615",
				"previousOwner": "0x179b6b1cb6755e31",
				"name":          "user1",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "19.00000000",
				"to":     "0x179b6b1cb6755e31",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "1.00000000",
				"to":     "0x1cf0e2f2f715450",
			}))

	})

	t.Run("Should be able to sell lease from offer directly", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1")

		buyer := "user2"
		name := "user1"
		amount := "10.0"

		gt.GWTF.TransactionFromFile("bid").SignProposeAndPayAs(buyer).
			StringArgument(name).
			UFix64Argument(amount).
			Test(gt.T).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sold", map[string]interface{}{
				"amount":        "10.00000000",
				"expireAt":      "31536001.00000000",
				"newOwner":      "0xf3fcd2c1a78f5eee",
				"previousOwner": "0x179b6b1cb6755e31",
				"name":          "user1",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "9.50000000",
				"to":     "0x179b6b1cb6755e31",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "0.50000000",
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
			listForAuction("user1").
			blindBid("user2", "user1", "4.0")

	})

	t.Run("Should start auction if we start out with smaller bid and then increase it with locked user", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			expireLease().
			listForAuction("user1").
			blindBid("user2", "user1", "4.0")

		gt.GWTF.TransactionFromFile("increaseBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("4.0").
			Test(t).
			AssertSuccess().
			AssertPartialEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount": "8.00000000",
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":   "user1",
			}))
	})

	t.Run("Should not allow double bid from same author", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			expireLease().
			listForAuction("user1").
			bid("user2", "user1", "10.0")

		gt.GWTF.TransactionFromFile("bid").SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("15.0").
			Test(gt.T).
			AssertFailure("You already have the latest bid on this item, use the incraseBid transaction")

	})

	t.Run("Should start auction if we start out with smaller bid and then increase it", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			blindBid("user2", "user1", "4.0")

		gt.GWTF.TransactionFromFile("increaseBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("4.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "8.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":         "user1",
			}))
	})

	t.Run("Should be able to increase auction bid", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			bid("user2", "user1", "5.0")

		gt.GWTF.TransactionFromFile("increaseBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("3.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionBid", map[string]interface{}{
				"amount":       "8.00000000",
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
			listForAuction("user1").
			blindBid("user2", "user1", "4.0")

		gt.GWTF.TransactionFromFile("startAuction").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionStarted", map[string]interface{}{
				"amount":       "4.00000000",
				"auctionEndAt": "86401.00000000",
				"bidder":       "0xf3fcd2c1a78f5eee",
				"name":         "user1",
			}))

	})

	//todo test when user is locked
	t.Run("Should be able to cancel blind bid", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			blindBid("user2", "user1", "4.0")

		gt.GWTF.TransactionFromFile("cancelBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.DirectOfferCanceled", map[string]interface{}{
				"bidder": "0xf3fcd2c1a78f5eee",
				"name":   "user1",
			}))
	})

	t.Run("Should be able to cancel blind bid when user locked", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			blindBid("user2", "user1", "4.0").
			expireLease()

		gt.assertLookupAddress("user2", "")

		gt.GWTF.TransactionFromFile("cancelBid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.DirectOfferCanceled", map[string]interface{}{
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
			listForAuction("user1").
			bid("user2", "user1", "5.0")

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
			listForAuction("user1").
			bid("user2", "user1", "5.0")

		gt.GWTF.TransactionFromFile("bid").
			SignProposeAndPayAs("user3").
			StringArgument("user1").
			UFix64Argument("15.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
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
			listForAuction("user1").
			bid("user2", "user1", "5.0")

		gt.tickClock("86380.0")

		gt.GWTF.TransactionFromFile("bid").
			SignProposeAndPayAs("user3").
			StringArgument("user1").
			UFix64Argument("15.0").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
				"to":     "0xf3fcd2c1a78f5eee",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionBid", map[string]interface{}{
				"amount":       "15.00000000",
				"auctionEndAt": "86681.00000000", //auction is extended
				"bidder":       "0xe03daebed8ca0615",
				"name":         "user1",
			}))

	})

	t.Run("Should be able to cancel unfinished auction", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			bid("user2", "user1", "5.0")

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
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AuctionCancelled", map[string]interface{}{
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
		gt.expireLock().tickClock("2.0")

		gt.GWTF.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertFailure("cannot bid on name that is free")

	})

	t.Run("Should not be able to cancel finished auction", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			bid("user2", "user1", "25.0").
			expireAuction().tickClock("2.0")

		gt.GWTF.TransactionFromFile("cancelAuction").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertFailure("Cannot cancel finished auction")

	})

}

//TODO: Fullfillment of auction that had a name that was locked
//TODO: cancel an auction that did not meets its price as the bidder
//TODO: test new lease information
