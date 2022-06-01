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

	t.Run("Should be able to get media with thumbnail", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFtInRegistry().
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

		actual := otu.O.ScriptFromFile("getNFTDetails").
			Args(otu.O.Arguments().
				String("user1").
				String("Dandy").
				UInt64(dandyIds[4]).
				StringArray()).
			RunReturnsJsonString()

		autogold.Equal(t, actual)
	})

}
