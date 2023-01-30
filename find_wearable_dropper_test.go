package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestFindWearablesDropper(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createWearableUser("user1")

	id1 := otu.mintWearables("user1")
	id2 := otu.mintWearables("user1")
	id3 := otu.mintWearables("user1")

	t.Run("Should be able to send Wearables using Airdrop", func(t *testing.T) {
		otu.createWearableUser("user2")

		user2 := otu.O.Address("user2")
		user3 := otu.O.Address("user3")

		res := otu.O.Tx(
			"sendWearables",
			WithSigner("user1"),
			WithArg("allReceivers", []string{user2, user3, user2}),
			WithArg("ids", []uint64{id1, id2, id3}),
			WithArg("memos", []string{"1", "2", "3"}),
		).
			AssertSuccess(t)

		res.AssertEvent(t, "Airdropped", map[string]interface{}{
			"from": otu.O.Address("user1"),
			"to":   otu.O.Address("user2"),
			"uuid": id1,
			"context": map[string]interface{}{
				"tenant":  "find",
				"message": "1",
			},
		})

		res.AssertEvent(t, "Airdropped", map[string]interface{}{
			"from": otu.O.Address("user1"),
			"to":   otu.O.Address("user2"),
			"uuid": id3,
			"context": map[string]interface{}{
				"tenant":  "find",
				"message": "3",
			},
		})

		res.AssertEvent(t, "AirdropFailed", map[string]interface{}{
			"from": otu.O.Address("user1"),
			"to":   otu.O.Address("user3"),
			"uuid": id2,
			"context": map[string]interface{}{
				"tenant":  "find",
				"message": "2",
			},
			"reason": "Invalid Receiver Capability",
		})
	})

}
