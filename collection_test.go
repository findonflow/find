package test_main

import (
	"testing"

	"github.com/hexops/autogold"
)

func TestCollectionScripts(t *testing.T) {

	t.Run("Should be able to mint Dandy and then get it by script", func(t *testing.T) {
		otu := NewOverflowTest(t)

		otu.setupFIND().
			createUser(10000.0, "user1").
			registerUser("user1").
			buyForge("user1").
			registerDandyInNFTRegistry().
			registerUserWithNameAndForge("user1", "neomotorcycle").
			registerUserWithNameAndForge("user1", "xtingles").
			registerUserWithNameAndForge("user1", "flovatar").
			registerUserWithNameAndForge("user1", "ufcstrike").
			registerUserWithNameAndForge("user1", "jambb").
			registerUserWithNameAndForge("user1", "bitku").
			registerUserWithNameAndForge("user1", "goatedgoats").
			registerUserWithNameAndForge("user1", "klktn")

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
			RunPrintEventsFull()

		result := otu.O.ScriptFromFile("getCollections").
			Args(otu.O.Arguments().String("user1")).
			RunReturnsJsonString()
		// fmt.Println("@@@@@@@@@@@@@@@@@@@@@@@@@@@")
		// fmt.Println(err)
		// fmt.Println("@@@@@@@@@@@@@@@@@@@@@@@@@@@")
		autogold.Equal(t, result)

	})

}
