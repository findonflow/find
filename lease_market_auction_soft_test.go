package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
)

func TestLeaseMarketAuctionSoft(t *testing.T) {

	otu := NewOverflowTest(t)

	price := 10.0
	preIncrement := 5.0
	otu.setupMarketAndDandy()
	otu.registerFtInRegistry().
		setFlowLeaseMarketOption("AuctionSoft").
		setProfile("user1").
		setProfile("user2")

	otu.O.TransactionFromFile("testMintFusd").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			Account("user2").
			UFix64(1000.0)).
		Test(otu.T).
		AssertSuccess()

	otu.O.TransactionFromFile("testMintFlow").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			Account("user2").
			UFix64(1000.0)).
		Test(otu.T).
		AssertSuccess()

	otu.O.TransactionFromFile("testMintUsdc").
		SignProposeAndPayAsService().
		Args(otu.O.Arguments().
			Account("user2").
			UFix64(1000.0)).
		Test(otu.T).
		AssertSuccess()

	otu.registerUserWithName("user1", "name1").
		registerUserWithName("user1", "name2").
		registerUserWithName("user1", "name3")

	t.Run("Should not be able to list an item for auction twice, and will give error message.", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price)

		otu.O.TransactionFromFile("listLeaseForAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name1").
				String("Flow").
				UFix64(price).
				UFix64(price + 5.0).
				UFix64(300.0).
				UFix64(60.0).
				UFix64(1.0).
				UFix64(otu.currentTime() + 10.0)).
			Test(otu.T).AssertFailure("Auction listing for this item is already created.")

		otu.delistAllLeaseForSoftAuction("user1")
	})

	t.Run("Should be able to sell at auction", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+5.0).
			fulfillLeaseMarketAuctionSoft("user2", "name1", 15.0)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to sell and buy at auction even buyer is without the collection.", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			destroyLeaseCollection("user2").
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+5.0).
			fulfillLeaseMarketAuctionSoft("user2", "name1", 15.0)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to cancel listing if the pointer is no longer valid", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+5.0).
			moveNameTo("user1", "user2", "name1")

		otu.O.TransactionFromFile("cancelLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				StringArray("name1")).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"leaseName": "name1",
				"seller":    otu.accountAddress("user1"),
				"buyer":     otu.accountAddress("user2"),
				"amount":    15.0,
				"status":    "cancel_ghostlisting",
			}))

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to add bid at auction", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			increaseAuctionBidLeaseMarketSoft("user2", "name1", 5.0, price+10.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+10.0).
			fulfillLeaseMarketAuctionSoft("user2", "name1", price+10.0)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should not be able to bid expired auction listing", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			tickClock(100.0)

		otu.O.TransactionFromFile("bidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).AssertFailure("This auction listing is already expired")

		otu.delistAllLeaseForSoftAuction("user1")
	})

	t.Run("Should not be able to bid your own listing", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price)

		otu.O.TransactionFromFile("bidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).AssertFailure("You cannot bid on your own resource")

		otu.delistAllLeaseForSoftAuction("user1")
	})

	t.Run("Should be able to cancel an auction", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price)

		name := "user1"
		otu.O.TransactionFromFile("cancelLeaseMarketAuctionSoft").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				StringArray("name1")).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"leaseName": "name1",
				"seller":    otu.accountAddress(name),
				"amount":    10.0,
				"status":    "cancel",
			}))
	})

	t.Run("Should not be able to cancel an ended auction", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			tickClock(4000.0).
			saleLeaseListed("user1", "finished_completed", price+5.0)

		name := "user1"
		otu.O.TransactionFromFile("cancelLeaseMarketAuctionSoft").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				StringArray("name1")).
			Test(otu.T).AssertFailure("Cannot cancel finished auction, fulfill it instead")

		otu.fulfillLeaseMarketAuctionSoft("user2", "name1", price+5.0).
			moveNameTo("user2", "user1", "name1")

	})

	t.Run("Cannot fulfill a not yet ended auction", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price)

		otu.auctionBidLeaseMarketSoft("user2", "name1", price+5.0)

		otu.tickClock(100.0)

		otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price + 5.0)).
			Test(otu.T).AssertFailure("Auction has not ended yet")

		otu.delistAllLeaseForSoftAuction("user1")
	})

	t.Run("Should allow seller to cancel auction if it failed to meet reserve price", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+1.0).
			tickClock(400.0).
			saleLeaseListed("user1", "finished_failed", 11.0)

		buyer := "user2"
		name := "user1"
		otu.O.TransactionFromFile("cancelLeaseMarketAuctionSoft").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				StringArray("name1")).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"leaseName": "name1",
				"seller":    otu.accountAddress(name),
				"buyer":     otu.accountAddress(buyer),
				"amount":    11.0,
				"status":    "cancel_reserved_not_met",
			}))
	})

	t.Run("Should be able to bid and increase bid by same user", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+preIncrement).
			saleLeaseListed("user1", "active_ongoing", price+preIncrement)

		otu.O.TransactionFromFile("increaseBidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(0.1)).
			Test(otu.T).
			AssertFailure("must be larger then previous bid+bidIncrement")

		otu.delistAllLeaseForSoftAuction("user1")
	})

	/* Tests on Rules */
	t.Run("Should not be able to list after deprecated", func(t *testing.T) {

		otu.alterLeaseMarketOption("AuctionSoft", "deprecate")

		otu.O.TransactionFromFile("listLeaseForAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name1").
				String("Flow").
				UFix64(price).
				UFix64(price + preIncrement).
				UFix64(300.0).
				UFix64(60.0).
				UFix64(1.0).
				UFix64(10.0)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.alterLeaseMarketOption("AuctionSoft", "enable")
	})

	t.Run("Should be able to bid, add bid , fulfill auction and delist after deprecated", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user1", "name1", price)

		otu.alterLeaseMarketOption("AuctionSoft", "deprecate")

		otu.O.TransactionFromFile("bidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).AssertSuccess()

		otu.O.TransactionFromFile("increaseBidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price + 10.0)).
			Test(otu.T).AssertSuccess()

		otu.tickClock(500.0)

		otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(30.0)).
			Test(otu.T).AssertSuccess()

		otu.alterLeaseMarketOption("AuctionSoft", "enable")
		otu.O.TransactionFromFile("listLeaseForAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				String("Flow").
				UFix64(price).
				UFix64(price + 5.0).
				UFix64(300.0).
				UFix64(60.0).
				UFix64(1.0).
				UFix64(otu.currentTime() + 10.0)).
			Test(otu.T).AssertSuccess()
		otu.auctionBidLeaseMarketSoft("user1", "name1", price+5.0)

		otu.alterLeaseMarketOption("AuctionSoft", "deprecate")
		otu.O.TransactionFromFile("cancelLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				StringArray("name1")).
			Test(otu.T).AssertSuccess()

		otu.alterLeaseMarketOption("AuctionSoft", "enable").
			moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should no be able to list, bid, add bid , fulfill auction and delist after stopped", func(t *testing.T) {

		otu.alterLeaseMarketOption("AuctionSoft", "stop")

		otu.O.TransactionFromFile("listLeaseForAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name1").
				String("Flow").
				UFix64(price).
				UFix64(price + 5.0).
				UFix64(300.0).
				UFix64(60.0).
				UFix64(1.0).
				UFix64(10.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterLeaseMarketOption("AuctionSoft", "enable").
			listLeaseForSoftAuction("user1", "name1", price).
			alterLeaseMarketOption("AuctionSoft", "stop")

		otu.O.TransactionFromFile("bidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterLeaseMarketOption("AuctionSoft", "enable").
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			alterLeaseMarketOption("AuctionSoft", "stop")

		otu.O.TransactionFromFile("increaseBidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price + 10.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterLeaseMarketOption("AuctionSoft", "stop")
		otu.O.TransactionFromFile("cancelLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				StringArray("name1")).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.tickClock(500.0)

		otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price + 5.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		/* Reset */
		otu.alterLeaseMarketOption("AuctionSoft", "enable")

		otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price + 5.0)).
			Test(otu.T).
			AssertSuccess()
		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should not be able to bid below listing price", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price)

		otu.O.TransactionFromFile("bidLeaseMarketAuctionSoft").SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(1.0)).
			Test(otu.T).AssertFailure("You need to bid more then the starting price of 10.00000000")

		otu.delistAllLeaseForSoftAuction("user1")

	})

	t.Run("Should not be able to bid less the previous bidder", func(t *testing.T) {
		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0)

		otu.O.TransactionFromFile("bidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(5.0)).
			Test(otu.T).AssertFailure("bid 5.00000000 must be larger then previous bid+bidIncrement 16.00000000")
		otu.delistAllLeaseForSoftAuction("user1")
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon fulfill action", func(t *testing.T) {

		price = 5.0

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0)

		otu.tickClock(500.0)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		otu.AutoGoldRename("Royalties should be sent to correspondence upon fulfill action status", status)

		res := otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(10.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      0.25,
				"royaltyName": "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("find"),
				"amount":      0.5,
				"royaltyName": "network",
			}))

		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction"})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties should be sent to correspondence upon fulfill action events", result)
		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		price = 5.0

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			setFindLeaseCut(0.035)

		otu.tickClock(500.0)

		status := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		otu.AutoGoldRename("Royalties of find platform should be able to change status", status)

		res := otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(10.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("account"),
				"amount":      0.35,
				"royaltyName": "find",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", map[string]interface{}{
				"address":     otu.accountAddress("find"),
				"amount":      0.5,
				"royaltyName": "network",
			}))

		saleIDs := otu.getIDFromEvent(res.Events, "A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", "saleID")

		result := otu.retrieveEvent(res.Events, []string{"A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyPaid", "A.f8d6e0586b0a20c7.FindLeaseMarket.RoyaltyCouldNotBePaid", "A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction"})
		result = otu.replaceID(result, saleIDs)
		otu.AutoGoldRename("Royalties of find platform should be able to change events", result)
		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			listLeaseForSoftAuction("user1", "name2", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			tickClock(400.0).
			leaseProfileBan("user1")

			// Should not be able to list
		otu.O.TransactionFromFile("listLeaseForAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("name3").
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
		otu.O.TransactionFromFile("bidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name2").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		// Should not be able to fufil
		otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price + 5.0)).
			Test(otu.T).
			AssertFailure("Seller banned by Tenant")

		// Should be able to cancel
		otu.O.TransactionFromFile("cancelLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				StringArray("name2")).
			Test(otu.T).AssertSuccess()

		otu.removeLeaseProfileBan("user1")
		otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price + 5.0)).
			Test(otu.T).
			AssertSuccess()

		otu.delistAllLeaseForSoftAuction("user1").
			moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should be able to ban user, user cannot bid NFT.", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			listLeaseForSoftAuction("user1", "name2", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			tickClock(400.0).
			leaseProfileBan("user2")

		// Should not be able to bid
		otu.O.TransactionFromFile("bidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name2").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

		// Should not be able to fufil
		otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price + 5.0)).
			Test(otu.T).
			AssertFailure("Buyer banned by Tenant")

		/* Reset */
		otu.removeLeaseProfileBan("user2")
		otu.O.TransactionFromFile("fulfillLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(price + 5.0)).
			Test(otu.T).
			AssertSuccess()

		otu.delistAllLeaseForSoftAuction("user1").
			moveNameTo("user2", "user1", "name1")

	})

	t.Run("Should emit previous bidder if outbid", func(t *testing.T) {

		otu.listLeaseForSoftAuction("user1", "name1", price).
			saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoft("user2", "name1", price+5.0).
			saleLeaseListed("user1", "active_ongoing", price+5.0)

		otu.O.TransactionFromFile("bidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(20.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
				"amount":        20.0,
				"leaseName":     "name1",
				"buyer":         otu.accountAddress("user3"),
				"previousBuyer": otu.accountAddress("user2"),
				"status":        "active_ongoing",
			}))

		otu.delistAllLeaseForSoftAuction("user1")
	})

	t.Run("Should be able to list an NFT for auction and bid it with DUC", func(t *testing.T) {

		otu.registerDUCInRegistry().
			setDUCLease()

		otu.listLeaseForSoftAuctionDUC("user1", "name1", price)

		otu.saleLeaseListed("user1", "active_listed", price).
			auctionBidLeaseMarketSoftDUC("user2", "name1", price+5.0)

		otu.O.TransactionFromFile("increaseBidLeaseMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("name1").
				UFix64(5.0)).
			Test(otu.T).
			AssertSuccess()

		otu.tickClock(400.0).
			saleLeaseListed("user1", "finished_completed", price+10.0).
			fulfillLeaseMarketAuctionSoftDUC("user2", "name1", price+10.0)

		otu.moveNameTo("user2", "user1", "name1")
	})

}
