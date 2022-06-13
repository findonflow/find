package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
)

func TestMarketAuctionEscrow(t *testing.T) {

	t.Run("Should not be able to list an item for auction twice, and will give error message.", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.TransactionFromFile("listNFTForAuctionEscrowed").
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
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+5.0).
			fulfillMarketAuctionEscrow("user1", id, "user2", price+5.0)
	})

	t.Run("Should be able to sell and buy at auction even the buyer is without the collection", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			destroyDandyCollection("user2").
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+5.0).
			fulfillMarketAuctionEscrow("user1", id, "user2", price+5.0)
	})

	t.Run("Should be able to sell at auction, buyer fulfill", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		otu.tickClock(400.0)

		otu.saleItemListed("user1", "finished_completed", price+5.0)
		otu.fulfillMarketAuctionEscrowFromBidder("user2", id, price+5.0)
	})

	t.Run("Should not be able to bid expired auction listing", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			tickClock(100.0)

		otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
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
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).AssertFailure("You cannot bid on your own resource")
	})

	t.Run("Should return funds if auction does not meet reserve price", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+1.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_failed", 11.0)

		buyer := "user2"
		name := "user1"
		otu.O.TransactionFromFile("fulfillMarketAuctionEscrowed").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				Account("account").
				String(name).
				UInt64(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
				"id":     fmt.Sprintf("%d", id),
				"seller": otu.accountAddress(name),
				"buyer":  otu.accountAddress(buyer),
				"amount": fmt.Sprintf("%.8f", 11.0),
				"status": "cancel_reserved_not_met",
			}))

	})

	t.Run("Should be able to cancel the auction", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		name := "user1"

		otu.O.TransactionFromFile("cancelMarketAuctionEscrowed").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
				"id":     fmt.Sprintf("%d", id),
				"seller": otu.accountAddress(name),
				"buyer":  "",
				"amount": fmt.Sprintf("%.8f", 10.0),
				"status": "cancel_listing",
			}))

	})

	t.Run("Should not be able to cancel the auction if it is ended", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			tickClock(400.0).
			saleItemListed("user1", "finished_completed", price+5.0)

		name := "user1"

		otu.O.TransactionFromFile("cancelMarketAuctionEscrowed").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).AssertFailure("Cannot cancel finished auction, fulfill it instead")

	})

	t.Run("Should not be able to fulfill a not yet live / ended auction", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.TransactionFromFile("fulfillMarketAuctionEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id)).
			Test(otu.T).AssertFailure("This auction is not live")

		otu.auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		otu.tickClock(100.0)

		otu.O.TransactionFromFile("fulfillMarketAuctionEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id)).
			Test(otu.T).AssertFailure("Auction has not ended yet")

	})

	t.Run("Should return funds if auction is cancelled", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+1.0).
			saleItemListed("user1", "active_ongoing", 11.0).
			tickClock(2.0)

		buyer := "user2"
		name := "user1"

		otu.O.TransactionFromFile("cancelMarketAuctionEscrowed").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
				"id":     fmt.Sprintf("%d", id),
				"seller": otu.accountAddress(name),
				"buyer":  otu.accountAddress(buyer),
				"amount": fmt.Sprintf("%.8f", 11.0),
				"status": "cancel_listing",
			}))

	})

	t.Run("Should be able to bid and increase bid by same user", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			saleItemListed("user1", "active_ongoing", 15.0).
			increaseAuctioBidMarketEscrow("user2", id, 5.0, 20.0).
			saleItemListed("user1", "active_ongoing", 20.0)

	})

	t.Run("Should not be able to add bid that is not above minimumBidIncrement", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		preIncrement := 5.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+preIncrement).
			saleItemListed("user1", "active_ongoing", price+preIncrement)

		otu.O.TransactionFromFile("increaseBidMarketAuctionEscrowed").
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
			setFlowDandyMarketOption("AuctionEscrow")

		otu.alterMarketOption("AuctionEscrow", "deprecate")

		otu.O.TransactionFromFile("listNFTForAuctionEscrowed").
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
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price)

		otu.alterMarketOption("AuctionEscrow", "deprecate")

		otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).AssertSuccess()

		otu.O.TransactionFromFile("increaseBidMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(price + 10.0)).
			Test(otu.T).AssertSuccess()

		otu.tickClock(500.0)

		otu.O.TransactionFromFile("fulfillMarketAuctionEscrowedFromBidder").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertSuccess()

		otu.alterMarketOption("AuctionEscrow", "enable")
		otu.O.TransactionFromFile("listNFTForAuctionEscrowed").
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
		otu.auctionBidMarketEscrow("user1", "user2", id, price+5.0)

		otu.alterMarketOption("AuctionEscrow", "deprecate")
		otu.O.TransactionFromFile("cancelMarketAuctionEscrowed").
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
			setFlowDandyMarketOption("AuctionEscrow")

		otu.alterMarketOption("AuctionEscrow", "stop")

		otu.O.TransactionFromFile("listNFTForAuctionEscrowed").
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

		otu.alterMarketOption("AuctionEscrow", "enable").
			listNFTForEscrowedAuction("user1", id, price).
			alterMarketOption("AuctionEscrow", "stop")

		otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("AuctionEscrow", "enable").
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			alterMarketOption("AuctionEscrow", "stop")

		otu.O.TransactionFromFile("increaseBidMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(price + 10.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("AuctionEscrow", "stop")
		otu.O.TransactionFromFile("cancelMarketAuctionEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.tickClock(500.0)

		otu.O.TransactionFromFile("fulfillMarketAuctionEscrowedFromBidder").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

	})

	t.Run("Should not be able to bid below listing price", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price)

		otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
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
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
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
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			setProfile("user1").
			setProfile("user2").
			auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		otu.tickClock(500.0)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		otu.AutoGold("status", status)

		res := otu.O.TransactionFromFile("fulfillMarketAuctionEscrowedFromBidder").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      "0.50000000",
				"findName":    "user1",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "minter",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "platform",
				"tenant":      "find",
			}))
		otu.AutoGold("events", res.Events)

	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 5.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			setProfile("user1").
			setProfile("user2").
			setFindCut(0.035)

		otu.tickClock(500.0)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		otu.AutoGold("status", status)

		res := otu.O.TransactionFromFile("fulfillMarketAuctionEscrowedFromBidder").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.35000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "find",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("user1"),
				"amount":      "0.50000000",
				"findName":    "user1",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "minter",
				"tenant":      "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      "0.25000000",
				"findName":    "",
				"id":          fmt.Sprintf("%d", id),
				"royaltyName": "platform",
				"tenant":      "find",
			}))

		otu.AutoGold("events", res.Events)

	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		otu.setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			createUser(100.0, "user3").
			registerUser("user2").
			registerUser("user3")

		ids := otu.mintThreeExampleDandies()

		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			auctionBidMarketEscrow("user2", "user1", ids[0], price+5.0).
			tickClock(400.0).
			profileBan("user1")

			// Should not be able to list
		otu.O.TransactionFromFile("listNFTForAuctionEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("Dandy").
				UInt64(ids[2]).
				String("Flow").
				UFix64(price).
				UFix64(price + 5.0).
				UFix64(300.0).
				UFix64(60.0).
				UFix64(1.0).
				UFix64(10.0)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		// Should not be able to bid
		otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(ids[1]).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		// Should not be able to fulfill
		otu.O.TransactionFromFile("fulfillMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(ids[0])).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		// Should be able to cancel
		otu.O.TransactionFromFile("cancelMarketAuctionEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64Array(ids[1])).
			Test(otu.T).AssertSuccess()

	})

	t.Run("Should be able to ban user, user cannot bid NFT.", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		otu.setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			createUser(100.0, "user3").
			registerUser("user2").
			registerUser("user3")

		ids := otu.mintThreeExampleDandies()

		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			auctionBidMarketEscrow("user2", "user1", ids[0], price+5.0).
			tickClock(400.0).
			profileBan("user2")

		// Should not be able to bid
		otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(ids[1]).
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

		// Should not be able to fulfill
		otu.O.TransactionFromFile("fulfillMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(ids[0])).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")
	})

	t.Run("Should emit previous bidder if outbid", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "active_listed", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0).
			saleItemListed("user1", "active_ongoing", 15.0)

		otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(20.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
				"amount":        fmt.Sprintf("%.8f", 20.0),
				"id":            fmt.Sprintf("%d", id),
				"buyer":         otu.accountAddress("user3"),
				"previousBuyer": otu.accountAddress("user2"),
				"status":        "active_ongoing",
			}))
	})

}
