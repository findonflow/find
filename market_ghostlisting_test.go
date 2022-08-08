package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestMarketGhostlistingTest(t *testing.T) {

	price := 10.0
	bidPrice := 15.0

	otu := NewOverflowTest(t)

	id := otu.setupMarketAndDandy()
	otu.registerFtInRegistry().
		setFlowDandyMarketOption("DirectOfferSoft").
		setFlowDandyMarketOption("DirectOfferEscrow").
		setFlowDandyMarketOption("Sale").
		setFlowDandyMarketOption("AuctionEscrow").
		setFlowDandyMarketOption("AuctionSoft").
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

	otu.setUUID(350)

	/* MarketSale */
	t.Run("Should not be able to fullfill sale if item was already sold on direct offer", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)

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

		/* Reset */
		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	/* MarketAuction Escrowed */
	t.Run("Should not be able to bid Auction if item was already sold on direct offer", func(t *testing.T) {

		otu.listNFTForEscrowedAuction("user1", id, price)

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

		/* Reset */
		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")
	})

	t.Run("Should not be able to increase bid in Auction if item was already sold on direct offer", func(t *testing.T) {

		otu.listNFTForEscrowedAuction("user1", id, price).
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

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to fulfill bid in Auction if item was already sold on direct offer", func(t *testing.T) {

		otu.listNFTForEscrowedAuction("user1", id, price).
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
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
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

		/* Reset */
		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	/* MarketAuction Soft */
	t.Run("Should not be able to bid Auction soft if item was already sold on direct offer", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price)

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

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to increase bid in Auction Soft if item was already sold on direct offer", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
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

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to fulfill bid in Auction if item was already sold on direct offer", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
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
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(id).
				String("Flow").
				UFix64(15.0).
				UFix64(otu.currentTime() + 800.0)).
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

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")
	})

	/* Direct Offer Escrowed */ // This is not likely to happen
	t.Run("Should not be able to make Direct Offer if item was already sold on direct offer", func(t *testing.T) {

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
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).AssertFailure("NFT does not exist")

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to fulfill Direct Offer if item was already sold in other form", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			directOfferMarketEscrowed("user2", "user1", id, price)

		otu.setUUID(300)

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

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to make Direct Offer Soft if item was already sold in other form", func(t *testing.T) {

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
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(id).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).AssertFailure("NFT does not exist")

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to accept Direct Offer Soft if item was already sold in other form", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price).
			directOfferMarketSoft("user2", "user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)
		otu.O.TransactionFromFile("acceptDirectOfferSoft").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertFailure("this is a ghost listing")

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to fulfill Direct Offer Soft if item was already sold in other form", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
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

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")
	})

	t.Run("Should be able to return ghost listings with script getStatus", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.directOfferMarketSoft("user2", "user1", ids[0], price).
			acceptDirectOfferMarketSoft("user1", ids[0], "user2", price).
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", ids[1], price)

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 3, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", ids[0], "user2", price)

		result := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()

		result = otu.replaceID(result, ids)

		otu.AutoGoldRename("Should be able to return ghost listings with script getStatus", result)

		otu.sendDandy("user1", "user2", ids[0]).
			delistAllNFT("user1")

	})

	t.Run("Should be able to return ghost bids with script getStatus", func(t *testing.T) {
		ids := otu.mintThreeExampleDandies()
		otu.directOfferMarketSoft("user2", "user1", ids[0], price).
			acceptDirectOfferMarketSoft("user1", ids[0], "user2", price).
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			auctionBidMarketEscrow("user2", "user1", ids[0], bidPrice).
			auctionBidMarketEscrow("user2", "user1", ids[1], bidPrice)

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 4, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", ids[0], "user2", price)

		result := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user2")).RunReturnsJsonString()
		result = otu.replaceID(result, ids)
		otu.AutoGoldRename("Should be able to return ghost bids with script getStatus", result)

		otu.sendDandy("user1", "user2", ids[0]).
			delistAllNFT("user1")
	})

	t.Run("SoulBound items should be ghostListings", func(t *testing.T) {
		otu.sendSoulBoundNFT("user1", "account").
			registerExampleNFTInNFTRegistry()
		// set market rules
		otu.O.Tx("adminSetSellExampleNFTForFlow",
			overflow.WithSigner("find"),
			overflow.WithArg("tenant", "account"),
		).AssertSuccess(t)

		// make it non-soulBound before listing
		otu.O.Tx("testtoggleSoulBoundExampleNFT",
			overflow.WithSigner("user1"),
			overflow.WithArg("id", 1),
			overflow.WithArg("soulBound", false),
		).AssertSuccess(t)

		saleId, err := otu.O.Tx("listNFTForAuctionEscrowed",
			overflow.WithSigner("user1"),
			overflow.WithArg("marketplace", "account"),
			overflow.WithArg("nftAliasOrIdentifier", "A.f8d6e0586b0a20c7.ExampleNFT.NFT"),
			overflow.WithArg("id", 1),
			overflow.WithArg("ftAliasOrIdentifier", "Flow"),
			overflow.WithArg("price", price),
			overflow.WithArg("auctionReservePrice", price+5.0),
			overflow.WithArg("auctionDuration", 300.0),
			overflow.WithArg("auctionExtensionOnLateBid", 60.0),
			overflow.WithArg("minimumBidIncrement", 1.0),
			overflow.WithArg("auctionValidUntil", otu.currentTime()+100.0),
		).AssertSuccess(t).GetIdFromEvent("EnglishAuction", "id")

		if err != nil {
			panic(err)
		}

		// make it soulBound before listing
		otu.O.Tx("testtoggleSoulBoundExampleNFT",
			overflow.WithSigner("user1"),
			overflow.WithArg("id", 1),
			overflow.WithArg("soulBound", true),
		).AssertSuccess(t)

		otu.O.Script("getStatus",
			overflow.WithArg("user", "user1"),
		).
			AssertWithPointerWant(t, "/FINDReport/itemsForSale/FindMarketAuctionEscrow/ghosts",
				autogold.Want("soulBoundGhost", `[]interface {}{
  map[string]interface {}{
    "id": 101,
    "listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem",
  },
}`),
			)

		// Bids will also show as ghost
		otu.O.Tx("bidMarketAuctionEscrowed",
			overflow.WithSigner("user2"),
			overflow.WithArg("marketplace", "account"),
			overflow.WithArg("user", "user1"),
			overflow.WithArg("id", saleId),
			overflow.WithArg("amount", price+5.0),
		).AssertSuccess(t)

		otu.O.Script("getStatus",
			overflow.WithArg("user", "user2"),
		).Print().
			AssertWithPointerWant(t, "/FINDReport/marketBids/FindMarketAuctionEscrow/ghosts",
				autogold.Want("soulBoundGhostBid", `[]interface {}{
  map[string]interface {}{
    "id": 101,
    "listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid",
  },
}`),
			)
	})

}
