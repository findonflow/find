package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestMarketGhostlistingTest(t *testing.T) {

	price := 10.0
	bidPrice := 15.0

	otu := NewOverflowTest(t)

	mintFund := otu.O.TxFN(
		WithSigner("account"),
		WithArg("amount", 10000.0),
		WithArg("recipient", "user2"),
	)

	id := otu.setupMarketAndDandy()
	otu.registerFtInRegistry().
		setFlowDandyMarketOption("find").
		setProfile("user1").
		setProfile("user2")

	mintFund("devMintFusd").AssertSuccess(t)

	mintFund("devMintFlow").AssertSuccess(t)

	mintFund("devMintUsdc").AssertSuccess(t)

	otu.setUUID(600)

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

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "this is a ghost listing")

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

		otu.O.Tx("bidMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "this is a ghost listing")

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

		otu.O.Tx("increaseBidMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("id", id),
			WithArg("amount", bidPrice+1.0),
		).
			AssertFailure(t, "this is a ghost listing")

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

		otu.O.Tx("bidMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", 15.0),
			WithArg("validUntil", 800.0),
		).
			AssertSuccess(t)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.O.Tx("fulfillMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("owner", "user1"),
			WithArg("id", id),
		).
			AssertFailure(t, "NFT does not exist")

		/* Reset */
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

		otu.O.Tx("bidMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", 100.0),
		).
			AssertFailure(t, "NFT does not exist")

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to fulfill Direct Offer if item was already sold in other form", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		otu.setUUID(1000)

		otu.listNFTForSale("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.buyNFTForMarketSale("user2", "user1", id, price)

		otu.O.Tx("fulfillMarketDirectOfferEscrowed",
			WithSigner("user1"),
			WithArg("id", id),
		).
			AssertFailure(t, "this is a ghost listing")

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to make Direct Offer Escrowed if item was already sold in other form", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_ongoing", itemsForSale[0].SaleType)

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

		otu.O.Tx("bidMarketDirectOfferEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("amount", price),
			WithArg("validUntil", 100.0),
		).
			AssertFailure(t, "NFT does not exist")

		otu.sendDandy("user1", "user2", id).
			sendFT("user1", "user2", "Flow", 15.0).
			delistAllNFT("user1")

	})

	t.Run("Should be able to return ghost listings with script getFindMarket", func(t *testing.T) {
		otu.setUUID(1400)
		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price).
			setFlowDandyMarketOption("find").
			listNFTForEscrowedAuction("user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.buyNFTForMarketSale("user2", "user1", ids[0], price)

		otu.O.Script("getFindMarket",
			WithArg("user", "user1"),
		).AssertWithPointerWant(t, "/itemsForSale/FindMarketAuctionEscrow",
			autogold.Want("getFindMarket", map[string]interface{}{"ghosts": []interface{}{map[string]interface{}{"id": 1402, "listingTypeIdentifier": "A.179b6b1cb6755e31.FindMarketAuctionEscrow.SaleItem"}}}),
		)

		otu.sendDandy("user1", "user2", ids[0]).
			delistAllNFT("user1")

	})

	t.Run("Should be able to return ghost bids with script getFindMarket", func(t *testing.T) {
		otu.setUUID(1800)
		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price).
			setFlowDandyMarketOption("find").
			listNFTForEscrowedAuction("user1", ids[0], price).
			auctionBidMarketEscrow("user2", "user1", ids[0], bidPrice)

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 3, len(itemsForSale))

		otu.buyNFTForMarketSale("user2", "user1", ids[0], price)

		otu.O.Script("getFindMarket",
			WithArg("user", "user2"),
		).AssertWithPointerWant(t, "/marketBids/FindMarketAuctionEscrow",
			autogold.Want("getFindMarketBid", map[string]interface{}{"ghosts": []interface{}{map[string]interface{}{"id": 1802, "listingTypeIdentifier": "A.179b6b1cb6755e31.FindMarketAuctionEscrow.Bid"}}}),
		)

		otu.sendDandy("user1", "user2", ids[0]).
			delistAllNFT("user1")
	})

	t.Run("SoulBound items should be ghostListings", func(t *testing.T) {
		otu.sendSoulBoundNFT("user1", "find").
			registerExampleNFTInNFTRegistry()
		// set market rules
		otu.O.Tx("adminSetSellExampleNFTForFlow",
			WithSigner("find-admin"),
			WithArg("tenant", "find"),
		).AssertSuccess(t)

		// make it non-soulBound before listing
		otu.O.Tx("devtoggleSoulBoundExampleNFT",
			WithSigner("user1"),
			WithArg("id", 1),
			WithArg("soulBound", false),
		).AssertSuccess(t)

		saleId, err := otu.O.Tx("listNFTForAuctionEscrowed",
			WithSigner("user1"),
			WithArg("nftAliasOrIdentifier", exampleNFTType(otu)),
			WithArg("id", 1),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("price", price),
			WithArg("auctionReservePrice", price+5.0),
			WithArg("auctionDuration", 300.0),
			WithArg("auctionExtensionOnLateBid", 60.0),
			WithArg("minimumBidIncrement", 1.0),
			WithArg("auctionStartTime", nil),
			WithArg("auctionValidUntil", otu.currentTime()+100.0),
		).AssertSuccess(t).GetIdFromEvent("EnglishAuction", "id")

		if err != nil {
			panic(err)
		}

		// make it soulBound before listing
		otu.O.Tx("devtoggleSoulBoundExampleNFT",
			WithSigner("user1"),
			WithArg("id", 1),
			WithArg("soulBound", true),
		).AssertSuccess(t)

		otu.O.Script("getFindMarket",
			WithArg("user", "user1"),
		).
			AssertWithPointerWant(t, "/itemsForSale/FindMarketAuctionEscrow/ghosts/0/listingTypeIdentifier",
				autogold.Want("soulBoundGhost", otu.identifier("FindMarketAuctionEscrow", "SaleItem")),
			)

		// Bids will also show as ghost
		otu.O.Tx("bidMarketAuctionEscrowed",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", saleId),
			WithArg("amount", price+5.0),
		).AssertSuccess(t)

		otu.O.Script("getFindMarket",
			WithArg("user", "user2"),
		).Print().
			AssertWithPointerWant(t, "/marketBids/FindMarketAuctionEscrow/ghosts/0/listingTypeIdentifier",
				autogold.Want("Bid", otu.identifier("FindMarketAuctionEscrow", "Bid")),
			)
	})

	// reset for Dapper tests
	otu = NewOverflowTest(t)

	id = otu.setupMarketAndDandyDapper()
	otu.registerDUCInRegistry().
		registerDandyInNFTRegistry().
		setFlowDandyMarketOption("dapper").
		setProfile("user1").
		setProfile("user2").
		createDapperUser("find")

	/* MarketAuction Soft */
	t.Run("Should not be able to bid Auction if item was already sold on direct offer", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.directOfferMarketSoft("user2", "user1", id, 15.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.sendDandy("user2", "user1", id)

		otu.O.Tx("bidMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", bidPrice),
		).
			AssertFailure(t, "this is a ghost listing")

		otu.sendDandy("user1", "user2", id).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to increase bid in Auction Soft if item was already sold on direct offer", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			auctionBidMarketSoft("user2", "user1", id, bidPrice)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_ongoing", itemsForSale[0].SaleType)

		otu.directOfferMarketSoft("user2", "user1", id, 15.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.sendDandy("user2", "user1", id)

		otu.O.Tx("increaseBidMarketAuctionSoft",
			WithSigner("user2"),
			WithArg("id", id),
			WithArg("amount", bidPrice+1.0),
		).
			AssertFailure(t, "this is a ghost listing")

		otu.sendDandy("user1", "user2", id).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to fulfill bid in Auction if item was already sold on direct offer", func(t *testing.T) {

		otu.listNFTForSoftAuction("user1", id, price).
			auctionBidMarketSoft("user2", "user1", id, bidPrice).
			tickClock(700)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "finished_completed", itemsForSale[0].SaleType)

		otu.directOfferMarketSoft("user2", "user1", id, 15.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.sendDandy("user2", "user1", id)

		otu.O.Tx("fulfillMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("id", id),
			WithArg("amount", 15.0),
		).
			AssertFailure(t, "this is a ghost listing")

		otu.sendDandy("user1", "user2", id).
			delistAllNFT("user1")
	})

	t.Run("Should not be able to accept Direct Offer Soft if item was already sold in other form", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))

		otu.sendDandy("user2", "user1", id)

		otu.O.Tx("acceptDirectOfferSoftDapper",
			WithSigner("user1"),
			WithArg("id", id),
		).
			AssertFailure(t, "this is a ghost listing")

		otu.sendDandy("user1", "user2", id).
			delistAllNFT("user1")

	})

	t.Run("Should not be able to fulfill Direct Offer Soft if item was already sold in other form", func(t *testing.T) {

		otu.directOfferMarketSoft("user2", "user1", id, price).
			acceptDirectOfferMarketSoft("user1", id, "user2", price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))

		otu.sendDandy("user2", "user1", id)

		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "this is a ghost listing")

		otu.sendDandy("user1", "user2", id).
			delistAllNFT("user1")
	})

}
