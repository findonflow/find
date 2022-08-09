package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestCollectionScripts(t *testing.T) {

	t.Run("Should be able to mint Dandy and then get it by script", func(t *testing.T) {
		otu := NewOverflowTest(t)

		otu.setupFIND().
			createUser(10000.0, "user1").
			registerUser("user1").
			buyForge("user1").
			registerUserWithNameAndForge("user1", "neomotorcycle").
			registerUserWithNameAndForge("user1", "xtingles").
			registerUserWithNameAndForge("user1", "flovatar").
			registerUserWithNameAndForge("user1", "ufcstrike").
			registerUserWithNameAndForge("user1", "jambb").
			registerUserWithNameAndForge("user1", "bitku").
			registerUserWithNameAndForge("user1", "goatedgoats").
			registerUserWithNameAndForge("user1", "klktn")

		otu.setUUID(500)

		otu.O.TransactionFromFile("testMintDandyTO").
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
			Test(t).
			AssertSuccess()

		otu.registerDandyInNFTRegistry()

		result, err := otu.O.Script("getFactoryCollectionsNFTCatalog",
			overflow.WithArg("user", "user1"),
			overflow.WithArg("maxItems", 100),
			overflow.WithArg("collections", "[]"),
		).GetWithPointer("/A.f8d6e0586b0a20c7.Dandy.NFT/items")

		if err != nil {
			panic(err)
		}

		autogold.Equal(t, result)

	})

}
