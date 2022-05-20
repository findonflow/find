package test_main

import (
	"encoding/json"
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNFTDetailScript(t *testing.T) {

	price := 10.00

	t.Run("Should be able to get all listings of a person by a script", func(t *testing.T) {
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
		err := otu.O.ScriptFromFile("getListings").Args(otu.O.Arguments().String("user1")).RunMarshalAs(&itemForSaleStruct)
		swallowErr(err)

		err = json.Unmarshal([]byte(expectedSale), &expectedSaleStruct)
		swallowErr(err)
		err = json.Unmarshal([]byte(expectedAuctionEscrow), &expectedAuctionEscrowStruct)
		swallowErr(err)
		err = json.Unmarshal([]byte(expectedAuctionSoft), &expectedAuctionSoftStruct)
		swallowErr(err)
		err = json.Unmarshal([]byte(expectedDirectOfferEscrow), &expectedDirectOfferEscrowStruct)
		swallowErr(err)
		err = json.Unmarshal([]byte(expectedDirectOfferSoft), &expectedDirectOfferSoftStruct)
		swallowErr(err)

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
	})

	t.Run("Should be able to get NFT and listing details by a script", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSale("user1", ids[1], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			listNFTForSoftAuction("user1", ids[1], price)

		otu.O.TransactionFromFile("testListStorefront").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().UInt64(ids[1]).UFix64(10.0)).
			Test(otu.T).AssertSuccess()

		expectedJson := `
		{
			"findMarket": {
				"FindMarketAuctionEscrow": {
					"amount": "10.00000000",
					"auction": {
						"auctionEndsAt": "",
						"currentPrice": "10.00000000",
						"extentionOnLateBid": "60.00000000",
						"minimumBidIncrement": "1.00000000",
						"reservePrice": "15.00000000",
						"startPrice": "10.00000000",
						"timestamp": "1.00000000"
					},
					"bidder": "",
					"bidderName": "",
					"ftAlias": "Flow",
					"ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
					"listingId": "134",
					"listingStatus": "active",
					"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem",
					"listingValidUntil": "",
					"nftId": "134",
					"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"saleType": "active_listed",
					"seller": "0x179b6b1cb6755e31",
					"sellerName": "user1"
				},
				"FindMarketAuctionSoft": {
					"amount": "10.00000000",
					"auction": {
						"auctionEndsAt": "",
						"currentPrice": "10.00000000",
						"extentionOnLateBid": "60.00000000",
						"minimumBidIncrement": "1.00000000",
						"reservePrice": "15.00000000",
						"startPrice": "10.00000000",
						"timestamp": "1.00000000"
					},
					"bidder": "",
					"bidderName": "",
					"ftAlias": "Flow",
					"ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
					"listingId": "134",
					"listingStatus": "active",
					"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionSoft.SaleItem",
					"listingValidUntil": "",
					"nftId": "134",
					"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"saleType": "active_listed",
					"seller": "0x179b6b1cb6755e31",
					"sellerName": "user1"
				},
				"FindMarketSale": {
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
					"nftId": "134",
					"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"saleType": "active_listed",
					"seller": "0x179b6b1cb6755e31",
					"sellerName": "user1"
				}
			},
			"nftDetail": {
				"collectionDescription": "Neo Collectibles FIND",
				"collectionName": "user1",
				"editionNumber": "2",
				"id": "134",
				"name": "Neo Motorcycle 2 of 3",
				"rarity": "",
				"scalars": {
					"Speed": "100.00000000"
				},
				"tags": {
					"NeoMotorCycleTag": "Tag1"
				},
				"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
				"totalInEdition": "3",
				"type": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"uuid": "134",
				"views": {}
			},
			"storefront": {
				"amount": "10.00000000",
				"ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"listingID": "140",
				"nftID": "134",
				"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleCut": [
					{
						"address": "0x179b6b1cb6755e31",
						"amount": "10.00000000",
						"findName": "user1"
					}
				],
				"storefront": "139"
			}
		}
			`

		json := otu.O.ScriptFromFile("getNFTDetails").
			Args(otu.O.Arguments().
				String("user1").
				String("Dandy").
				UInt64(ids[1]).
				StringArray()).
			RunReturnsJsonString()
		fmt.Println("@@@@@@@@@@@@@@@@@")
		fmt.Println(json)
		fmt.Println("@@@@@@@@@@@@@@@@@@")
		assert.JSONEq(otu.T, expectedJson, json)
	})

	t.Run("Should be able to get listing methods from a script", func(t *testing.T) {
		otu := NewOverflowTest(t)

		otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft")

		expectedJson := `
		{
			"FindMarketAuctionEscrow": {
				"ftAlias": [
					"Flow"
				],
				"ftIdentifiers": [
					"A.0ae53cb6e3f42a79.FlowToken.Vault"
				],
				"listingType": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem",
				"status": "active"
			},
			"FindMarketAuctionSoft": {
				"ftAlias": [
					"Flow"
				],
				"ftIdentifiers": [
					"A.0ae53cb6e3f42a79.FlowToken.Vault"
				],
				"listingType": "A.f8d6e0586b0a20c7.FindMarketAuctionSoft.SaleItem",
				"status": "active"
			},
			"FindMarketDirectOfferEscrow": {
				"ftAlias": [
					"Flow"
				],
				"ftIdentifiers": [
					"A.0ae53cb6e3f42a79.FlowToken.Vault"
				],
				"listingType": "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.SaleItem",
				"status": "active"
			},
			"FindMarketDirectOfferSoft": {
				"ftAlias": [
					"Flow"
				],
				"ftIdentifiers": [
					"A.0ae53cb6e3f42a79.FlowToken.Vault"
				],
				"listingType": "A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.SaleItem",
				"status": "active"
			},
			"FindMarketSale": {
				"ftAlias": [
					"Flow"
				],
				"ftIdentifiers": [
					"A.0ae53cb6e3f42a79.FlowToken.Vault"
				],
				"listingType": "A.f8d6e0586b0a20c7.FindMarketSale.SaleItem",
				"status": "active"
			}
		}
		`
		json := otu.O.ScriptFromFile("resolveListing").
			Args(otu.O.Arguments().
				String("Dandy")).
			RunReturnsJsonString()

		assert.JSONEq(otu.T, expectedJson, json)
	})

}

func swallowErr(err error) {
}
