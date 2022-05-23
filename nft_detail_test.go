package test_main

import (
	"encoding/json"
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
				"nft": {
					"id": "134",
					"name": "Neo Motorcycle 2 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"editionNumber"	: "2",
					"totalInEdition"	: "3",
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
					"id": "134",
					"name": "Neo Motorcycle 2 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"editionNumber"	: "2",
					"totalInEdition"	: "3",
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
					"id": "134",
					"name": "Neo Motorcycle 2 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"editionNumber"	: "2",
					"totalInEdition"	: "3",
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
					"id": "133",
					"name": "Neo Motorcycle 1 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"editionNumber"	: "1",
					"totalInEdition"	: "3",
					"CollectionName" : "user1",
					"CollectionDescription": "Neo Collectibles FIND"
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
					"id": "133",
					"name": "Neo Motorcycle 1 of 3",
					"rarity": "",
					"thumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"editionNumber"	: "1",
					"totalInEdition"	: "3",
					"CollectionName" : "user1",
					"CollectionDescription": "Neo Collectibles FIND"
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
		err := otu.O.ScriptFromFile("getListings").Args(otu.O.Arguments().Account("account").String("user1")).RunMarshalAs(&itemForSaleStruct)
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

	t.Run("Should be able to get the nft and auction detail of an NFT by a script", func(t *testing.T) {
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

		expectedJson := `
{
        	            	    "findMarket": {
        	            	        "FindMarketAuctionEscrow": {
        	            	            "ghosts": null,
        	            	            "items": [
        	            	                {
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
        	            	                    "nft": {
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
        	            	                        "type": "A.f8d6e0586b0a20c7.Dandy.NFT"
        	            	                    },
        	            	                    "nftId": "134",
        	            	                    "nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
        	            	                    "saleType": "active_listed",
        	            	                    "seller": "0x179b6b1cb6755e31",
        	            	                    "sellerName": "user1"
        	            	                }
        	            	            ]
        	            	        },
        	            	        "FindMarketAuctionSoft": {
        	            	            "ghosts": null,
        	            	            "items": [
        	            	                {
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
        	            	                    "nft": {
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
        	            	                        "type": "A.f8d6e0586b0a20c7.Dandy.NFT"
        	            	                    },
        	            	                    "nftId": "134",
        	            	                    "nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
        	            	                    "saleType": "active_listed",
        	            	                    "seller": "0x179b6b1cb6755e31",
        	            	                    "sellerName": "user1"
        	            	                }
        	            	            ]
        	            	        },
        	            	        "FindMarketSale": {
        	            	            "ghosts": null,
        	            	            "items": [
        	            	                {
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
        	            	                        "type": "A.f8d6e0586b0a20c7.Dandy.NFT"
        	            	                    },
        	            	                    "nftId": "134",
        	            	                    "nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
        	            	                    "saleType": "active_listed",
        	            	                    "seller": "0x179b6b1cb6755e31",
        	            	                    "sellerName": "user1"
        	            	                }
        	            	            ]
        	            	        }
        	            	    },
														"storefront" : ""
        	            	}`

		json := otu.O.ScriptFromFile("resolveListing").Args(otu.O.Arguments().Account("account").String("user1").UInt64(ids[1])).RunReturnsJsonString()

		assert.JSONEq(otu.T, expectedJson, json)
	})

	t.Run("Should be able to get storefront listings of an NFT by a script", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSale("user1", ids[1], price)

		otu.O.TransactionFromFile("testListStorefront").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().UInt64(ids[1]).UFix64(10.0)).
			Test(otu.T).AssertSuccess()

		expectedJson := `
{
	"findMarket": {
        "FindMarketSale": {
            "ghosts": null,
            "items": [
                {
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
                        "type": "A.f8d6e0586b0a20c7.Dandy.NFT"
                    },
                    "nftId": "134",
                    "nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
                    "saleType": "active_listed",
                    "seller": "0x179b6b1cb6755e31",
                    "sellerName": "user1"
                }
            ]
        }
    },
    "storefront": {
        "ghosts": null,
        "items": [
            {
                "amount": "10.00000000",
                "ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
                "listingID": "138",
                "nftID": "134",
                "nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
                "saleCut": [
                    {
                        "address": "0x179b6b1cb6755e31",
                        "amount": "10.00000000",
                        "findName": "user1"
                    }
                ],
                "storefront": "137"
            }
        ]
    }
}
`

		json := otu.O.ScriptFromFile("resolveListing").Args(otu.O.Arguments().Account("account").String("user1").UInt64(ids[1])).RunReturnsJsonString()

		assert.JSONEq(otu.T, expectedJson, json)
	})

}

func swallowErr(err error) {
}
