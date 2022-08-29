package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestFindLostAndFound(t *testing.T) {
	otu := NewOverflowTest(t)

	otu.setupFIND().
		createUser(10000.0, "user1").
		registerUser("user1").
		registerExampleNFTInNFTRegistry()

	t.Run("Should be able to query estimated flow for depositing", func(t *testing.T) {
		//sender: Address, nftIdentifiers: [String], allReceivers: [String] , ids:[UInt64], random: Bool
		otu.O.Script("estimateStorageFee",
			overflow.WithArg("sender", "account"),
			overflow.WithArg("nftIdentifiers", `["A.f8d6e0586b0a20c7.ExampleNFT.NFT"]`),
			overflow.WithArg("allReceivers", `["user1"]`),
			overflow.WithArg("ids", []uint64{0}),
			overflow.WithArg("random", false),
		).AssertWant(t,
			autogold.Want("Should be able to query estimated flow for depositing", nil),
		)

	})

}
