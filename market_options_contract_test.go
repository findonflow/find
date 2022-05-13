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
		otu.registerFlowFUSDDandyInRegistry().
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
				"id": "125",
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
				"listingId": "126",
				"listingStatus": "active",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem",
				"listingValidUntil": "",
				"nft": {
					"grouping": "",
					"id": "126",
					"name": "Neo Motorcycle 2 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT"
				},
				"nftId": "126",
				"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleType": "active_listed",
				"seller": "0x179b6b1cb6755e31",
				"sellerName": "user1"
			}]
		`

		var findReport FINDReport
		var expectedGhost []GhostListing
		var expectedListings []SaleItemInformation
		otu.O.ScriptFromFile("address_status").Args(otu.O.Arguments().Account("user1")).RunMarshalAs(&findReport)

		json.Unmarshal([]byte(expectedListingsJson), &expectedListings)
		json.Unmarshal([]byte(expectedGhostJson), &expectedGhost)

		ghost := findReport.ItemsForSale["FindMarketDirectOfferSoft"].Ghosts
		listings := findReport.ItemsForSale["FindMarketAuctionEscrow"].Items

		assert.Equal(otu.T, expectedGhost, ghost)
		assert.Equal(otu.T, expectedListings, listings)

		otu.O.ScriptFromFile("name_status").Args(otu.O.Arguments().Account("user1")).RunMarshalAs(&findReport)

		ghost = findReport.ItemsForSale["FindMarketDirectOfferSoft"].Ghosts
		listings = findReport.ItemsForSale["FindMarketAuctionEscrow"].Items

		assert.Equal(otu.T, expectedGhost, ghost)
		assert.Equal(otu.T, expectedListings, listings)

	})

	t.Run("Should be able to return ghost bids with script addressStatus and nameStatus", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFlowFUSDDandyInRegistry().
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
				"id": "125",
				"listingType": "Type\u003cA.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.Bid\u003e()",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.Bid"
			}
		]`

		expectedGhostAuctionEscrowJson := `[
			{
				"id": "125",
				"listingType": "Type\u003cA.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid\u003e()",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid"
			}
		]`

		expectedBidsJson := `[
			{
				"bidAmount": "15.00000000",
				"bidTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid",
				"id": "126",
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
					"listingId": "126",
					"listingStatus": "active",
					"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem",
					"listingValidUntil": "301.00000000",
					"nft": {
						"grouping": "",
						"id": "126",
						"name": "Neo Motorcycle 2 of 3",
						"rarity": "",
						"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						"type": "A.f8d6e0586b0a20c7.Dandy.NFT"
					},
					"nftId": "126",
					"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"saleType": "active_ongoing",
					"seller": "0x179b6b1cb6755e31",
					"sellerName": "user1"
				}
			}
		]
		`

		var findReport FINDReport
		var expectedGhostDirectOffer []GhostListing
		var expectedGhostAuctionEscrow []GhostListing
		var expectedBids []BidInfo
		otu.O.ScriptFromFile("address_status").Args(otu.O.Arguments().Account("user2")).RunMarshalAs(&findReport)

		json.Unmarshal([]byte(expectedGhostDirectOfferJson), &expectedGhostDirectOffer)
		json.Unmarshal([]byte(expectedGhostAuctionEscrowJson), &expectedGhostAuctionEscrow)
		json.Unmarshal([]byte(expectedBidsJson), &expectedBids)

		ghostDirectOffer := findReport.MarketBids["FindMarketDirectOfferSoft"].Ghosts
		ghostAuctionEscrow := findReport.MarketBids["FindMarketAuctionEscrow"].Ghosts
		bids := findReport.MarketBids["FindMarketAuctionEscrow"].Items

		assert.Equal(otu.T, expectedGhostDirectOffer, ghostDirectOffer)
		assert.Equal(otu.T, expectedGhostAuctionEscrow, ghostAuctionEscrow)
		assert.Equal(otu.T, expectedBids, bids)

		otu.O.ScriptFromFile("name_status").Args(otu.O.Arguments().Account("user2")).RunMarshalAs(&findReport)

		json.Unmarshal([]byte(expectedGhostDirectOfferJson), &expectedGhostDirectOffer)
		json.Unmarshal([]byte(expectedGhostAuctionEscrowJson), &expectedGhostAuctionEscrow)
		json.Unmarshal([]byte(expectedBidsJson), &expectedBids)

		ghostDirectOffer = findReport.MarketBids["FindMarketDirectOfferSoft"].Ghosts
		ghostAuctionEscrow = findReport.MarketBids["FindMarketAuctionEscrow"].Ghosts
		bids = findReport.MarketBids["FindMarketAuctionEscrow"].Items

		assert.Equal(otu.T, expectedGhostDirectOffer, ghostDirectOffer)
		assert.Equal(otu.T, expectedGhostAuctionEscrow, ghostAuctionEscrow)
		assert.Equal(otu.T, expectedBids, bids)

	})

}
