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
		createUser(1000.0, "user1").
		registerUser("user1").
		buyForge("user1").
		createUser(100.0, "user2").
		registerUser("user2").
		registerExampleNFTInNFTRegistry()

	dandyType := fmt.Sprintf("A.%s.%s.%s", otu.O.Account("account").Address().String(), "Dandy", "NFT")
	otu.mintThreeExampleDandies()
	otu.registerDandyInNFTRegistry()

	t.Run("Should be able to send Airdrop", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		res := otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("allReceivers", []string{"user2", "user2", "user2"}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
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

	packType := "user1"
	packTypeId := uint64(1)
	salt := "find"
	singleType := []string{exampleNFTType}

	t.Run("Should be able to send packs thru airdropper with struct", func(t *testing.T) {

		type FindPack_AirdropInfo struct {
			PackTypeName string `cadence:"packTypeName"`
			PackTypeId   uint64 `cadence:"packTypeId"`
			Users        []string
			Message      string
		}

		id1 := otu.mintExampleNFTs()

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account").
			mintPack("user1", packTypeId, []uint64{id1}, singleType, salt)

		res := otu.O.Tx("sendFindPacks",
			WithSigner("find"),
			WithArg("packInfo", FindPack_AirdropInfo{
				PackTypeName: packType,
				PackTypeId:   packTypeId,
				Users:        []string{"user2"},
				Message:      "I can use struct here",
			}),
		).
			AssertSuccess(t)

		res.AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
			"from": otu.O.Address("account"),
			"to":   otu.O.Address("user2"),
			"type": "A.f8d6e0586b0a20c7.FindPack.NFT",
			"context": map[string]interface{}{
				"message": "I can use struct here",
			},
		})
	})

	t.Run("Should be able to send Airdrop with only collection public linked", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.O.Tx("testUnlinkDandyReceiver",
			WithSigner("user2"),
		).
			AssertSuccess(t)

		res := otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("allReceivers", []string{"user2", "user2", "user2"}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
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

		res := otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("allReceivers", []string{user3, user3, user3}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
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

		res := otu.O.Script("sendNFTs",
			WithArg("sender", "user1"),
			WithArg("allReceivers", []string{"user1", "user2", user3}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
		)

		user1Res := makeResult(true, true, ids[0], 0, true, true, "user1", true, dandyType)
		user2Res := makeResult(true, true, ids[1], 1, true, true, "user2", false, dandyType)
		user3Res := makeResult(false, false, ids[2], 2, true, false, otu.O.Address("user3"), false, dandyType)

		res.AssertWant(t, autogold.Want("sendNFTs", litter.Sdump([]interface{}{user1Res, user2Res, user3Res})))

	})

}
