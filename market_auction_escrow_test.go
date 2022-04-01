package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
	"github.com/stretchr/testify/assert"
)

func TestMarketAuctionEscrow(t *testing.T) {

	t.Run("Should be able to sell at auction", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.listDandyForEscrowedAuction("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "ondemand_auction", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		otu.tickClock(400.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "ongoing_auction", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price+5.0), itemsForSale[0].Amount)

		otu.fulfillMarketAuctionEscrow("user1", id, "user2", price+5.0)
	})

	t.Run("Should return funds if auction does not meet reserve price", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.listDandyForEscrowedAuction("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "ondemand_auction", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.auctionBidMarketEscrow("user2", "user1", id, price+1.0)

		otu.tickClock(400.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "ongoing_auction", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price+1.0), itemsForSale[0].Amount)

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

	})

	t.Run("Should return funds if auction is cancelled", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()
		otu.listDandyForEscrowedAuction("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "ondemand_auction", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.auctionBidMarketEscrow("user2", "user1", id, price+1.0)

		otu.tickClock(2.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "ongoing_auction", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price+1.0), itemsForSale[0].Amount)

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
}

//TODO: fulfill when auction did not meet reserve price
