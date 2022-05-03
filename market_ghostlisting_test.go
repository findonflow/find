package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestMarketGhostlistingTest(t *testing.T) {

	price := 10.0

	t.Run("Should not be able to fullfill sale if item was already sold on direct offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("Sale").
			listNFTForSale("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "directSale", itemsForSale[0].SaleType)

		otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))
		assert.Equal(t, "directSale", itemsForSale[0].SaleType)
		assert.Equal(t, "directoffer", itemsForSale[1].SaleType)

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.O.TransactionFromFile("buyItemForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).AssertFailure("This listing is a ghost listing")

	})

}
