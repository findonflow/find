package test_main

import (
	"strings"
	"testing"

	"github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/sanity-io/litter"
)

func TestNFTDetailScript(t *testing.T) {

	price := 10.00

	otu := NewOverflowTest(t)

	otu.setupFIND().
		createUser(1000.0, "user1").
		registerUser("user1").
		buyForge("user1").
		createUser(1000.0, "user2").
		createUser(1000.0, "user3").
		registerUser("user2").
		registerUser("user3")
	otu.setUUID(300)
	ids := otu.mintThreeExampleDandies()
	otu.registerFtInRegistry().
		setFlowDandyMarketOption("Sale")

	t.Run("Should be able to get nft details of item with script", func(t *testing.T) {

		otu.listNFTForSale("user1", ids[1], price)

		actual := otu.O.ScriptFromFile("getNFTDetailsNFTCatalog").
			Args(otu.O.Arguments().
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[1]).
				StringArray()).
			RunReturnsJsonString()

		actual = otu.replaceID(actual, ids)

		autogold.Equal(t, actual)
	})

	t.Run("Should be able to get nft details of item if listed in rule with no listing type", func(t *testing.T) {

		otu.O.TransactionFromFile("adminSetSellDandyRules").
			SignProposeAndPayAs("find").
			Args(otu.O.Arguments().
				Account("account")).
			Test(otu.T).
			AssertSuccess()
		otu.listNFTForSale("user1", ids[1], price)

		actual := otu.O.ScriptFromFile("getNFTDetailsNFTCatalog").
			Args(otu.O.Arguments().
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[1]).
				StringArray()).
			RunReturnsJsonString()

		actual = otu.replaceID(actual, ids)

		autogold.Equal(t, actual)

	})

	t.Run("Should be able to get nft details of item with views", func(t *testing.T) {

		otu.listNFTForSale("user1", ids[1], price)

		actual := otu.O.ScriptFromFile("getNFTDetailsNFTCatalog").
			Args(otu.O.Arguments().
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[1]).
				StringArray(
					"A.f8d6e0586b0a20c7.FindViews.Nounce",
					"A.f8d6e0586b0a20c7.MetadataViews.Traits",
					"A.f8d6e0586b0a20c7.MetadataViews.Royalties",
					"A.f8d6e0586b0a20c7.MetadataViews.ExternalURL",
					"A.f8d6e0586b0a20c7.FindViews.CreativeWork",
				)).
			RunReturnsJsonString()

		actual = otu.replaceID(actual, ids)

		autogold.Equal(t, actual)
	})

	t.Run("Should be able to get all listings of a person by a script", func(t *testing.T) {
		otu.setUUID(500)
		ids := otu.mintThreeExampleDandies()
		otu.setProfile("user1").
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

		otu.O.Script("getStatus",
			overflow.WithArg("user", "user1"),
		).AssertWithPointerWant(t, "/FINDReport/itemsForSale/FindMarketAuctionEscrow/items/0",
			autogold.Want("get all listings", map[string]interface{}{
				"amount": 10, "auction": map[string]interface{}{
					"currentPrice": 10, "extentionOnLateBid": 60, "minimumBidIncrement": 1,
					"reservePrice": 15,
					"startPrice":   10,
					"timestamp":    1,
				},
				"ftAlias":               "Flow",
				"ftTypeIdentifier":      "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"listingId":             503,
				"listingStatus":         "active",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem",
				"listingValidUntil":     11,
				"nft": map[string]interface{}{
					"collectionDescription": "Neo Collectibles FIND",
					"collectionName":        "user1",
					"editionNumber":         2,
					"id":                    503,
					"name":                  "Neo Motorcycle 2 of 3",
					"scalars": map[string]interface{}{
						"Speed":              100,
						"edition_set_max":    3,
						"edition_set_number": 2,
					},
					"tags":           map[string]interface{}{"NeoMotorCycleTag": "Tag1"},
					"thumbnail":      "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"totalInEdition": 3,
					"type":           "A.f8d6e0586b0a20c7.Dandy.NFT",
				},
				"nftId":         503,
				"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleType":      "active_listed",
				"seller":        "0x179b6b1cb6755e31",
				"sellerName":    "user1",
			}),
		)

	})

	t.Run("Should be able to get storefront listings of an NFT by a script", func(t *testing.T) {
		otu.setUUID(700)
		ids := otu.mintThreeExampleDandies()
		otu.setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSale("user1", ids[1], price)

		otu.O.TransactionFromFile("testListStorefront").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().UInt64(ids[1]).UFix64(10.0)).
			Test(otu.T).AssertSuccess()

		actual := otu.O.ScriptFromFile("getNFTDetailsNFTCatalog").
			Args(otu.O.Arguments().
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[1]).
				StringArray()).
			RunReturnsInterface()

			/*
				viewList := []string{
					"A.f8d6e0586b0a20c7.FindViews.Nounce",
					"A.f8d6e0586b0a20c7.MetadataViews.NFTCollectionData",
					"A.f8d6e0586b0a20c7.MetadataViews.Royalties",
					"A.f8d6e0586b0a20c7.MetadataViews.ExternalURL",
					"A.f8d6e0586b0a20c7.FindViews.CreativeWork",
					"A.f8d6e0586b0a20c7.MetadataViews.Traits",
				}
				for _, item := range viewList {
					actual = strings.Replace(actual, item, "checked", -1)
				}
				actual = otu.replaceID(actual, ids)

			*/
		autogold.Equal(t, litter.Sdump(actual))
	})

	t.Run("Should be able to get media with thumbnail", func(t *testing.T) {
		otu.setUUID(900)
		ids := otu.mintThreeExampleDandies()
		otu.registerUserWithNameAndForge("user1", "neomotorcycle").
			registerUserWithNameAndForge("user1", "xtingles").
			registerUserWithNameAndForge("user1", "flovatar").
			registerUserWithNameAndForge("user1", "ufcstrike").
			registerUserWithNameAndForge("user1", "jambb").
			registerUserWithNameAndForge("user1", "bitku").
			registerUserWithNameAndForge("user1", "goatedgoats").
			registerUserWithNameAndForge("user1", "klktn").
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSale("user1", ids[1], price)

		result := otu.O.TransactionFromFile("testMintDandyTO").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("user1").
				UInt64(1).
				String("Neo").
				String("Neo Motorcycle").
				String(`Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK`).
				String("https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp").
				String("rare").
				UFix64(50.0).
				Account("user1")).
			Test(otu.T).AssertSuccess()

		dandyIds := []uint64{}
		for _, event := range result.Events {
			if event.Name == "A.f8d6e0586b0a20c7.Dandy.Deposit" {
				dandyIds = append(dandyIds, event.GetFieldAsUInt64("id"))
			}
		}

		actual1 := otu.O.ScriptFromFile("getNFTDetailsNFTCatalog").
			Args(otu.O.Arguments().
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(dandyIds[0]).
				StringArray()).
			RunReturnsJsonString()
		actual1 = otu.replaceID(actual1, dandyIds)

		viewList := []string{
			"A.f8d6e0586b0a20c7.FindViews.Nounce",
			"A.f8d6e0586b0a20c7.MetadataViews.NFTCollectionData",
			"A.f8d6e0586b0a20c7.MetadataViews.Royalties",
			"A.f8d6e0586b0a20c7.MetadataViews.ExternalURL",
			"A.f8d6e0586b0a20c7.FindViews.CreativeWork",
			"A.f8d6e0586b0a20c7.MetadataViews.Traits",
			"A.f8d6e0586b0a20c7.MetadataViews.Rarity",
		}
		for _, item := range viewList {
			actual1 = strings.Replace(actual1, item, "checked", -1)
		}

		otu.AutoGold("actual1", actual1)

		actual2 := otu.O.ScriptFromFile("getNFTDetailsNFTCatalog").
			Args(otu.O.Arguments().
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(dandyIds[1]).
				StringArray()).
			RunReturnsJsonString()
		actual2 = otu.replaceID(actual2, dandyIds)

		for _, item := range viewList {
			actual2 = strings.Replace(actual2, item, "checked", -1)
		}

		otu.AutoGold("actual2", actual2)

		actual3 := otu.O.ScriptFromFile("getNFTDetailsNFTCatalog").
			Args(otu.O.Arguments().
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(dandyIds[2]).
				StringArray()).
			RunReturnsJsonString()
		actual3 = otu.replaceID(actual3, dandyIds)

		for _, item := range viewList {
			actual3 = strings.Replace(actual3, item, "checked", -1)
		}
		otu.AutoGold("actual3", actual3)

		actual4 := otu.O.ScriptFromFile("getNFTDetailsNFTCatalog").
			Args(otu.O.Arguments().
				String("user1").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(dandyIds[3]).
				StringArray()).
			RunReturnsJsonString()
		actual4 = otu.replaceID(actual4, dandyIds)

		for _, item := range viewList {
			actual4 = strings.Replace(actual4, item, "checked", -1)
		}

		otu.AutoGold("actual", actual4)
	})

	t.Run("Should not be fetching NFTInfo when item is stopped", func(t *testing.T) {
		otu.setUUID(1100)
		ids := otu.mintThreeExampleDandies()
		otu.setProfile("user1").
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSale("user1", ids[1], price).
			directOfferMarketSoft("user2", "user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			listNFTForSoftAuction("user1", ids[1], price).
			directOfferMarketEscrowed("user2", "user1", ids[0], price).
			alterMarketOption("Sale", "stop").
			alterMarketOption("AuctionSoft", "stop").
			alterMarketOption("AuctionEscrow", "stop").
			alterMarketOption("DirectOfferSoft", "stop").
			alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.Script("getStatus",
			overflow.WithArg("user", "user1"),
		).AssertWithPointerWant(t, "/FINDReport/itemsForSale/FindMarketAuctionSoft/items/0",
			autogold.Want("Should not be fetching NFTInfo if stopped", map[string]interface{}{
				"amount": 10, "auction": map[string]interface{}{
					"currentPrice": 10, "extentionOnLateBid": 60, "minimumBidIncrement": 1,
					"reservePrice": 15,
					"startPrice":   10,
					"timestamp":    1,
				},
				"ftAlias":               "Flow",
				"ftTypeIdentifier":      "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"listingId":             1103,
				"listingStatus":         "stopped",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionSoft.SaleItem",
				"listingValidUntil":     11,
				"nftId":                 1103,
				"nftIdentifier":         "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleType":              "active_listed",
				"seller":                "0x179b6b1cb6755e31",
				"sellerName":            "user1",
			}),
		)

	})

	t.Run("Should return all blocked NFTs by type", func(t *testing.T) {
		otu.setUUID(1300)
		ids := otu.mintThreeExampleDandies()
		otu.setProfile("user1").
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSale("user1", ids[1], price).
			directOfferMarketSoft("user2", "user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			listNFTForSoftAuction("user1", ids[1], price).
			directOfferMarketEscrowed("user2", "user1", ids[0], price).
			alterMarketOption("Sale", "stop").
			alterMarketOption("AuctionSoft", "stop").
			alterMarketOption("AuctionEscrow", "stop")

		actual := otu.O.ScriptFromFile("getMarketBlockedNFT").RunReturnsJsonString()
		actual = otu.replaceID(actual, ids)

		autogold.Equal(t, actual)
	})

	t.Run("Should not fetch NFTInfo if blocked by find", func(t *testing.T) {
		otu.setUUID(1500)
		ids := otu.mintThreeExampleDandies()
		otu.setProfile("user1").
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			listNFTForSale("user1", ids[1], price).
			directOfferMarketSoft("user2", "user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			listNFTForSoftAuction("user1", ids[1], price).
			blockDandy("testBlockItem")

		otu.O.Script("getStatus",
			overflow.WithArg("user", "user1"),
		).AssertWithPointerError(t, "/FINDReport/itemsForSale/FindMarketAuctionEscrow/items/0/nft", "")

	})

	t.Run("Should return all blocked NFTs if blocked by find.", func(t *testing.T) {
		otu.setUUID(1700)
		otu.mintThreeExampleDandies()
		otu.setProfile("user1").
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			blockDandy("testBlockItem")

		actual := otu.O.ScriptFromFile("getMarketBlockedNFT").RunReturnsJsonString()

		autogold.Equal(t, actual)
	})

	t.Run("Should return all blocked NFTs if blocked by find by listing type.", func(t *testing.T) {
		otu.setUUID(1900)
		otu.mintThreeExampleDandies()
		otu.setProfile("user1").
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow").
			setFlowDandyMarketOption("AuctionSoft").
			blockDandy("testBlockItemByListingType")

		actual := otu.O.ScriptFromFile("getMarketBlockedNFT").RunReturnsJsonString()

		autogold.Equal(t, actual)
	})
}
