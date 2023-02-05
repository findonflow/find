package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestMarketOptionsContract(t *testing.T) {

	bidPrice := 15.00
	price := 10.00

	otu := NewOverflowTest(t)

	ids := otu.setupMarketAndMintDandys()
	otu.registerFtInRegistry().
		setFlowDandyMarketOption().
		listNFTForEscrowedAuction("user1", ids[1], price).
		setProfile("user1").
		setProfile("user2")

	t.Run("Should be able to return ghost listings with script addressStatus and nameStatus", func(t *testing.T) {

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 2, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", ids[0], "user2", price)

		otu.O.Script("getStatus",
			WithArg("user", "user1"),
		).AssertWithPointerWant(t,
			"/FINDReport/itemsForSale",
			autogold.Want("ghostListing", map[string]interface{}{"FindMarketAuctionEscrow": map[string]interface{}{"items": []interface{}{map[string]interface{}{
				"amount": 10,
				"auction": map[string]interface{}{
					"currentPrice":        10,
					"extentionOnLateBid":  60,
					"minimumBidIncrement": 1,
					"reservePrice":        15,
					"startPrice":          10,
					"timestamp":           1,
				},
				"ftAlias":               "Flow",
				"ftTypeIdentifier":      "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"listingId":             603,
				"listingStatus":         "active",
				"listingTypeIdentifier": "A.179b6b1cb6755e31.FindMarketAuctionEscrow.SaleItem",
				"listingValidUntil":     101,
				"nft": map[string]interface{}{
					"collectionDescription": "Neo Collectibles FIND",
					"collectionName":        "user1",
					"editionNumber":         2,
					"id":                    603,
					"name":                  "Neo Motorcycle 2 of 3",
					"scalars": map[string]interface{}{
						"Speed":              100,
						"date.Birthday":      1.660145023e+09,
						"edition_set_max":    3,
						"edition_set_number": 2,
						"uuid":               603,
					},
					"tags": map[string]interface{}{
						"NeoMotorCycleTag": "Tag1",
						"external_url":     "https://find.xyz/collection/user1/dandy/603",
					},
					"thumbnail":      "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"totalInEdition": 3,
					"type":           "A.179b6b1cb6755e31.Dandy.NFT",
				},
				"nftId":         603,
				"nftIdentifier": "A.179b6b1cb6755e31.Dandy.NFT",
				"saleType":      "active_listed",
				"seller":        "0x120e725050340cab",
				"sellerName":    "user1",
			}}}}),
		)

		otu.sendDandy("user1", "user2", ids[0]).
			sendFT("user1", "user2", "Flow", price)
		otu.delistAllNFT("user1")

	})

	t.Run("Should be able to return ghost bids with script addressStatus and nameStatus", func(t *testing.T) {

		otu.listNFTForEscrowedAuction("user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			auctionBidMarketEscrow("user2", "user1", ids[0], bidPrice).
			auctionBidMarketEscrow("user2", "user1", ids[1], bidPrice).
			directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		fmt.Println(itemsForSale)
		assert.Equal(t, 3, len(itemsForSale))

		otu.acceptDirectOfferMarketEscrowed("user1", ids[0], "user2", price)

		otu.O.Script("getStatus",
			WithArg("user", "user1"),
		).AssertWithPointerWant(t,
			"/FINDReport/itemsForSale",
			autogold.Want("ghostBids", map[string]interface{}{"FindMarketAuctionEscrow": map[string]interface{}{
				"ghosts": []interface{}{map[string]interface{}{
					"id":                    602,
					"listingTypeIdentifier": "A.179b6b1cb6755e31.FindMarketAuctionEscrow.SaleItem",
				}},
				"items": []interface{}{map[string]interface{}{
					"amount": 15,
					"auction": map[string]interface{}{
						"auctionEndsAt":       301,
						"currentPrice":        15,
						"extentionOnLateBid":  60,
						"minimumBidIncrement": 1,
						"reservePrice":        15,
						"startPrice":          10,
						"timestamp":           1,
					},
					"bidder":                "0xf669cb8d41ce0c74",
					"bidderName":            "user2",
					"ftAlias":               "Flow",
					"ftTypeIdentifier":      "A.0ae53cb6e3f42a79.FlowToken.Vault",
					"listingId":             603,
					"listingStatus":         "active",
					"listingTypeIdentifier": "A.179b6b1cb6755e31.FindMarketAuctionEscrow.SaleItem",
					"listingValidUntil":     301,
					"nft": map[string]interface{}{
						"collectionDescription": "Neo Collectibles FIND",
						"collectionName":        "user1",
						"editionNumber":         2,
						"id":                    603,
						"name":                  "Neo Motorcycle 2 of 3",
						"scalars": map[string]interface{}{
							"Speed":              100,
							"date.Birthday":      1.660145023e+09,
							"edition_set_max":    3,
							"edition_set_number": 2,
							"uuid":               603,
						},
						"tags": map[string]interface{}{
							"NeoMotorCycleTag": "Tag1",
							"external_url":     "https://find.xyz/collection/user1/dandy/603",
						},
						"thumbnail":      "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						"totalInEdition": 3,
						"type":           "A.179b6b1cb6755e31.Dandy.NFT",
					},
					"nftId":         603,
					"nftIdentifier": "A.179b6b1cb6755e31.Dandy.NFT",
					"saleType":      "active_ongoing",
					"seller":        "0x120e725050340cab",
					"sellerName":    "user1",
				}},
			}}),
		)

		otu.sendDandy("user1", "user2", ids[0]).
			sendFT("user1", "user2", "Flow", price)
		otu.delistAllNFT("user1")
	})

}
