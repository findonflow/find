package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNFTDetailScript(t *testing.T) {

	price := 10.00

	t.Run("Should be able to get all listings of a person by a script", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setProfile("user1").
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

		actual := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()

		expected := `
{
	    "FINDReport": {
	        "bids": null,
	        "itemsForSale": {
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
							"saleItemExtraField" : {} ,
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
							"saleItemExtraField" : {} ,
							"saleType": "active_listed",
	                        "seller": "0x179b6b1cb6755e31",
	                        "sellerName": "user1"
	                    }
	                ]
	            },
	            "FindMarketDirectOfferEscrow": {
	                "ghosts": null,
	                "items": [
	                    {
	                        "amount": "10.00000000",
	                        "auction": "",
	                        "bidder": "0xf3fcd2c1a78f5eee",
	                        "bidderName": "user2",
	                        "ftAlias": "Flow",
	                        "ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
	                        "listingId": "133",
	                        "listingStatus": "active",
	                        "listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.SaleItem",
	                        "listingValidUntil": "100.00000000",
	                        "nft": {
	                            "collectionDescription": "Neo Collectibles FIND",
	                            "collectionName": "user1",
	                            "editionNumber": "1",
	                            "id": "133",
	                            "name": "Neo Motorcycle 1 of 3",
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
	                        "nftId": "133",
	                        "nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
							"saleItemExtraField" : {} ,
	                        "saleType": "active_ongoing",
	                        "seller": "0x179b6b1cb6755e31",
	                        "sellerName": "user1"
	                    }
	                ]
	            },
	            "FindMarketDirectOfferSoft": {
	                "ghosts": null,
	                "items": [
	                    {
	                        "amount": "10.00000000",
	                        "auction": "",
	                        "bidder": "0xf3fcd2c1a78f5eee",
	                        "bidderName": "user2",
	                        "ftAlias": "Flow",
	                        "ftTypeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
	                        "listingId": "133",
	                        "listingStatus": "active",
	                        "listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.SaleItem",
	                        "listingValidUntil": "100.00000000",
	                        "nft": {
	                            "collectionDescription": "Neo Collectibles FIND",
	                            "collectionName": "user1",
	                            "editionNumber": "1",
	                            "id": "133",
	                            "name": "Neo Motorcycle 1 of 3",
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
	                        "nftId": "133",
	                        "nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
							"saleItemExtraField" : {} ,
	                        "saleType": "active_ongoing",
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
	                        "listingValidUntil": "100.00000000",
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
							"saleItemExtraField" : {} ,
	                        "saleType": "active_listed",
	                        "seller": "0x179b6b1cb6755e31",
	                        "sellerName": "user1"
	                    }
	                ]
	            }
	        },
	        "leases": [
	            {
	                "addons": [
	                    "forge"
	                ],
	                "address": "0x179b6b1cb6755e31",
	                "auctionEnds": "",
	                "auctionReservePrice": "",
	                "auctionStartPrice": "",
	                "cost": "5.00000000",
	                "currentTime": "1.00000000",
	                "extensionOnLateBid": "300.00000000",
	                "latestBid": "",
	                "latestBidBy": "",
	                "lockedUntil": "39312001.00000000",
	                "name": "user1",
	                "salePrice": "",
	                "status": "TAKEN",
	                "validUntil": "31536001.00000000"
	            }
	        ],
	        "marketBids": {},
	        "privateMode": "false",
	        "profile": {
	            "address": "0x179b6b1cb6755e31",
	            "allowStoringFollowers": "true",
	            "avatar": "https://find.xyz/assets/img/avatars/avatar14.png",
	            "collections": null,
	            "createdAt": "find",
	            "description": "",
	            "findName": "user1",
	            "followers": null,
	            "following": null,
	            "gender": "",
	            "links": null,
	            "name": "user1",
	            "tags": null,
	            "wallets": [
	                {
	                    "accept": "A.0ae53cb6e3f42a79.FlowToken.Vault",
	                    "balance": "100.00100000",
	                    "name": "Flow",
	                    "tags": [
	                        "flow"
	                    ]
	                },
	                {
	                    "accept": "A.f8d6e0586b0a20c7.FUSD.Vault",
	                    "balance": "45.00000000",
	                    "name": "FUSD",
	                    "tags": [
	                        "fusd",
	                        "stablecoin"
	                    ]
	                },
	                {
	                    "accept": "A.f8d6e0586b0a20c7.FiatToken.Vault",
	                    "balance": "100.00000000",
	                    "name": "USDC",
	                    "tags": [
	                        "usdc",
	                        "stablecoin"
	                    ]
	                }
	            ]
	        },
	        "relatedAccounts": {}
	    },
	    "NameReport": {
	        "cost": "5.00000000",
	        "status": "TAKEN"
	    }
	}
		`
		assert.JSONEq(otu.T, expected, actual)

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
	    "allowedListingActions": {
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
	    },
	    "findMarket": {
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
	            "listingValidUntil": "100.00000000",
	            "nft": "",
	            "nftId": "134",
	            "nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleItemExtraField" : {} ,
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
	        "royalties": [
	            {
	                "address": "0x179b6b1cb6755e31",
	                "cut": "0.05000000",
	                "findName": "user1",
	                "royaltyName": "artist"
	            },
	            {
	                "address": "0xf8d6e0586b0a20c7",
	                "cut": "0.02500000",
	                "findName": "",
	                "royaltyName": "platform"
	            }
	        ],
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
	}
			`

		json := otu.O.ScriptFromFile("getNFTDetails").
			Args(otu.O.Arguments().
				String("user1").
				String("Dandy").
				UInt64(ids[1]).
				StringArray()).
			RunReturnsJsonString()
		assert.JSONEq(otu.T, expectedJson, json)
	})

}
