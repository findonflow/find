package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow/v2"
)

func TestFindFurnace(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}
	dandyType := otu.identifier("Dandy", "NFT")

	ot.Run(t, "Should be able to burn Dandy", func(t *testing.T) {
		res := otu.O.Tx("burnNFTs",
			WithSigner("user1"),
			WithArg("types", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", dandyIds),
			WithArg("messages", []string{"Message 0", "Message 1", "Message 2"}),
		).
			AssertSuccess(t)

		for i, id := range dandyIds {

			events := res.GetEventsWithName("FindFurnace.Burned")
			mockField := map[string]interface{}{}
			for _, e := range events {
				field, exist := e.Fields["nftInfo"].(map[string]interface{})
				if exist {
					mockId := field["id"].(uint64)
					if id == mockId {
						field["id"] = id
						field["type"] = dandyType
						mockField = field
					}
				}
			}

			res.AssertEvent(t, "FindFurnace.Burned", map[string]interface{}{
				"from":     otu.O.Address("user1"),
				"fromName": "user1",
				"uuid":     id,
				"context": map[string]interface{}{
					"message": fmt.Sprintf("Message %d", i),
					"tenant":  "find",
				},
				"nftInfo": mockField,
			})
		}
	})
}
