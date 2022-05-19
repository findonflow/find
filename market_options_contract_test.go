package test_main

import (
	"encoding/json"
	"testing"

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
					"CollectionName" : "user1",
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
		otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunMarshalAs(&report)

		json.Unmarshal([]byte(expectedListingsJson), &expectedListings)
		json.Unmarshal([]byte(expectedGhostJson), &expectedGhost)

		ghost := report.FINDReport.ItemsForSale["FindMarketDirectOfferSoft"].Ghosts
		listings := report.FINDReport.ItemsForSale["FindMarketAuctionEscrow"].Items

		assert.Equal(otu.T, expectedGhost, ghost)
		assert.Equal(otu.T, expectedListings, listings)
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
					"listingStatus": "active",
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
		// var findReport FINDReport
		var expectedGhostDirectOffer []GhostListing
		var expectedGhostAuctionEscrow []GhostListing
		var expectedBids []BidInfo

		userAddress := otu.accountAddress("user2")
		otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String(userAddress)).RunMarshalAs(&report)

		json.Unmarshal([]byte(expectedGhostDirectOfferJson), &expectedGhostDirectOffer)
		json.Unmarshal([]byte(expectedGhostAuctionEscrowJson), &expectedGhostAuctionEscrow)
		json.Unmarshal([]byte(expectedBidsJson), &expectedBids)

		ghostDirectOffer := report.FINDReport.MarketBids["FindMarketDirectOfferSoft"].Ghosts
		ghostAuctionEscrow := report.FINDReport.MarketBids["FindMarketAuctionEscrow"].Ghosts
		bids := report.FINDReport.MarketBids["FindMarketAuctionEscrow"].Items

		assert.Equal(otu.T, expectedGhostDirectOffer, ghostDirectOffer)
		assert.Equal(otu.T, expectedGhostAuctionEscrow, ghostAuctionEscrow)
		assert.Equal(otu.T, expectedBids, bids)

	})

}
