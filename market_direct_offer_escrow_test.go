package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
	"github.com/stretchr/testify/assert"
)

func TestMarketDirectOfferEscrow(t *testing.T) {

	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()

		price := 10.0
		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

	})

	t.Run("Should be able to increase offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.directOfferMarketEscrowed("user2", "user1", id, 10.0)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", 10.0), itemsForSale[0].Amount)

		otu.increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", 15.0), itemsForSale[0].Amount)

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

	})

	t.Run("Should be able to reject offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.directOfferMarketEscrowed("user2", "user1", id, 10.0)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", 10.0), itemsForSale[0].Amount)

		otu.rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	//return money when outbid

	t.Run("Should return money when outbid", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()

		price := 10.0
		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
		assert.Equal(t, fmt.Sprintf("%.8f", price), itemsForSale[0].Amount)

		otu.createUser(100.0, "user3").registerUser("user3")

		newPrice := 11.0
		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("user1").
				UInt64(id).
				UFix64(newPrice)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
				"amount": fmt.Sprintf("%.8f", newPrice),
				"id":     fmt.Sprintf("%d", id),
				"buyer":  otu.accountAddress("user3"),
				"status": "offered",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": fmt.Sprintf("%.8f", price),
				"to":     otu.accountAddress("user2"),
			}))
		//TODO: should there be an event emitted that you get your money back?

	})

}
