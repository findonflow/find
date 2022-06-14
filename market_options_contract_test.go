package test_main

import (
	"testing"

	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestMarketOptionsContract(t *testing.T) {

	bidPrice := 15.00
	price := 10.00

	t.Run("Should be able to return ghost listings with script addressStatus and nameStatus", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			directOfferMarketSoft("user2", "user1", ids[0], price).
			acceptDirectOfferMarketSoft("user1", ids[0], "user2", price).
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", ids[1], price).
			setProfile("user1").
			setProfile("user2")

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 3, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", ids[0], "user2", price)

		result := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		result = otu.replaceID(result, ids)
		autogold.Equal(t, result)

	})

	t.Run("Should be able to return ghost bids with script addressStatus and nameStatus", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			directOfferMarketSoft("user2", "user1", ids[0], price).
			acceptDirectOfferMarketSoft("user1", ids[0], "user2", price).
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			auctionBidMarketEscrow("user2", "user1", ids[0], bidPrice).
			auctionBidMarketEscrow("user2", "user1", ids[1], bidPrice).
			setProfile("user1").
			setProfile("user2")

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 4, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", ids[0], "user2", price)

		result := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user2")).RunReturnsJsonString()
		result = otu.replaceID(result, ids)
		autogold.Equal(t, result)
	})

}
