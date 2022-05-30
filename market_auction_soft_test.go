package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
)

func TestMarketAuctionSoft(t *testing.T) {

	t.Run("Should not be able to list an item for auction twice, and will give error message.", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.TransactionFromFile("listNFTForAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(price + 5.0).
				UFix64(300.0).
				UFix64(60.0).
				UFix64(1.0).
				UFix64(10.0)).
			Test(otu.T).AssertFailure("Auction listing for this item is already created.")
	})

	t.Run("Should be able to sell at auction", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			tickClock(400.0).
			//TODO: Should status be something else while time has not run out? I think so
			saleItemListed("user1", "finished_completed", price+5.0).
			fulfillMarketAuctionSoft("user2", id, 15.0)
	})

	t.Run("Should be able to add bid at auction", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			increaseAuctionBidMarketSoft("user2", id, 5.0, price+10.0).
			tickClock(400.0).
			//TODO: Should status be something else while time has not run out? I think so
			saleItemListed("user1", "finished_completed", price+10.0).
			fulfillMarketAuctionSoft("user2", id, price+10.0)
	})

	t.Run("Should not be able to bid expired auction listing", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			tickClock(100.0)

		otu.O.TransactionFromFile("bidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).AssertFailure("This auction listing is already expired")
	})

	t.Run("Should not be able to bid your own listing", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.TransactionFromFile("bidMarketAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).AssertFailure("You cannot bid on your own resource")
	})

	t.Run("Should be able to cancel an auction", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		name := "user1"
		otu.O.TransactionFromFile("cancelMarketAuctionSoft").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"id":     fmt.Sprintf("%d", id),
				"seller": otu.accountAddress(name),
				"buyer":  "",
				"amount": fmt.Sprintf("%.8f", 10.0),
				"status": "cancel",
			}))
	})

	t.Run("Should not be able to cancel an ended auction", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			tickClock(4000.0).
			//TODO: Should status be something else while time has not run out? I think so
			saleItemListed("user1", "finished_completed", price+5.0)

		name := "user1"
		otu.O.TransactionFromFile("cancelMarketAuctionSoft").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).AssertFailure("Cannot cancel finished auction, fulfill it instead")
	})

	t.Run("Cannot fulfill a not yet ended auction", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.auctionBidMarketSoft("user2", "user1", id, price+5.0)

		otu.tickClock(100.0)

		otu.O.TransactionFromFile("fulfillMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(price + 5.0)).
			Test(otu.T).AssertFailure("Auction has not ended yet")
	})

	t.Run("Should allow seller to cancel auction if it failed to meet reserve price", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+1.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_failed", 11.0)

		buyer := "user2"
		name := "user1"
		otu.O.TransactionFromFile("cancelMarketAuctionSoft").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"id":     fmt.Sprintf("%d", id),
				"seller": otu.accountAddress(name),
				"buyer":  otu.accountAddress(buyer),
				"amount": fmt.Sprintf("%.8f", 11.0),
				"status": "cancel_reserved_not_met",
			}))
	})

	t.Run("Should be able to bid and increase bid by same user", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		preIncrement := 5.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+preIncrement).
			saleItemListed("user1", "active_ongoing", price+preIncrement)

		otu.O.TransactionFromFile("increaseBidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
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
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft")

		otu.alterMarketOption("AuctionSoft", "deprecate")

		otu.O.TransactionFromFile("listNFTForAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(price + preIncrement).
				UFix64(300.0).
				UFix64(60.0).
				UFix64(1.0).
				UFix64(10.0)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

	})

	t.Run("Should be able to bid, add bid , fulfill auction and delist after deprecated", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price)

		otu.alterMarketOption("AuctionSoft", "deprecate")

		otu.O.TransactionFromFile("bidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).AssertSuccess()

		otu.O.TransactionFromFile("increaseBidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(price + 10.0)).
			Test(otu.T).AssertSuccess()

		otu.tickClock(500.0)

		otu.O.TransactionFromFile("fulfillMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(30.0)).
			Test(otu.T).AssertSuccess()

		otu.alterMarketOption("AuctionSoft", "enable")
		otu.O.TransactionFromFile("listNFTForAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(price + 5.0).
				UFix64(300.0).
				UFix64(60.0).
				UFix64(1.0).
				UFix64(510.0)).
			Test(otu.T).AssertSuccess()
		otu.auctionBidMarketSoft("user1", "user2", id, price+5.0)

		otu.alterMarketOption("AuctionSoft", "deprecate")
		otu.O.TransactionFromFile("cancelMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).AssertSuccess()

	})

	t.Run("Should no be able to list, bid, add bid , fulfill auction and delist after stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft")

		otu.alterMarketOption("AuctionSoft", "stop")

		otu.O.TransactionFromFile("listNFTForAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(price + 5.0).
				UFix64(300.0).
				UFix64(60.0).
				UFix64(1.0).
				UFix64(10.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("AuctionSoft", "enable").
			listNFTForSoftAuction("user1", id, price).
			alterMarketOption("AuctionSoft", "stop")

		otu.O.TransactionFromFile("bidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
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
				Account("account").
				UInt64(id).
				UFix64(price + 10.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("AuctionSoft", "stop")
		otu.O.TransactionFromFile("cancelMarketAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.tickClock(500.0)

		otu.O.TransactionFromFile("fulfillMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(price + 5.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

	})

	t.Run("Should not be able to bid below listing price", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.TransactionFromFile("bidMarketAuctionSoft").SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(1.0)).
			Test(otu.T).AssertFailure("You need to bid more then the starting price of 10.00000000")

	})

	t.Run("Should not be able to bid less the previous bidder", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0)

		otu.O.TransactionFromFile("bidMarketAuctionSoft").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(5.0)).
			Test(otu.T).AssertFailure("bid 5.00000000 must be larger then previous bid+bidIncrement 16.00000000")

	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon fulfill action", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 5.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			setProfile("user1")

		otu.tickClock(500.0)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		otu.AutoGold("status", status)

		res := otu.O.TransactionFromFile("fulfillMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(10.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"royaltyName": "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      "0.50000000",
				"royaltyName": "artist",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"royaltyName": "platform",
			}))

		otu.AutoGold("events", res.Events)
	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 5.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketSoft("user2", "user1", id, price+5.0).
			setProfile("user1"). 
			setFindCut(0.035)

		otu.tickClock(500.0)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		otu.AutoGold("status", status)

		res := otu.O.TransactionFromFile("fulfillMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(10.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.35000000",
				"royaltyName": "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      "0.50000000",
				"royaltyName": "artist",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"royaltyName": "platform",
			}))

		otu.AutoGold("events", res.Events)
	})
}

//TODO: add bid should return money from another user that has bid before
