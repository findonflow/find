package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/sanity-io/litter"
)

func TestFindAirdropper(t *testing.T) {

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

	t.Run("Should be able to send Airdrop with only collection public linked", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.O.Tx("devUnlinkDandyReceiver",
			WithSigner("user2"),
		).
			AssertSuccess(t)

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
				"remark": "Receiver Not Linked",
			})
		}
	})

	t.Run("Should not be able to send Airdrop without collection, good events will be emitted", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		user3 := otu.O.Address("user3")

		res := otu.O.Tx("airdropNFTs",
			WithSigner("user1"),
			WithArg("receivers", []string{user3, user3, user3}),
			WithArg("types", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("messages", []string{"Message 0", "Message 1", "Message 2"}),
		).
			AssertSuccess(t)

		for i, id := range ids {
			res.AssertEvent(t, "FindAirdropper.AirdropFailed", map[string]interface{}{
				"from": otu.O.Address("user1"),
				"to":   otu.O.Address("user3"),
				"id":   id,
				"uuid": id,
				"type": dandyType,
				"context": map[string]interface{}{
					"message": fmt.Sprintf("Message %d", i),
				},
				"reason": "Invalid Receiver Capability",
			})
		}
	})

	t.Run("Should be able to get Airdrop details with a script", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		user3 := otu.O.Address("user3")

		makeResult := func(account, cplinked bool, id, index uint64, nftInplace, ok bool, receiver string, receiverlinked bool, t string) map[string]interface{} {
			return map[string]interface{}{
				"accountInitialized":     account,
				"collectionPublicLinked": cplinked,
				"id":                     id,
				"message":                fmt.Sprintf("Message %d", index),
				"nftInPlace":             nftInplace,
				"ok":                     ok,
				"receiver":               receiver,
				"receiverLinked":         receiverlinked,
				"type":                   t,
			}
		}

		res := otu.O.Script("airdropNFTs",
			WithArg("sender", "user1"),
			WithArg("receivers", []string{"user1", "user2", user3}),
			WithArg("types", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("messages", []string{"Message 0", "Message 1", "Message 2"}),
		)

		user1Res := makeResult(true, true, ids[0], 0, true, true, "user1", true, dandyType)
		user2Res := makeResult(true, true, ids[1], 1, true, true, "user2", false, dandyType)
		user3Res := makeResult(false, false, ids[2], 2, true, false, otu.O.Address("user3"), false, dandyType)

		res.AssertWant(t, autogold.Want("airdropNFTs", litter.Sdump([]interface{}{user1Res, user2Res, user3Res})))

	})

}
