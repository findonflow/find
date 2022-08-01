package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestFindForge(t *testing.T) {

	t.Run("Should be able to mint Example NFT and then get it by script", func(t *testing.T) {
		otu := NewOverflowTest(t)

		otu.setupFIND().
			createUser(10000.0, "user1").
			registerUser("user1").
			buyForge("user1")

		otu.O.TransactionFromFile("adminSetNFTInfo_ExampleNFT").
			SignProposeAndPayAs("find").
			Test(otu.T).
			AssertSuccess().
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.NFTRegistry.NFTInfoRegistered", map[string]interface{}{
				"alias":          "ExampleNFT",
				"typeIdentifier": "A.f8d6e0586b0a20c7.ExampleNFT.NFT",
			}))

		events := otu.O.TransactionFromFile("testMintExampleNFT").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("user1").
				String("Bam").
				String("ExampleNFT").
				String("This is an ExampleNFT").
				String("This is an exampleNFT url").
				String("Example NFT FIND").
				String("Example NFT external url").
				String("Example NFT square image").
				String("Example NFT banner image")).
			Test(t).
			AssertSuccess()

		dandyIds := []uint64{}
		for _, event := range events.Events {
			if event.Name == "A.f8d6e0586b0a20c7.ExampleNFT.Deposit" {
				dandyIds = append(dandyIds, event.GetFieldAsUInt64("id"))
			}
		}

		// result := otu.O.ScriptFromFile("getCollections").
		// 	Args(otu.O.Arguments().String("user1")).
		// 	RunReturnsJsonString()

		// result = otu.replaceID(result, dandyIds)
		// result = otu.replaceID(result, uuids)

		// autogold.Equal(t, result)

		otu.O.Script("getCollections",
			overflow.WithArg("user", "user1"),
		).AssertWithPointerWant(t,
			"/collections",
			autogold.Want("collection", map[string]interface{}{"ExampleNFT": []interface{}{"ExampleNFT1"}}),
		)

	})

}
