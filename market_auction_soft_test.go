package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
)

func TestMarketAuctionSoft(t *testing.T) {

	t.Run("Should be able to sell at auction", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "ondemand_auction", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			tickClock(400.0).
			//TODO: Should status be something else while time has not run out? I think so
			saleItemListed("user1", "ongoing_auction", price+5.0).
			fulfillMarketAuctionSoft("user2", id, price+5.0)
	})

	t.Run("Should allow seller to cancel auction if it failed to meet reserve price", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "ondemand_auction", price).
			auctionBidMarketSoft("user2", "user1", id, price+1.0).
			tickClock(400.0).
			saleItemListed("user1", "ongoing_auction", 11.0)

		buyer := "user2"
		name := "user1"
		otu.O.TransactionFromFile("cancelMarketAuctionSoft").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				UInt64(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionSoft.ForAuction", map[string]interface{}{
				"id":     fmt.Sprintf("%d", id),
				"seller": otu.accountAddress(name),
				"buyer":  otu.accountAddress(buyer),
				"amount": fmt.Sprintf("%.8f", 11.0),
				"status": "failed",
			}))
	})

	t.Run("Should be able to bid and increase bid by same user", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		preIncrement := 5.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "ondemand_auction", price).
			auctionBidMarketSoft("user2", "user1", id, price+preIncrement).
			saleItemListed("user1", "ongoing_auction", price+preIncrement)

		otu.O.TransactionFromFile("increaseBidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				UInt64(id).
				UFix64(0.1)).
			Test(otu.T).
			AssertFailure("must be larger then previous bid+bidIncrement")

	})

	/* Tests on Rules */
	t.Run("Should not be able to list after deprecated", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		preIncrement := 5.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("AuctionSoft")

		otu.alterMarketOption("AuctionSoft", "deprecate")

		otu.O.TransactionFromFile("listNFTForAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(price + preIncrement).
				UFix64(300.0).
				UFix64(60.0).
				UFix64(1.0)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

	})

	t.Run("Should be able to bid, add bid , fulfill auction and delist after deprecated", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price)

		otu.alterMarketOption("AuctionSoft", "deprecate")

		otu.O.TransactionFromFile("bidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).AssertSuccess()

		otu.O.TransactionFromFile("increaseBidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				UInt64(id).
				UFix64(price + 10.0)).
			Test(otu.T).AssertSuccess()

		otu.tickClock(500.0)

		otu.O.TransactionFromFile("fulfillMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				UInt64(id)).
			Test(otu.T).AssertSuccess()

		otu.alterMarketOption("AuctionSoft", "enable").
			listNFTForSoftAuction("user2", id, price).
			auctionBidMarketSoft("user1", "user2", id, price+5.0)

		otu.alterMarketOption("AuctionSoft", "deprecate")
		otu.O.TransactionFromFile("cancelMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				UInt64(id)).
			Test(otu.T).AssertSuccess()

	})

	t.Run("Should no be able to list, bid, add bid , fulfill auction and delist after stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("AuctionSoft")

		otu.alterMarketOption("AuctionSoft", "stop")

		otu.O.TransactionFromFile("listNFTForAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(price + 5.0).
				UFix64(300.0).
				UFix64(60.0).
				UFix64(1.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("AuctionSoft", "enable").
			listNFTForSoftAuction("user1", id, price).
			alterMarketOption("AuctionSoft", "stop")

		otu.O.TransactionFromFile("bidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("AuctionSoft", "enable").
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			alterMarketOption("AuctionSoft", "stop")

		otu.O.TransactionFromFile("increaseBidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				UInt64(id).
				UFix64(price + 10.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("AuctionSoft", "stop")
		otu.O.TransactionFromFile("cancelMarketAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				UInt64(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.tickClock(500.0)

		otu.O.TransactionFromFile("fulfillMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				UInt64(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

	})

}

//TODO: add bid when there is a higher bid by another user
//TODO: add bid should return money from another user that has bid before
