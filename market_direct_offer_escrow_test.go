package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
)

func TestMarketDirectOfferEscrow(t *testing.T) {

	price := 10.0
	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		otu.saleItemListed("user1", "directoffer", price)
		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

	})

	t.Run("Should be able to increase offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.directOfferMarketEscrowed("user2", "user1", id, price)
		otu.saleItemListed("user1", "directoffer", price)
		otu.increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0)
		otu.saleItemListed("user1", "directoffer", 15.0)
		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)
	})

	t.Run("Should be able to reject offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.directOfferMarketEscrowed("user2", "user1", id, price)
		otu.saleItemListed("user1", "directoffer", price)
		otu.rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	//return money when outbid

	t.Run("Should return money when outbid", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.directOfferMarketEscrowed("user2", "user1", id, price)
		otu.saleItemListed("user1", "directoffer", price)

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
