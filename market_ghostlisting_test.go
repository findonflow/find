package test_main

import (
	"encoding/json"
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
			Test(otu.T).AssertFailure("This listing is a ghost listing")

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
			Test(otu.T).AssertFailure("This listing is a ghost listing")

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
			Test(otu.T).AssertFailure("This bid is on a ghostlisting, so you should cancel the original bid and get your funds back")

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

		otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

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
			Test(otu.T).AssertFailure("This listing is a ghost listing")

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
			Test(otu.T).AssertFailure("This bid is on a ghostlisting, so you should cancel the original bid and get your funds back")

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

		otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

		itemsForSale = otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

		otu.O.TransactionFromFile("fulfillMarketAuctionSoft").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("account").
				UInt64(id)).
			Test(otu.T).AssertFailure("Cannot fulfill market auction on ghost listing")

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
				UFix64(price)).
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
			Test(otu.T).AssertFailure("Cannot fulfill market offer on ghost listing")

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
				UFix64(price)).
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
			Test(otu.T).AssertFailure("This offer is made on a ghost listing")

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
				UInt64(id)).
			Test(otu.T).AssertFailure("Cannot fulfill market offer on ghost listing")

	})

	t.Run("Should be able to return ghost listings with script getStatus", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			directOfferMarketSoft("user2", "user1", ids[0], price).
			acceptDirectOfferMarketSoft("user1", ids[0], "user2", price).
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", ids[1], price)

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 3, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", ids[0], "user2", price)

		expectedGhostJson := `
			[{
				"id": "133",
				"listingType": "Type\u003cA.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.SaleItem\u003e()",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.SaleItem"
			}]
		`

		expectedListingsJson := `
			[{
				"amount": "10.00000000",
				"auction": {
					"auctionEndsAt": "",
					"currentPrice": "10.00000000",
					"extentionOnLateBid": "60.00000000",
					"minimumBidIncrement": "1.00000000",
					"reservePrice": "15.00000000",
					"startPrice": "10.00000000"
				},
				"bidder": "",
				"bidderName": "",
				"ftAlias": "Flow",
				"ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"listingId": "134",
				"listingStatus": "active",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem",
				"listingValidUntil": "",
				"nft": {
					"id": "134",
					"name": "Neo Motorcycle 2 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"EditionNumber" : "2",
					"TotalInEdition" : "3",
					"CollectionName": "user1",
					"CollectionDescription": "Neo Collectibles FIND"
				},
				"nftId": "134",
				"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleType": "active_listed",
				"seller": "0x179b6b1cb6755e31",
				"sellerName": "user1"
			}]
		`

		var report Report
		var expectedGhost []GhostListing
		var expectedListings []SaleItemInformation

		err := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunMarshalAs(&report)
		assert.NoError(otu.T, err)

		err = json.Unmarshal([]byte(expectedListingsJson), &expectedListings)
		assert.NoError(otu.T, err)

		err = json.Unmarshal([]byte(expectedGhostJson), &expectedGhost)
		assert.NoError(otu.T, err)

		ghost := report.FINDReport.ItemsForSale["FindMarketDirectOfferSoft"].Ghosts
		listings := report.FINDReport.ItemsForSale["FindMarketAuctionEscrow"].Items

		assert.Equal(otu.T, expectedGhost, ghost)
		assert.Equal(otu.T, expectedListings, listings)

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
			auctionBidMarketEscrow("user2", "user1", ids[1], bidPrice)

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 4, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", ids[0], "user2", price)

		expectedGhostDirectOfferJson := `[
			{
				"id": "133",
				"listingType": "Type\u003cA.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.Bid\u003e()",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.Bid"
			}
		]`

		expectedGhostAuctionEscrowJson := `[
			{
				"id": "133",
				"listingType": "Type\u003cA.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid\u003e()",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid"
			}
		]`

		expectedBidsJson := `[
			{
				"bidAmount": "15.00000000",
				"bidTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid",
				"id": "134",
				"item": {
					"amount": "15.00000000",
					"auction": {
						"auctionEndsAt": "301.00000000",
						"currentPrice": "15.00000000",
						"extentionOnLateBid": "60.00000000",
						"minimumBidIncrement": "1.00000000",
						"reservePrice": "15.00000000",
						"startPrice": "10.00000000"
					},
					"bidder": "0xf3fcd2c1a78f5eee",
					"bidderName": "user2",
					"ftAlias": "Flow",
					"ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
					"listingId": "134",
					"listingStatus": "ended",
					"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem",
					"listingValidUntil": "301.00000000",
					"nft": {
						"id": "134",
						"name": "Neo Motorcycle 2 of 3",
						"rarity": "",
						"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						"type": "A.f8d6e0586b0a20c7.Dandy.NFT",
						"EditionNumber" : "2",
						"TotalInEdition" : "3",
						"CollectionName" : "user1",
					"CollectionDescription": "Neo Collectibles FIND"
					},
					"nftId": "134",
					"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"saleType": "active_ongoing",
					"seller": "0x179b6b1cb6755e31",
					"sellerName": "user1"
				}
			}
		]
		`

		var report Report
		var expectedGhostDirectOffer []GhostListing
		var expectedGhostAuctionEscrow []GhostListing
		var expectedBids []BidInfo

		err := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user2")).RunMarshalAs(&report)
		assert.NoError(otu.T, err)

		err = json.Unmarshal([]byte(expectedGhostDirectOfferJson), &expectedGhostDirectOffer)
		assert.NoError(otu.T, err)

		err = json.Unmarshal([]byte(expectedGhostAuctionEscrowJson), &expectedGhostAuctionEscrow)
		assert.NoError(otu.T, err)

		err = json.Unmarshal([]byte(expectedBidsJson), &expectedBids)
		assert.NoError(otu.T, err)

		ghostDirectOffer := report.FINDReport.MarketBids["FindMarketDirectOfferSoft"].Ghosts
		ghostAuctionEscrow := report.FINDReport.MarketBids["FindMarketAuctionEscrow"].Ghosts
		bids := report.FINDReport.MarketBids["FindMarketAuctionEscrow"].Items

		assert.Equal(otu.T, expectedGhostDirectOffer, ghostDirectOffer)
		assert.Equal(otu.T, expectedGhostAuctionEscrow, ghostAuctionEscrow)
		assert.Equal(otu.T, expectedBids, bids)

	})
}
