package test_main

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCollectionScripts(t *testing.T) {

	t.Run("Should be able to mint Dandy and then get it by script", func(t *testing.T) {

		expected := `
		{
			"collections": {
				"Dandy": [
					"Dandy81",
					"Dandy80",
					"Dandy82"
				]
			},
			"curatedCollections": {},
			"items": {
				"Dandy80": {
					"collection": "Dandy",
					"contentType": "image",
					"id": "80",
					"image": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"metadata": {},
					"name": "Neo Motorcycle 1 of 3",
					"rarity": "",
					"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"url": "find.xyz",
					"uuid": "80"
				},
				"Dandy81": {
					"collection": "Dandy",
					"contentType": "image",
					"id": "81",
					"image": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"metadata": {},
					"name": "Neo Motorcycle 2 of 3",
					"rarity": "",
					"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"url": "find.xyz",
					"uuid": "81"
				},
				"Dandy82": {
					"collection": "Dandy",
					"contentType": "image",
					"id": "82",
					"image": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"metadata": {},
					"name": "Neo Motorcycle 3 of 3",
					"rarity": "",
					"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"url": "find.xyz",
					"uuid": "82"
				}
			}
		}
		`

		otu := NewOverflowTest(t)
		otu.setupFIND().
			setupDandy("user1").
			registerDandyInNFTRegistry().
			mintThreeExampleDandies()

		result := otu.O.ScriptFromFile("collections").
			Args(otu.O.Arguments().Address("user1")).
			RunReturnsJsonString()
		fmt.Println(result)
		assert.JSONEq(otu.T, expected, result)

	})

	/* Test on address_status script */
	t.Run("Should be able to check the status of an address, with NFT Info and auction Info", func(t *testing.T) {
		otu := NewOverflowTest(t)

		price := 10.0
		id := otu.setupMarketAndDandy()

		otu.O.TransactionFromFile("setProfile").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("https://find.xyz/assets/img/avatars/avatar1.png")).
			Test(otu.T).
			AssertSuccess()

		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", id, price).
			saleItemListed("user1", "ondemand_auction", price).
			auctionBidMarketEscrow("user2", "user1", id, price+5.0)

		result := otu.O.ScriptFromFile("address_status").
			Args(otu.O.Arguments().
				Address("user1")).
			RunReturnsJsonString()

		expected := `{
			"bids": null,
			"itemsForSale": [
				{
					"amount": "15.00000000",
					"auctionReservePrice": "15.00000000",
					"bidder": "0xf3fcd2c1a78f5eee",
					"bidderName": "user2",
					"extensionOnLateBid": "60.00000000",
					"ftAlias": "Flow",
					"listingId": "124",
					"listingValidUntil": "301.00000000",
					"minimumBidIncrement": "1.00000000",
					"nftAlias": "Dandy",
					"nftDescription": "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK",
					"nftId": "124",
					"nftName": "Neo Motorcycle 1 of 3",
					"nftThumbnail": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"saleType": "ongoing_auction",
					"seller": "0x179b6b1cb6755e31",
					"sellerName": "user1",
					"startPrice": "10.00000000"
				}
			],
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
			"marketBids": null,
			"privateMode": "false",
			"profile": {
				"address": "0x179b6b1cb6755e31",
				"allowStoringFollowers": "true",
				"avatar": "https://find.xyz/assets/img/avatars/avatar1.png",
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
						"accept": "A.f8d6e0586b0a20c7.FUSD.Vault",
						"balance": "145.00000000",
						"name": "FUSD",
						"tags": [
							"fusd",
							"stablecoin"
						]
					},
					{
						"accept": "A.0ae53cb6e3f42a79.FlowToken.Vault",
						"balance": "200.00100000",
						"name": "Flow",
						"tags": [
							"flow"
						]
					}
				]
			},
			"relatedAccounts": {}
		}`

		assert.JSONEq(otu.T, expected, result)
	})

}
