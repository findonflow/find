package test_main

import (
	"testing"
)

func TestMarketDirectOfferSoft(t *testing.T) {

	price := 10.0
	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "directoffer_soft", price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price).
			saleItemListed("user1", "directoffer_soft_accepted", price).
			fulfillMarketDirectOfferSoft("user2", id, price)
	})

	t.Run("Should be able to increase offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "directoffer_soft", price).
			increaseDirectOfferMarketSoft("user2", id, 5.0, 15.0).
			saleItemListed("user1", "directoffer_soft", 15.0)
	})

	t.Run("Should be able to reject offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			directOfferMarketSoft("user2", "user1", id, price).
			saleItemListed("user1", "directoffer_soft", price).
			rejectDirectOfferSoft("user1", id, 10.0)
	})

}
