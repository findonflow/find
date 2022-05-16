package test_main

import (
	"encoding/json"
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNFTDetailScript(t *testing.T) {

	price := 10.00

	t.Run("Should be able to get all listings of a person by a script. ", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSale("user1", ids[1], price).
			directOfferMarketSoft("user2", "user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			listNFTForSoftAuction("user1", ids[1], price)

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 5, len(itemsForSale))

		expectedSale := `
	[		{
				"amount": "10.00000000",
				"auction": "",
				"bidder": "",
				"bidderName": "",
				"ftAlias": "Flow",
				"ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"listingId": "134",
				"listingStatus": "active",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketSale.SaleItem",
				"listingValidUntil": "",
				"nft": {
					"grouping": "",
					"id": "134",
					"name": "Neo Motorcycle 2 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT"
				},
				"nftId": "134",
				"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleType": "active_listed",
				"seller": "0x179b6b1cb6755e31",
				"sellerName": "user1"
			}]
			`
		expectedAuctionEscrow := `
	[		{
				"amount": "10.00000000",
				"auction": {
					"auctionEndsAt": "",
					"currentPrice": "10.00000000",
					"extentionOnLateBid": "60.00000000",
					"minimumBidIncrement": "1.00000000",
					"reservePrice": "15.00000000",
					"startPrice": "10.00000000",
					"timestamp": "1652277195.00000000"
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
					"grouping": "",
					"id": "134",
					"name": "Neo Motorcycle 2 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT"
				},
				"nftId": "134",
				"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleType": "active_listed",
				"seller": "0x179b6b1cb6755e31",
				"sellerName": "user1"
			}]
			`

		expectedAuctionSoft := `
	[		{
				"amount": "10.00000000",
				"auction": {
					"auctionEndsAt": "",
					"currentPrice": "10.00000000",
					"extentionOnLateBid": "60.00000000",
					"minimumBidIncrement": "1.00000000",
					"reservePrice": "15.00000000",
					"startPrice": "10.00000000",
					"timestamp": "1652277195.00000000"
				},
				"bidder": "",
				"bidderName": "",
				"ftAlias": "Flow",
				"ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"listingId": "134",
				"listingStatus": "active",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionSoft.SaleItem",
				"listingValidUntil": "",
				"nft": {
					"grouping": "",
					"id": "134",
					"name": "Neo Motorcycle 2 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT"
				},
				"nftId": "134",
				"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleType": "active_listed",
				"seller": "0x179b6b1cb6755e31",
				"sellerName": "user1"
			}]
			`

		expectedDirectOfferEscrow := `
	[		{
				"amount": "10.00000000",
				"auction": "",
				"bidder": "0xf3fcd2c1a78f5eee",
				"bidderName": "user2",
				"ftAlias": "Flow",
				"ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"listingId": "133",
				"listingStatus": "active",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.SaleItem",
				"listingValidUntil": "",
				"nft": {
					"grouping": "",
					"id": "133",
					"name": "Neo Motorcycle 1 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT"
				},
				"nftId": "133",
				"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleType": "active_ongoing",
				"seller": "0x179b6b1cb6755e31",
				"sellerName": "user1"
			}]
			`

		expectedDirectOfferSoft := `
	[		{
				"amount": "10.00000000",
				"auction": "",
				"bidder": "0xf3fcd2c1a78f5eee",
				"bidderName": "user2",
				"ftAlias": "Flow",
				"ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"listingId": "133",
				"listingStatus": "active",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.SaleItem",
				"listingValidUntil": "",
				"nft": {
					"grouping": "",
					"id": "133",
					"name": "Neo Motorcycle 1 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT"
				},
				"nftId": "133",
				"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleType": "active_ongoing",
				"seller": "0x179b6b1cb6755e31",
				"sellerName": "user1"
			}]
			`

		var itemForSaleStruct map[string]SaleItemCollectionReport

		var expectedSaleStruct []SaleItemInformation
		var expectedAuctionEscrowStruct []SaleItemInformation
		var expectedAuctionSoftStruct []SaleItemInformation
		var expectedDirectOfferEscrowStruct []SaleItemInformation
		var expectedDirectOfferSoftStruct []SaleItemInformation
		otu.O.ScriptFromFile("getListingsByAddress").Args(otu.O.Arguments().Account("user1")).RunMarshalAs(&itemForSaleStruct)

		json.Unmarshal([]byte(expectedSale), &expectedSaleStruct)
		json.Unmarshal([]byte(expectedAuctionEscrow), &expectedAuctionEscrowStruct)
		json.Unmarshal([]byte(expectedAuctionSoft), &expectedAuctionSoftStruct)
		json.Unmarshal([]byte(expectedDirectOfferEscrow), &expectedDirectOfferEscrowStruct)
		json.Unmarshal([]byte(expectedDirectOfferSoft), &expectedDirectOfferSoftStruct)

		FindMarketSale := itemForSaleStruct["FindMarketSale"].Items
		FindMarketAuctionEscrow := itemForSaleStruct["FindMarketAuctionEscrow"].Items
		FindMarketAuctionSoft := itemForSaleStruct["FindMarketAuctionSoft"].Items
		FindMarketDirectOfferEscrow := itemForSaleStruct["FindMarketDirectOfferEscrow"].Items
		FindMarketDirectOfferSoft := itemForSaleStruct["FindMarketDirectOfferSoft"].Items

		assert.Equal(otu.T, expectedSaleStruct, FindMarketSale)
		assert.Equal(otu.T, expectedAuctionEscrowStruct, FindMarketAuctionEscrow)
		assert.Equal(otu.T, expectedAuctionSoftStruct, FindMarketAuctionSoft)
		assert.Equal(otu.T, expectedDirectOfferEscrowStruct, FindMarketDirectOfferEscrow)
		assert.Equal(otu.T, expectedDirectOfferSoftStruct, FindMarketDirectOfferSoft)

		otu.O.ScriptFromFile("getListingsByName").Args(otu.O.Arguments().Account("user1")).RunMarshalAs(&itemForSaleStruct)

		FindMarketSale = itemForSaleStruct["FindMarketSale"].Items
		FindMarketAuctionEscrow = itemForSaleStruct["FindMarketAuctionEscrow"].Items
		FindMarketAuctionSoft = itemForSaleStruct["FindMarketAuctionSoft"].Items
		FindMarketDirectOfferEscrow = itemForSaleStruct["FindMarketDirectOfferEscrow"].Items
		FindMarketDirectOfferSoft = itemForSaleStruct["FindMarketDirectOfferSoft"].Items

		assert.Equal(otu.T, expectedSaleStruct, FindMarketSale)
		assert.Equal(otu.T, expectedAuctionEscrowStruct, FindMarketAuctionEscrow)
		assert.Equal(otu.T, expectedAuctionSoftStruct, FindMarketAuctionSoft)
		assert.Equal(otu.T, expectedDirectOfferEscrowStruct, FindMarketDirectOfferEscrow)
		assert.Equal(otu.T, expectedDirectOfferSoftStruct, FindMarketDirectOfferSoft)

	})

	t.Run("Should be able to get the nft and auction detail of an NFT by a script. ", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSale("user1", ids[1], price).
			directOfferMarketSoft("user2", "user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			listNFTForSoftAuction("user1", ids[1], price)

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 5, len(itemsForSale))
		fmt.Println("@@@@@@@@@@@@@@@@@@@@@@@@")
		expectedSale := `
		[		{
					"amount": "10.00000000",
					"auction": "",
					"bidder": "",
					"bidderName": "",
					"ftAlias": "Flow",
					"ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
					"listingId": "134",
					"listingStatus": "active",
					"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketSale.SaleItem",
					"listingValidUntil": "",
					"nft": {
						"grouping": "",
						"id": "134",
						"name": "Neo Motorcycle 2 of 3",
						"rarity": "",
						"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						"type": "A.f8d6e0586b0a20c7.Dandy.NFT"
					},
					"nftId": "134",
					"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"saleType": "active_listed",
					"seller": "0x179b6b1cb6755e31",
					"sellerName": "user1"
				}]
				`
		expectedAuctionEscrow := `
		[		{
					"amount": "10.00000000",
					"auction": {
						"auctionEndsAt": "",
						"currentPrice": "10.00000000",
						"extentionOnLateBid": "60.00000000",
						"minimumBidIncrement": "1.00000000",
						"reservePrice": "15.00000000",
						"startPrice": "10.00000000",
						"timestamp": "1652277195.00000000"
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
						"grouping": "",
						"id": "134",
						"name": "Neo Motorcycle 2 of 3",
						"rarity": "",
						"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						"type": "A.f8d6e0586b0a20c7.Dandy.NFT"
					},
					"nftId": "134",
					"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"saleType": "active_listed",
					"seller": "0x179b6b1cb6755e31",
					"sellerName": "user1"
				}]
				`

		expectedAuctionSoft := `
		[		{
					"amount": "10.00000000",
					"auction": {
						"auctionEndsAt": "",
						"currentPrice": "10.00000000",
						"extentionOnLateBid": "60.00000000",
						"minimumBidIncrement": "1.00000000",
						"reservePrice": "15.00000000",
						"startPrice": "10.00000000",
						"timestamp": "1652277195.00000000"
					},
					"bidder": "",
					"bidderName": "",
					"ftAlias": "Flow",
					"ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
					"listingId": "134",
					"listingStatus": "active",
					"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionSoft.SaleItem",
					"listingValidUntil": "",
					"nft": {
						"grouping": "",
						"id": "134",
						"name": "Neo Motorcycle 2 of 3",
						"rarity": "",
						"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						"type": "A.f8d6e0586b0a20c7.Dandy.NFT"
					},
					"nftId": "134",
					"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"saleType": "active_listed",
					"seller": "0x179b6b1cb6755e31",
					"sellerName": "user1"
				}]
				`

		var itemForSaleStruct map[string]SaleItemCollectionReport

		var expectedSaleStruct []SaleItemInformation
		var expectedAuctionEscrowStruct []SaleItemInformation
		var expectedAuctionSoftStruct []SaleItemInformation
		otu.O.ScriptFromFile("resolveListingByAddress").Args(otu.O.Arguments().Account("user1").UInt64(ids[1])).RunMarshalAs(&itemForSaleStruct)

		json.Unmarshal([]byte(expectedSale), &expectedSaleStruct)
		json.Unmarshal([]byte(expectedAuctionEscrow), &expectedAuctionEscrowStruct)
		json.Unmarshal([]byte(expectedAuctionSoft), &expectedAuctionSoftStruct)

		FindMarketSale := itemForSaleStruct["FindMarketSale"].Items
		FindMarketAuctionEscrow := itemForSaleStruct["FindMarketAuctionEscrow"].Items
		FindMarketAuctionSoft := itemForSaleStruct["FindMarketAuctionSoft"].Items

		assert.Equal(otu.T, expectedSaleStruct, FindMarketSale)
		assert.Equal(otu.T, expectedAuctionEscrowStruct, FindMarketAuctionEscrow)
		assert.Equal(otu.T, expectedAuctionSoftStruct, FindMarketAuctionSoft)

		result, err := otu.O.ScriptFromFile("resolveListingByAddress").Args(otu.O.Arguments().Account("user1").UInt64(ids[1])).RunReturns()
		fmt.Println(result)
		fmt.Println(err)
		FindMarketSale = itemForSaleStruct["FindMarketSale"].Items
		FindMarketAuctionEscrow = itemForSaleStruct["FindMarketAuctionEscrow"].Items
		FindMarketAuctionSoft = itemForSaleStruct["FindMarketAuctionSoft"].Items

		assert.Equal(otu.T, expectedSaleStruct, FindMarketSale)
		assert.Equal(otu.T, expectedAuctionEscrowStruct, FindMarketAuctionEscrow)
		assert.Equal(otu.T, expectedAuctionSoftStruct, FindMarketAuctionSoft)

	})

}
