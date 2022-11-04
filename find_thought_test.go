package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestFindThought(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		setupDandy("user1").
		createUser(100.0, "user2").
		registerUser("user2")

	header := "This is header"
	body := "This is body"
	tags := []string{"tag1", "tag2", "@find"}
	mediaHash := "mediaHash"
	mediaType := "mediaType"
	var thoguhtId uint64

	t.Run("Should be able to post a thought", func(t *testing.T) {
		var err error
		thoguhtId, err = otu.O.Tx("publishFindThought",
			WithSigner("user1"),
			WithArg("header", header),
			WithArg("body", body),
			WithArg("tags", tags),
			WithArg("mediaHash", mediaHash),
			WithArg("mediaType", mediaType),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Published", map[string]interface{}{
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"header":      header,
				"message":     body,
				"medias": []interface{}{
					fmt.Sprintf("ipfs://%s", mediaHash),
				},
				"tags": []interface{}{"tag1", "tag2", "@find"},
			}).
			GetIdFromEvent("Published", "id")

		assert.NoError(t, err)
	})

	if thoguhtId == 0 {
		thoguhtId, _ = otu.O.Tx("publishFindThought",
			WithSigner("user1"),
			WithArg("header", header),
			WithArg("body", body),
			WithArg("tags", tags),
			WithArg("mediaHash", mediaHash),
			WithArg("mediaType", mediaType),
		).
			GetIdFromEvent("Published", "id")
	}

	newHeader := "This is new header"
	newBody := "This is new body"
	newTags := []string{"tag4", "tag5", "@fest"}

	t.Run("Should be able to edit a thought", func(t *testing.T) {

		otu.O.Tx("editFindThought",
			WithSigner("user1"),
			WithArg("id", thoguhtId),
			WithArg("header", newHeader),
			WithArg("body", newBody),
			WithArg("tags", newTags),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Edited", map[string]interface{}{
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"header":      newHeader,
				"message":     newBody,
				"medias": []interface{}{
					fmt.Sprintf("ipfs://%s", mediaHash),
				},
				"tags": []interface{}{"tag4", "tag5", "@fest"},
			})
	})

	t.Run("Should be able to react to a thought", func(t *testing.T) {

		otu.O.Tx("reactToFindThoughts",
			WithSigner("user2"),
			WithArg("users", []string{"user1"}),
			WithArg("ids", []uint64{thoguhtId}),
			WithArg("reactions", []string{"fire"}),
			WithArg("undoReactionUsers", `[]`),
			WithArg("undoReactionIds", `[]`),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Reacted", map[string]interface{}{
				"id":          thoguhtId,
				"by":          otu.O.Address("user2"),
				"byName":      "user2",
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"header":      newHeader,
				"reaction":    "fire",
				"totalCount": map[string]interface{}{
					"fire": 1,
				},
			})
	})

	t.Run("Should be able to change reaction to a thought", func(t *testing.T) {

		otu.O.Tx("reactToFindThoughts",
			WithSigner("user2"),
			WithArg("users", []string{"user1"}),
			WithArg("ids", []uint64{thoguhtId}),
			WithArg("reactions", []string{"sad"}),
			WithArg("undoReactionUsers", `[]`),
			WithArg("undoReactionIds", `[]`),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Reacted", map[string]interface{}{
				"id":          thoguhtId,
				"by":          otu.O.Address("user2"),
				"byName":      "user2",
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"header":      newHeader,
				"reaction":    "sad",
				"totalCount": map[string]interface{}{
					"sad": 1,
				},
			})
	})

	t.Run("Should be able to undo reaction to a thought", func(t *testing.T) {

		otu.O.Tx("reactToFindThoughts",
			WithSigner("user2"),
			WithArg("users", `[]`),
			WithArg("ids", `[]`),
			WithArg("reactions", `[]`),
			WithArg("undoReactionUsers", []string{"user1"}),
			WithArg("undoReactionIds", []uint64{thoguhtId}),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Reacted", map[string]interface{}{
				"id":          thoguhtId,
				"by":          otu.O.Address("user2"),
				"byName":      "user2",
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"header":      newHeader,
			})
	})

	t.Run("Should be able to get thoguht by a script", func(t *testing.T) {

		res, err := otu.O.Script("getFindThoughts",
			WithArg("user", "user1"),
		).
			GetAsJson()

		assert.NoError(t, err)

		autogold.Equal(t, res)
	})

	t.Run("Should be able to delete a thought", func(t *testing.T) {

		otu.O.Tx("deleteFindThoughts",
			WithSigner("user1"),
			WithArg("ids", []uint64{thoguhtId}),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Deleted", map[string]interface{}{
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"header":      newHeader,
				"message":     newBody,
				"medias": []interface{}{
					fmt.Sprintf("ipfs://%s", mediaHash),
				},
				"tags": []interface{}{"tag4", "tag5", "@fest"},
			})
	})

}
