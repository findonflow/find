package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestMarketGhostlistingTest(t *testing.T) {

	price := 10.0
	bidPrice := 15.0

	/* MarketSale */
	t.Run("Should not be able to fullfill sale if item was already sold on direct offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("Sale").
			listNFTForSale("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.O.TransactionFromFile("buyNFTForSale").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).AssertFailure("this is a ghost listing")

	})

	/* MarketAuction Escrowed */
	t.Run("Should not be able to bid Auction if item was already sold on direct offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(bidPrice)).
			Test(otu.T).AssertFailure("this is a ghost listing")

	})

	t.Run("Should not be able to increase bid in Auction if item was already sold on direct offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			auctionBidMarketEscrow("user2", "user1", id, bidPrice)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_ongoing", itemsForSale[0].SaleType)

		otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.O.TransactionFromFile("increaseBidMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(bidPrice + 1.0)).
			Test(otu.T).AssertFailure("this is a ghost listing")

	})

	t.Run("Should not be able to fulfill bid in Auction if item was already sold on direct offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			auctionBidMarketEscrow("user2", "user1", id, bidPrice).
			tickClock(700)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "finished_completed", itemsForSale[0].SaleType)

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(15.0).
				UFix64(800.0)).
			Test(otu.T).AssertSuccess()

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.O.TransactionFromFile("fulfillMarketAuctionEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id)).
			Test(otu.T).AssertFailure("NFT does not exist")

	})

	/* MarketAuction Soft */
	t.Run("Should not be able to bid Auction soft if item was already sold on direct offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.O.TransactionFromFile("bidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				UInt64(id).
				UFix64(bidPrice)).
			Test(otu.T).AssertFailure("this is a ghost listing")

	})

	t.Run("Should not be able to increase bid in Auction Soft if item was already sold on direct offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			auctionBidMarketSoft("user2", "user1", id, bidPrice)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_ongoing", itemsForSale[0].SaleType)

		otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.O.TransactionFromFile("increaseBidMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(bidPrice + 1.0)).
			Test(otu.T).AssertFailure("this is a ghost listing")

	})

	t.Run("Should not be able to fulfill bid in Auction if item was already sold on direct offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSoftAuction("user1", id, price).
			auctionBidMarketSoft("user2", "user1", id, bidPrice).
			tickClock(700)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "finished_completed", itemsForSale[0].SaleType)

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(15.0).
				UFix64(800.0)).
			Test(otu.T).AssertSuccess()

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.O.TransactionFromFile("fulfillMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(15.0)).
			Test(otu.T).AssertFailure("this is a ghost listing")

	})

	/* Direct Offer Escrowed */ // This is not likely to happen
	t.Run("Should not be able to make Direct Offer if item was already sold on direct offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("AuctionSoft")

		otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_ongoing", itemsForSale[0].SaleType)

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).AssertFailure("NFT does not exist")

	})

	t.Run("Should not be able to fulfill Direct Offer if item was already sold in other form", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			directOfferMarketEscrowed("user2", "user1", id, price)

		otu.directOfferMarketSoft("user2", "user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketSoft("user1", id, "user2", price).
			fulfillMarketDirectOfferSoft("user2", id, price)

		otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertFailure("this is a ghost listing")

	})

	t.Run("Should not be able to make Direct Offer Soft if item was already sold in other form", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft")

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_ongoing", itemsForSale[0].SaleType)

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				String("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).AssertFailure("NFT does not exist")

	})

	t.Run("Should not be able to accept Direct Offer Soft if item was already sold in other form", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			directOfferMarketSoft("user2", "user1", id, price)

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

		otu.O.TransactionFromFile("acceptDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertFailure("this is a ghost listing")

	})

	t.Run("Should not be able to fulfill Direct Offer Soft if item was already sold in other form", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			directOfferMarketSoft("user2", "user1", id, price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price)

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

		otu.O.TransactionFromFile("fulfillMarketDirectOfferSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id).
				UFix64(price)).
			Test(otu.T).AssertFailure("this is a ghost listing")

	})

	/*
		t.Run("Should be able to return ghost listings with script getStatus", func(t *testing.T) {
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
			autogold.Equal(t, result)
		})

			t.Run("Should be able to return ghost bids with script getStatus", func(t *testing.T) {
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
				autogold.Equal(t, result)
			})
	*/
}
