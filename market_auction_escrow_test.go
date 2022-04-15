package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
)

func TestMarketAuctionEscrow(t *testing.T) {

	t.Run("Should be able to sell at auction", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "ondemand_auction", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			tickClock(400.0).
			// //TODO: Should status be something else while time has not run out? I think so
			saleItemListed("user1", "ongoing_auction", price+5.0).
			fulfillMarketAuctionEscrow("user1", id, "user2", price+5.0)
	})

	t.Run("Should be able to sell at auction, buyer fulfill", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "ondemand_auction", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		otu.tickClock(400.0)

		otu.saleItemListed("user1", "ongoing_auction", price+5.0)
		otu.fulfillMarketAuctionEscrowFromBidder("user2", id, price+5.0)
	})

	t.Run("Should return funds if auction does not meet reserve price", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "ondemand_auction", price).
			auctionBidMarketEscrow("user2", "user1", id, price+1.0).
			tickClock(400.0).
			saleItemListed("user1", "ongoing_auction", 11.0)

		buyer := "user2"
		name := "user1"
		otu.O.TransactionFromFile("fulfillMarketAuctionEscrowed").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				Account(name).
				UInt64(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.ForAuction", map[string]interface{}{
				"id":     fmt.Sprintf("%d", id),
				"seller": otu.accountAddress(name),
				"buyer":  otu.accountAddress(buyer),
				"amount": fmt.Sprintf("%.8f", 11.0),
				"status": "cancelled",
			}))
		//TODO: should this be cancelled or should it be something else?

	})

	t.Run("Should return funds if auction is cancelled", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "ondemand_auction", price).
			auctionBidMarketEscrow("user2", "user1", id, price+1.0).
			saleItemListed("user1", "ongoing_auction", 11.0).
			tickClock(2.0)

		buyer := "user2"
		name := "user1"

		otu.O.TransactionFromFile("cancelMarketAuctionEscrowed").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				UInt64(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.ForAuction", map[string]interface{}{
				"id":     fmt.Sprintf("%d", id),
				"seller": otu.accountAddress(name),
				"buyer":  otu.accountAddress(buyer),
				"amount": fmt.Sprintf("%.8f", 11.0),
				"status": "cancelled",
			}))

	})

	t.Run("Should be able to bid and increase bid by same user", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "ondemand_auction", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			saleItemListed("user1", "ongoing_auction", 15.0).
			increaseAuctioBidMarketEscrow("user2", id, 5.0, 20.0).
			saleItemListed("user1", "ongoing_auction", 20.0)

	})

	/*
		//TODO: does not work
		t.Run("Relist", func(t *testing.T) {
			otu := NewOverflowTest(t)

			price := 10.0
			id := otu.setupMarketAndDandy()
			otu.listNFTForEscrowedAuction("user1", id, price)
			otu.saleItemListed("user1", "ondemand_auction", price)
			otu.listNFTForEscrowedAuction("user1", id, 20.0)
		})
	*/

	// Ben note : If the same buyer increase the bid, even under min bid increment, will still go thru
	t.Run("Add bid that is not above minimumBidIncrement", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		preIncrement := 5.0
		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "ondemand_auction", price).
			auctionBidMarketEscrow("user2", "user1", id, price+preIncrement).
			saleItemListed("user1", "ongoing_auction", price+preIncrement)

		name := "user2"
		postIncrement := 0.1
		totalPrice := price + preIncrement + postIncrement

		otu.O.TransactionFromFile("increaseBidMarketAuctionEscrowed").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				UInt64(id).
				UFix64(postIncrement)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.ForAuction", map[string]interface{}{
				"amount": fmt.Sprintf("%.8f", totalPrice),
				"id":     fmt.Sprintf("%d", id),
				"buyer":  otu.accountAddress(name),
				"status": "active",
			}))
	})

}

//TODO: list item twice for auction
//TODO: add bid when there is a higher bid by another user
//TODO: add bid should return money from another user that has bid before
