package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
)

func TestFindFurnace(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		setupDandy("user1")

	dandyType := fmt.Sprintf("A.%s.%s.%s", otu.O.Account("account").Address().String(), "Dandy", "NFT")
	otu.mintThreeExampleDandies()
	otu.registerDandyInNFTRegistry()

	t.Run("Should be able to burn Dandy", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		res := otu.O.Tx("burnNFTs",
			WithSigner("user1"),
			WithArg("types", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("messages", []string{"Message 0", "Message 1", "Message 2"}),
		).
			AssertSuccess(t)

		for i, id := range ids {
			res.AssertEvent(t, "FindFurnace.Burned", map[string]interface{}{
				"from": otu.O.Address("user1"),
				"id":   id,
				"uuid": id,
				"type": dandyType,
				"context": map[string]interface{}{
					"message": fmt.Sprintf("Message %d", i),
				},
			})
		}
	})

}