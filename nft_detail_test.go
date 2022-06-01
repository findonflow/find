package test_main

import (
	"testing"

	"github.com/hexops/autogold"
)

func TestNFTDetailScript(t *testing.T) {

	price := 10.00

	t.Run("Should be able to get nft details of item", func(t *testing.T) {
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
			RunReturnsJsonString()

		autogold.Equal(t, actual)
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
