package test_main

import (
	"testing"

	"github.com/hexops/autogold"
)

func TestCollectionScripts(t *testing.T) {

	t.Run("Should be able to mint Dandy and then get it by script", func(t *testing.T) {
		otu := NewOverflowTest(t)

		otu.setupFIND().
			setupDandy("user1").
			registerDandyInNFTRegistry()

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

		autogold.Equal(t, result)
	})

}
