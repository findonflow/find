package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

// TODO: we need to fix this test so that we can also test using dapper market
func TestNFTDetailScript(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	price := 10.00

	ot.Run(t, "Should be able to get nft details of item with script", func(t *testing.T) {
		otu.listNFTForSale("user1", dandyIds[1], price)

		actual, err := otu.O.Script("getNFTDetailsNFTCatalog",
			WithArg("user", "user1"),
			WithArg("project", dandyNFTType(otu)),
			WithArg("id", dandyIds[1]),
			WithArg("views", `[]`),
		).
			GetAsJson()
		if err != nil {
			panic(err)
		}

		actual = otu.replaceID(actual, dandyIds)

		autogold.Equal(t, actual)
	})
	/*

		t.Run("Should be able to get nft details of item with views", func(t *testing.T) {

			otu.listNFTForSale("user1", ids[1], price)

			viewList := []string{
				otu.identifier("FindViews", "Nounce"),
				otu.identifier("MetadataViews", "Traits"),
				otu.identifier("MetadataViews", "Royalties"),
				otu.identifier("MetadataViews", "ExternalURL"),
				otu.identifier("FindViews", "CreativeWork"),
			}

			actual, err := otu.O.Script("getNFTDetailsNFTCatalog",
				WithArg("user", "user1"),
				WithArg("project", dandyNFTType(otu)),
				WithArg("id", ids[1]),
				WithArg("views", viewList),
			).
				GetAsJson()

			if err != nil {
				panic(err)
			}

			actual = otu.replaceID(actual, ids)

			autogold.Equal(t, actual)
		})

		t.Run("Should be able to get nft details of item if listed in rule with no listing type", func(t *testing.T) {

			otu.O.Tx("adminSetSellDandyRules",
				WithSigner("find-admin"),
				WithArg("tenant", "find"),
			).
				AssertSuccess(t)

			otu.listNFTForSale("user1", ids[1], price)

			actual, err := otu.O.Script("getNFTDetailsNFTCatalog",
				WithArg("user", "user1"),
				WithArg("project", dandyNFTType(otu)),
				WithArg("id", ids[1]),
				WithArg("views", `[]`),
			).
				GetAsJson()

			if err != nil {
				panic(err)
			}

			actual = otu.replaceID(actual, ids)

			autogold.Equal(t, actual)

			// Remove these general rule for later testing
			otu.O.Tx("removeMarketOption",
				WithSigner("find"),
				WithArg("saleItemName", "FUSDDandy"),
			).
				AssertSuccess(t)

			otu.O.Tx("removeMarketOption",
				WithSigner("find"),
				WithArg("saleItemName", "FlowDandy"),
			).
				AssertSuccess(t)

		})

		t.Run("Should be able to get all listings of a person by a script", func(t *testing.T) {
			otu.setUUID(800)
			ids := otu.mintThreeExampleDandies()
			otu.setProfile("user1").
				listNFTForSale("user1", ids[1], price).
				listNFTForEscrowedAuction("user1", ids[1], price)

			otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

			otu.O.Script("getFindMarket",
				WithArg("user", "user1"),
			).AssertWithPointerWant(t, "/itemsForSale/FindMarketAuctionEscrow/items/0",
				autogold.Want("get all listings", map[string]interface{}{
					"amount": 10, "auction": map[string]interface{}{
						"currentPrice": 10, "extentionOnLateBid": 60, "minimumBidIncrement": 1,
						"reservePrice": 15,
						"startPrice":   10,
						"timestamp":    1,
					},
					"ftAlias":               "Flow",
					"ftTypeIdentifier":      "A.0ae53cb6e3f42a79.FlowToken.Vault",
					"listingId":             803,
					"listingStatus":         "active",
					"listingTypeIdentifier": "A.179b6b1cb6755e31.FindMarketAuctionEscrow.SaleItem",
					"listingValidUntil":     101,
					"nft": map[string]interface{}{
						"collectionDescription": "Neo Collectibles FIND",
						"collectionName":        "user1",
						"editionNumber":         2,
						"id":                    803,
						"name":                  "Neo Motorcycle 2 of 3",
						"scalars": map[string]interface{}{
							"Speed":              100,
							"date.Birthday":      1.660145023e+09,
							"edition_set_max":    3,
							"edition_set_number": 2,
							"uuid":               803,
						},
						"tags": map[string]interface{}{
							"NeoMotorCycleTag": "Tag1",
							"external_url":     "https://find.xyz/collection/user1/dandy/803",
						},
						"thumbnail":      "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						"totalInEdition": 3,
						"type":           "A.179b6b1cb6755e31.Dandy.NFT",
					},
					"nftId":         803,
					"nftIdentifier": "A.179b6b1cb6755e31.Dandy.NFT",
					"saleType":      "active_listed",
					"seller":        "0xf669cb8d41ce0c74",
					"sellerName":    "user1",
				}),
			)

		})

		t.Run("Should be able to get storefront listings of an NFT by a script", func(t *testing.T) {
			otu.setUUID(1200)
			ids := otu.mintThreeExampleDandies()
			otu.listNFTForSale("user1", ids[1], price)

			otu.O.Tx("devListStorefront",
				WithSigner("user1"),
				WithArg("saleItemID", ids[1]),
				WithArg("saleItemPrice", 10.0),
			).
				AssertSuccess(t)

			actual, err := otu.O.Script("getNFTDetailsNFTCatalogCommunity",
				WithArg("user", "user1"),
				WithArg("project", dandyNFTType(otu)),
				WithArg("id", ids[1]),
				WithArg("views", `[]`),
			).
				GetAsInterface()

			if err != nil {
				panic(err)
			}

			autogold.Equal(t, litter.Sdump(actual))
		})

		t.Run("Should be able to get media with thumbnail", func(t *testing.T) {
			otu.setUUID(1600)
			ids := otu.mintThreeExampleDandies()
			otu.registerUserWithNameAndForge("user1", "neomotorcycle").
				registerUserWithNameAndForge("user1", "xtingles").
				registerUserWithNameAndForge("user1", "flovatar").
				registerUserWithNameAndForge("user1", "ufcstrike").
				registerUserWithNameAndForge("user1", "jambb").
				registerUserWithNameAndForge("user1", "bitku").
				registerUserWithNameAndForge("user1", "goatedgoats").
				registerUserWithNameAndForge("user1", "klktn").
				listNFTForSale("user1", ids[1], price)

			dandyIds := otu.O.Tx("devMintDandyTO",
				WithSigner("user1"),
				WithArg("name", "user1"),
				WithArg("maxEdition", 1),
				WithArg("artist", "Neo"),
				WithArg("nftName", "Neo Motorcycle"),
				WithArg("nftDescription", `Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK`),
				WithArg("nftUrl", "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"),
				WithArg("rarity", "rare"),
				WithArg("rarityNum", 50.0),
				WithArg("to", "user1"),
			).
				AssertSuccess(t).
				GetIdsFromEvent(otu.identifier("Dandy", "Deposit"), "id")

			nftDetail := otu.O.ScriptFN(
				WithArg("user", "user1"),
				WithArg("project", dandyNFTType(otu)),
				WithArg("id", dandyIds[0]),
				WithArg("views", `[]`),
			)

			actual1, err := nftDetail("getNFTDetailsNFTCatalog",
				WithArg("id", dandyIds[0]),
			).
				GetAsJson()

			if err != nil {
				panic(err)
			}

			actual1 = otu.replaceID(actual1, dandyIds)

			viewList := []string{
				otu.identifier("FindViews", "Nounce"),
				otu.identifier("MetadataViews", "NFTCollectionData"),
				otu.identifier("MetadataViews", "Royalties"),
				otu.identifier("MetadataViews", "ExternalURL"),
				otu.identifier("FindViews", "CreativeWork"),
				otu.identifier("MetadataViews", "Traits"),
				otu.identifier("MetadataViews", "Rarity"),
			}

			for _, item := range viewList {
				actual1 = strings.Replace(actual1, item, "checked", -1)
			}

			otu.AutoGold("actual1", actual1)

			actual2, err := nftDetail("getNFTDetailsNFTCatalog",
				WithArg("id", dandyIds[1]),
			).
				GetAsJson()

			if err != nil {
				panic(err)
			}

			actual2 = otu.replaceID(actual2, dandyIds)

			for _, item := range viewList {
				actual2 = strings.Replace(actual2, item, "checked", -1)
			}

			otu.AutoGold("actual2", actual2)

			actual3, err := nftDetail("getNFTDetailsNFTCatalog",
				WithArg("id", dandyIds[2]),
			).
				GetAsJson()

			if err != nil {
				panic(err)
			}

			actual3 = otu.replaceID(actual3, dandyIds)

			for _, item := range viewList {
				actual3 = strings.Replace(actual3, item, "checked", -1)
			}
			otu.AutoGold("actual3", actual3)

			actual4, err := nftDetail("getNFTDetailsNFTCatalog",
				WithArg("id", dandyIds[3]),
			).
				GetAsJson()

			if err != nil {
				panic(err)
			}

			actual4 = otu.replaceID(actual4, dandyIds)

			for _, item := range viewList {
				actual4 = strings.Replace(actual4, item, "checked", -1)
			}

			otu.AutoGold("actual", actual4)
		})

		t.Run("Should not be fetching NFTInfo when item is stopped", func(t *testing.T) {
			otu.setUUID(2000)
			ids := otu.mintThreeExampleDandies()
			otu.setProfile("user1").
				listNFTForSale("user1", ids[1], price).
				listNFTForEscrowedAuction("user1", ids[1], price).
				directOfferMarketEscrowed("user2", "user1", ids[0], price).
				alterMarketOption("stop")

			otu.O.Script("getFindMarket",
				WithArg("user", "user1"),
			).Print().AssertWithPointerWant(t, "/itemsForSale/FindMarketAuctionEscrow/items/0",
				autogold.Want("Should not be fetching NFTInfo if stopped", map[string]interface{}{
					"amount": 10, "auction": map[string]interface{}{
						"currentPrice": 10, "extentionOnLateBid": 60, "minimumBidIncrement": 1,
						"reservePrice": 15,
						"startPrice":   10,
						"timestamp":    1,
					},
					"ftAlias":               "Flow",
					"ftTypeIdentifier":      "A.0ae53cb6e3f42a79.FlowToken.Vault",
					"listingId":             2003,
					"listingStatus":         "stopped",
					"listingTypeIdentifier": "A.179b6b1cb6755e31.FindMarketAuctionEscrow.SaleItem",
					"listingValidUntil":     101,
					"nftId":                 2003,
					"nftIdentifier":         "A.179b6b1cb6755e31.Dandy.NFT",
					"saleType":              "active_listed",
					"seller":                "0xf669cb8d41ce0c74",
					"sellerName":            "user1",
				}),
			)

		})

		t.Run("Should return all blocked NFTs by type", func(t *testing.T) {
			otu.alterMarketOption("enable")
			otu.setUUID(2400)
			ids := otu.mintThreeExampleDandies()
			otu.setProfile("user1").
				listNFTForSale("user1", ids[1], price).
				listNFTForEscrowedAuction("user1", ids[1], price).
				directOfferMarketEscrowed("user2", "user1", ids[0], price).
				alterMarketOption("stop")

			actual, err := otu.O.Script("getMarketBlockedNFT").
				GetAsJson()

			if err != nil {
				panic(err)
			}

			actual = otu.replaceID(actual, ids)

			autogold.Equal(t, actual)
		})

		t.Run("Should not fetch NFTInfo if blocked by find", func(t *testing.T) {
			otu.alterMarketOption("enable")
			otu.setUUID(2800)
			ids := otu.mintThreeExampleDandies()
			otu.setProfile("user1").
				listNFTForSale("user1", ids[1], price).
				listNFTForEscrowedAuction("user1", ids[1], price).
				blockDandy("devBlockItem")

			otu.O.Script("getFindMarket",
				WithArg("user", "user1"),
			).AssertWithPointerError(t, "/itemsForSale/FindMarketAuctionEscrow/items/0/nft", "")

		})

		t.Run("Should return all blocked NFTs if blocked by find.", func(t *testing.T) {
			otu.setUUID(3200)
			otu.mintThreeExampleDandies()
			otu.setProfile("user1").
				blockDandy("devBlockItem")

			actual, err := otu.O.Script("getMarketBlockedNFT").
				GetAsJson()

			if err != nil {
				panic(err)
			}

			autogold.Equal(t, actual)
		})

		t.Run("Should return all blocked NFTs if blocked by find by listing type.", func(t *testing.T) {
			otu.setUUID(3600)
			otu.mintThreeExampleDandies()
			otu.setProfile("user1").
				blockDandy("devBlockItemByListingType")

			actual, err := otu.O.Script("getMarketBlockedNFT").
				GetAsJson()

			if err != nil {
				panic(err)
			}

			autogold.Equal(t, actual)
		})

		typ := dandyNFTType(otu)

		t.Run("Should be able to get collection display by collection Identifier", func(t *testing.T) {
			otu.O.Script("getCatalogCollectionDisplay",
				WithArg("collectionIdentifier", typ),
				WithArg("type", OptionalString(typ)),
			).
				AssertWithPointerWant(t, "/collectionDisplay/name", autogold.Want("test", "user1"))

		})

		t.Run("Should be able to get collection display by collection name", func(t *testing.T) {
			otu.O.Script("getCatalogCollectionDisplay",
				WithArg("collectionIdentifier", "user1"),
				WithArg("type", OptionalString(typ)),
			).
				AssertWithPointerWant(t, "/collectionDisplay/name", autogold.Want("test", "user1"))
		})
	*/
}
