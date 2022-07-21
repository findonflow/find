package test_main

import (
	"strings"
	"testing"

	"github.com/hexops/autogold"
	"github.com/sanity-io/litter"
)

func TestNFTDetailScript(t *testing.T) {

	price := 10.00

	t.Run("Should be able to get nft details of item with script", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("Sale").
			listNFTForSale("user1", ids[1], price)

		actual := otu.O.ScriptFromFile("getNFTDetails").
			Args(otu.O.Arguments().
				String("user1").
				String("Dandy").
				UInt64(ids[1]).
				StringArray()).
			RunReturnsJsonString()

		actual = otu.replaceID(actual, ids)

		autogold.Equal(t, actual)
	})

	t.Run("Should be able to get nft details of item if listed in rule with no listing type", func(t *testing.T) {
		otu := NewOverflowTest(t)
		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry()
		otu.O.TransactionFromFile("adminSetSellDandyRules").
			SignProposeAndPayAs("find").
			Args(otu.O.Arguments().
				Account("account")).
			Test(otu.T).
			AssertSuccess()
		otu.listNFTForSale("user1", ids[1], price)

		actual := otu.O.ScriptFromFile("getNFTDetails").
			Args(otu.O.Arguments().
				String("user1").
				String("Dandy").
				UInt64(ids[1]).
				StringArray()).
			RunReturnsJsonString()

		actual = otu.replaceID(actual, ids)

		autogold.Equal(t, actual)
	})

	t.Run("Should be able to get nft details of item with views", func(t *testing.T) {
		otu := NewOverflowTest(t)
		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setFlowDandyMarketOption("Sale").
			listNFTForSale("user1", ids[1], price)

		actual := otu.O.ScriptFromFile("getNFTDetails").
			Args(otu.O.Arguments().
				String("user1").
				String("Dandy").
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

		actual = otu.replaceID(actual, ids)

		autogold.Equal(t, actual)
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

		actual := otu.O.ScriptFromFile("getNFTDetails").
			Args(otu.O.Arguments().
				String("user1").
				String("Dandy").
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
		otu := NewOverflowTest(t)

		otu.setupFIND().
			createUser(10000.0, "user1").
			registerUser("user1").
			buyForge("user1").
			createUser(100.0, "user2").
			createUser(100.0, "user3").
			registerUser("user2").
			registerUser("user3")
		otu.setUUID(300)
		ids := otu.mintThreeExampleDandies()
		otu.registerFtInRegistry().
			registerUserWithNameAndForge("user1", "neomotorcycle").
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

		actual1 := otu.O.ScriptFromFile("getNFTDetails").
			Args(otu.O.Arguments().
				String("user1").
				String("Dandy").
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

		actual2 := otu.O.ScriptFromFile("getNFTDetails").
			Args(otu.O.Arguments().
				String("user1").
				String("Dandy").
				UInt64(dandyIds[1]).
				StringArray()).
			RunReturnsJsonString()
		actual2 = otu.replaceID(actual2, dandyIds)

		for _, item := range viewList {
			actual2 = strings.Replace(actual2, item, "checked", -1)
		}

		otu.AutoGold("actual2", actual2)

		actual3 := otu.O.ScriptFromFile("getNFTDetails").
			Args(otu.O.Arguments().
				String("user1").
				String("Dandy").
				UInt64(dandyIds[2]).
				StringArray()).
			RunReturnsJsonString()
		actual3 = otu.replaceID(actual3, dandyIds)

		for _, item := range viewList {
			actual3 = strings.Replace(actual3, item, "checked", -1)
		}
		otu.AutoGold("actual3", actual3)

		actual4 := otu.O.ScriptFromFile("getNFTDetails").
			Args(otu.O.Arguments().
				String("user1").
				String("Dandy").
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
			listNFTForSoftAuction("user1", ids[1], price).
			directOfferMarketEscrowed("user2", "user1", ids[0], price).
			alterMarketOption("Sale", "stop").
			alterMarketOption("AuctionSoft", "stop").
			alterMarketOption("AuctionEscrow", "stop").
			alterMarketOption("DirectOfferSoft", "stop").
			alterMarketOption("DirectOfferEscrow", "stop")

		actual := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		actual = otu.replaceID(actual, ids)

		autogold.Equal(t, actual)
	})

	t.Run("Should return all blocked NFTs by type", func(t *testing.T) {
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
			listNFTForSoftAuction("user1", ids[1], price).
			blockDandy("testBlockItem")

		actual := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		actual = otu.replaceID(actual, ids)
		autogold.Equal(t, actual)
	})

	t.Run("Should return all blocked NFTs if blocked by find.", func(t *testing.T) {
		otu := NewOverflowTest(t)

		otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setProfile("user1").
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
		otu := NewOverflowTest(t)

		otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
			setProfile("user1").
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
