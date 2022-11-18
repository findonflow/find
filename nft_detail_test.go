package test_main

import (
	"strings"
	"testing"

	. "github.com/bjartek/overflow"
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
	otu.setUUID(400)
	ids := otu.mintThreeExampleDandies()
	otu.registerFtInRegistry().
		setFlowDandyMarketOption("Sale")

	t.Run("Should be able to get nft details of item with script", func(t *testing.T) {

		otu.listNFTForSale("user1", ids[1], price)

		actual, err := otu.O.Script("getNFTDetailsNFTCatalog",
			WithArg("user", "user1"),
			WithArg("project", "A.f8d6e0586b0a20c7.Dandy.NFT"),
			WithArg("id", ids[1]),
			WithArg("views", `[]`),
		).
			GetAsJson()

		if err != nil {
			panic(err)
		}

		actual = otu.replaceID(actual, ids)

		autogold.Equal(t, actual)
	})

	t.Run("Should be able to get nft details of item with views", func(t *testing.T) {

		otu.listNFTForSale("user1", ids[1], price)

		actual, err := otu.O.Script("getNFTDetailsNFTCatalog",
			WithArg("user", "user1"),
			WithArg("project", "A.f8d6e0586b0a20c7.Dandy.NFT"),
			WithArg("id", ids[1]),
			WithArg("views", `[
			"A.f8d6e0586b0a20c7.FindViews.Nounce",
			"A.f8d6e0586b0a20c7.MetadataViews.Traits",
			"A.f8d6e0586b0a20c7.MetadataViews.Royalties",
			"A.f8d6e0586b0a20c7.MetadataViews.ExternalURL",
			"A.f8d6e0586b0a20c7.FindViews.CreativeWork",]`),
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
			WithSigner("find"),
			WithArg("tenant", "account"),
		).
			AssertSuccess(t)

		otu.listNFTForSale("user1", ids[1], price)

		actual, err := otu.O.Script("getNFTDetailsNFTCatalog",
			WithArg("user", "user1"),
			WithArg("project", "A.f8d6e0586b0a20c7.Dandy.NFT"),
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
			WithSigner("account"),
			WithArg("saleItemName", "FUSDDandy"),
		).
			AssertSuccess(t)

		otu.O.Tx("removeMarketOption",
			WithSigner("account"),
			WithArg("saleItemName", "FlowDandy"),
		).
			AssertSuccess(t)

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
			WithArg("user", "user1"),
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
				"listingValidUntil":     101,
				"nft": map[string]interface{}{
					"collectionDescription": "Neo Collectibles FIND",
					"collectionName":        "user1",
					"editionNumber":         2,
					"id":                    503,
					"name":                  "Neo Motorcycle 2 of 3",
					"scalars": map[string]interface{}{
						"Speed":              100,
						"date.Birthday":      1.660145023e+09,
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

		otu.O.Tx("devListStorefront",
			WithSigner("user1"),
			WithArg("saleItemID", ids[1]),
			WithArg("saleItemPrice", 10.0),
		).
			AssertSuccess(t)

		actual, err := otu.O.Script("getNFTDetailsNFTCatalog",
			WithArg("user", "user1"),
			WithArg("project", "A.f8d6e0586b0a20c7.Dandy.NFT"),
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
			GetIdsFromEvent("A.f8d6e0586b0a20c7.Dandy.Deposit", "id")

		nftDetail := otu.O.ScriptFN(
			WithArg("user", "user1"),
			WithArg("project", "A.f8d6e0586b0a20c7.Dandy.NFT"),
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
			WithArg("user", "user1"),
		).Print().AssertWithPointerWant(t, "/FINDReport/itemsForSale/FindMarketAuctionSoft/items/0",
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
				"listingValidUntil":     101,
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

		actual, err := otu.O.Script("getMarketBlockedNFT").
			GetAsJson()

		if err != nil {
			panic(err)
		}

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
			blockDandy("devBlockItem")

		otu.O.Script("getStatus",
			WithArg("user", "user1"),
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
			blockDandy("devBlockItem")

		actual, err := otu.O.Script("getMarketBlockedNFT").
			GetAsJson()

		if err != nil {
			panic(err)
		}

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
			blockDandy("devBlockItemByListingType")

		actual, err := otu.O.Script("getMarketBlockedNFT").
			GetAsJson()

		if err != nil {
			panic(err)
		}

		autogold.Equal(t, actual)
	})
}
