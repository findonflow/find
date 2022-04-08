package test_main

import (
	"testing"
)

func TestMarketDirectOfferSoft(t *testing.T) {

	price := 10.0
	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.directOfferMarketSoft("user2", "user1", id, price)
		otu.saleItemListed("user1", "directoffer_soft", price)
		otu.acceptDirectOfferMarketSoft("user1", id, "user2", price)
		otu.saleItemListed("user1", "directoffer_soft_accepted", price)
		otu.fulfillMarketDirectOfferSoft("user2", id, price)
	})

	t.Run("Should be able to increase offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.directOfferMarketSoft("user2", "user1", id, price)
		otu.saleItemListed("user1", "directoffer_soft", price)
		otu.increaseDirectOfferMarketSoft("user2", id, 5.0, 15.0)
		otu.saleItemListed("user1", "directoffer_soft", 15.0)
	})

	t.Run("Should be able to reject offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.directOfferMarketSoft("user2", "user1", id, price)
		otu.saleItemListed("user1", "directoffer_soft", price)
		otu.rejectDirectOfferSoft("user1", id, 10.0)
	})

}
