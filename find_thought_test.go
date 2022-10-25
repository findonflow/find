package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
)

func TestFindThought(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		setupDandy("user1").
		createUser(100.0, "user2").
		registerUser("user2")

	dandyType := fmt.Sprintf("A.%s.%s.%s", otu.O.Account("account").Address().String(), "Dandy", "NFT")
	otu.mintThreeExampleDandies()
	otu.registerDandyInNFTRegistry()

	t.Run("Should be able to send Airdrop", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		res := otu.O.Tx("airdropNFTs",
			WithSigner("user1"),
			WithArg("receivers", []string{"user2", "user2", "user2"}),
			WithArg("types", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("messages", []string{"Message 0", "Message 1", "Message 2"}),
		).
			AssertSuccess(t)

		for i, id := range ids {
			res.AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
				"from": otu.O.Address("user1"),
				"to":   otu.O.Address("user2"),
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
