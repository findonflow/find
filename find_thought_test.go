package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
)

func TestFindThought(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	header := "This is header"
	body := "This is body"
	tags := []string{"tag1", "tag2", "@find"}
	mediaHash := "ipfs://mediaHash"
	//	mediaUrl := "mediaUrl"
	mediaType := "mediaType"

	cadMediaHash, err := otu.createOptional(mediaHash)
	assert.NoError(t, err)
	//	cadMediaUrl, err := otu.createOptional(mediaUrl)
	//	assert.NoError(t, err)
	cadMediaType, err := otu.createOptional(mediaType)
	assert.NoError(t, err)

	ot.Run(t, "Should be able to post a thought", func(t *testing.T) {
		otu.O.Tx("publishFindThought",
			WithSigner("user1"),
			WithArg("header", header),
			WithArg("body", body),
			WithArg("tags", tags),
			WithArg("mediaHash", cadMediaHash),
			WithArg("mediaType", cadMediaType),
			WithArg("quoteNFTOwner", nil),
			WithArg("quoteNFTType", nil),
			WithArg("quoteNFTId", nil),
			WithArg("quoteCreator", nil),
			WithArg("quoteId", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Published", map[string]interface{}{
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"header":      header,
				"message":     body,
				"medias": []interface{}{
					mediaHash,
				},
				"tags": []interface{}{"tag1", "tag2", "@find"},
			}).
			GetIdFromEvent("Published", "id")

		assert.NoError(t, err)
	})

	newHeader := "This is new header"
	newBody := "This is new body"
	newTags := []string{"tag4", "tag5", "@fest"}

	ot.Run(t, "Should be able to edit a thought", func(t *testing.T) {
		thoughtId, _ := otu.O.Tx("publishFindThought",
			WithSigner("user1"),
			WithArg("header", header),
			WithArg("body", body),
			WithArg("tags", tags),
			WithArg("mediaHash", cadMediaHash),
			WithArg("mediaType", cadMediaType),
			WithArg("quoteNFTOwner", nil),
			WithArg("quoteNFTType", nil),
			WithArg("quoteNFTId", nil),
			WithArg("quoteCreator", nil),
			WithArg("quoteId", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Published", map[string]interface{}{
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"header":      header,
				"message":     body,
				"medias": []interface{}{
					mediaHash,
				},
				"tags": []interface{}{"tag1", "tag2", "@find"},
			}).
			GetIdFromEvent("Published", "id")

		otu.O.Tx("editFindThought",
			WithSigner("user1"),
			WithArg("id", thoughtId),
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
					mediaHash,
				},
				"tags": []interface{}{"tag4", "tag5", "@fest"},
			})
	})

	ot.Run(t, "Should be able to react to a thought", func(t *testing.T) {
		thoughtId, _ := otu.O.Tx("publishFindThought",
			WithSigner("user1"),
			WithArg("header", header),
			WithArg("body", body),
			WithArg("tags", tags),
			WithArg("mediaHash", cadMediaHash),
			WithArg("mediaType", cadMediaType),
			WithArg("quoteNFTOwner", nil),
			WithArg("quoteNFTType", nil),
			WithArg("quoteNFTId", nil),
			WithArg("quoteCreator", nil),
			WithArg("quoteId", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Published", map[string]interface{}{
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"header":      header,
				"message":     body,
				"medias": []interface{}{
					mediaHash,
				},
				"tags": []interface{}{"tag1", "tag2", "@find"},
			}).
			GetIdFromEvent("Published", "id")

		otu.O.Tx("reactToFindThoughts",
			WithSigner("user2"),
			WithArg("users", []string{"user1"}),
			WithArg("ids", []uint64{thoughtId}),
			WithArg("reactions", []string{"fire"}),
			WithArg("undoReactionUsers", `[]`),
			WithArg("undoReactionIds", `[]`),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Reacted", map[string]interface{}{
				"id":          thoughtId,
				"by":          otu.O.Address("user2"),
				"byName":      "user2",
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"reaction":    "fire",
				"totalCount": map[string]interface{}{
					"fire": 1,
				},
			})

		otu.O.Tx("reactToFindThoughts",
			WithSigner("user2"),
			WithArg("users", []string{"user1"}),
			WithArg("ids", []uint64{thoughtId}),
			WithArg("reactions", []string{"sad"}),
			WithArg("undoReactionUsers", `[]`),
			WithArg("undoReactionIds", `[]`),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Reacted", map[string]interface{}{
				"id":      thoughtId,
				"by":      otu.O.Address("user2"),
				"byName":  "user2",
				"creator": otu.O.Address("user1"),
				"totalCount": map[string]interface{}{
					"sad": 1,
				},
			})
	})

	/*
		t.Run("Should be able to get a list of different thoguhts by a script with reacted list", func(t *testing.T) {

			res, err := otu.O.Script("getFindThoughts",
				WithAddresses("addresses", "user1"),
				WithArg("ids", []uint64{thoguhtId}),
			).
				GetAsJson()

			assert.NoError(t, err)

			autogold.Equal(t, res)
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

			res, err := otu.O.Script("getOwnedFindThoughts",
				WithArg("address", "user1"),
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
						mediaHash,
					},
					"tags": []interface{}{"tag4", "tag5", "@fest"},
				})
		})

		t.Run("Should be able to post a thought with Url", func(t *testing.T) {
			var err error

			thoguhtId, err = otu.O.Tx("publishFindThought",
				WithSigner("user1"),
				WithArg("header", header),
				WithArg("body", body),
				WithArg("tags", tags),
				WithArg("mediaHash", cadMediaUrl),
				WithArg("mediaType", cadMediaType),
				WithArg("quoteNFTOwner", nil),
				WithArg("quoteNFTType", nil),
				WithArg("quoteNFTId", nil),
				WithArg("quoteCreator", nil),
				WithArg("quoteId", nil),
			).
				AssertSuccess(t).
				AssertEvent(t, "FindThoughts.Published", map[string]interface{}{
					"creator":     otu.O.Address("user1"),
					"creatorName": "user1",
					"header":      header,
					"message":     body,
					"medias": []interface{}{
						mediaUrl,
					},
					"tags": []interface{}{"tag1", "tag2", "@find"},
				}).
				GetIdFromEvent("Published", "id")

			assert.NoError(t, err)
		})

		t.Run("Should be able to post a thought with NFT", func(t *testing.T) {

			id := otu.mintThreeExampleDandies()[0]
			identifier := dandyNFTType(otu)
			owner := otu.O.FlowAddress("user1").Bytes()

			otu.registerDandyInNFTRegistry()

			inputId, err := otu.createOptional(id)
			assert.NoError(t, err)
			inputIdentifier, err := otu.createOptional(identifier)
			assert.NoError(t, err)
			Owner := cadence.BytesToAddress(owner)
			inputOwner := cadence.NewOptional(Owner)

			nftInfo, err := otu.O.Script(`
			import MetadataViews from "../contracts/standard/MetadataViews.cdc"
			import FindMarket from "../contracts/FindMarket.cdc"
			import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
			import FindViews from "../contracts/FindViews.cdc"

			access(all) main(quoteNFTOwner: Address?, quoteNFTType: String?, quoteNFTId: UInt64?) : FindMarket.NFTInfo? {

				var nftPointer : FindViews.ViewReadPointer? = nil
				if quoteNFTOwner != nil {
						let path = FINDNFTCatalog.getCollectionDataForType(nftTypeIdentifier: quoteNFTType!)?.publicPath ?? panic("This nft type is not supported by NFT Catalog. Type : ".concat(quoteNFTType!))
						let cap = getAccount(quoteNFTOwner!).getCapability<&{ViewResolver.ResolverCollection}>(path)
						nftPointer = FindViews.ViewReadPointer(cap: cap, id: quoteNFTId!)
						let rv = nftPointer!.getViewResolver()
						return FindMarket.NFTInfo(rv, id: nftPointer!.id, detail: true)
				}
				return nil
			}
			`,
				WithArg("quoteNFTOwner", inputOwner),
				WithArg("quoteNFTType", inputIdentifier),
				WithArg("quoteNFTId", inputId),
			).
				GetAsInterface()

			assert.NoError(t, err)

			otu.O.Tx("publishFindThought",
				WithSigner("user1"),
				WithArg("header", header),
				WithArg("body", body),
				WithArg("tags", tags),
				WithArg("mediaHash", nil),
				WithArg("mediaType", nil),
				WithArg("quoteNFTOwner", inputOwner),
				WithArg("quoteNFTType", inputIdentifier),
				WithArg("quoteNFTId", inputId),
				WithArg("quoteCreator", nil),
				WithArg("quoteId", nil),
			).
				AssertSuccess(t).
				AssertEvent(t, "FindThoughts.Published", map[string]interface{}{
					"creator":     otu.O.Address("user1"),
					"creatorName": "user1",
					"header":      header,
					"message":     body,
					"nfts":        []interface{}{nftInfo},
					"tags":        []interface{}{"tag1", "tag2", "@find"},
				})
		})

		var thoughtWithQuote uint64

		t.Run("Should be able to post a thought with quote", func(t *testing.T) {

			owner := otu.O.FlowAddress("user1").Bytes()
			Owner := cadence.BytesToAddress(owner)
			inputOwner := cadence.NewOptional(Owner)

			inputThoughtId, err := otu.createOptional(thoguhtId)
			assert.NoError(t, err)

			thought, err := otu.O.Tx("publishFindThought",
				WithSigner("user1"),
				WithArg("header", header),
				WithArg("body", body),
				WithArg("tags", tags),
				WithArg("mediaHash", nil),
				WithArg("mediaType", nil),
				WithArg("quoteNFTOwner", nil),
				WithArg("quoteNFTType", nil),
				WithArg("quoteNFTId", nil),
				WithArg("quoteCreator", inputOwner),
				WithArg("quoteId", inputThoughtId),
			).
				AssertSuccess(t).
				AssertEvent(t, "FindThoughts.Published", map[string]interface{}{
					"creator":     otu.O.Address("user1"),
					"creatorName": "user1",
					"header":      header,
					"message":     body,
					"tags":        []interface{}{"tag1", "tag2", "@find"},
					"quoteOwner":  otu.O.Address("user1"),
					"quoteId":     thoguhtId,
				}).
				GetIdFromEvent("FindThoughts.Published", "id")
			assert.NoError(t, err)

			thoughtWithQuote = thought
		})

		if thoughtWithQuote == 0 {
			owner := otu.O.FlowAddress("user1").Bytes()
			Owner := cadence.BytesToAddress(owner)
			inputOwner := cadence.NewOptional(Owner)

			inputThoughtId, _ := otu.createOptional(thoguhtId)

			thought, _ := otu.O.Tx("publishFindThought",
				WithSigner("user1"),
				WithArg("header", header),
				WithArg("body", body),
				WithArg("tags", tags),
				WithArg("mediaHash", nil),
				WithArg("mediaType", nil),
				WithArg("quoteNFTOwner", nil),
				WithArg("quoteNFTType", nil),
				WithArg("quoteNFTId", nil),
				WithArg("quoteCreator", inputOwner),
				WithArg("quoteId", inputThoughtId),
			).
				GetIdFromEvent("FindThoughts.Published", "id")

			thoughtWithQuote = thought
		}

		t.Run("Should be able to get a list of different thoguhts with quoted thoughts", func(t *testing.T) {

			res, err := otu.O.Script("getFindThoughts",
				WithAddresses("addresses", "user1"),
				WithArg("ids", []uint64{thoughtWithQuote}),
			).
				GetAsJson()

			assert.NoError(t, err)

			autogold.Equal(t, res)
		})

		t.Run("Should be able to hide thoughts", func(t *testing.T) {

			otu.O.Tx("hideFindThoughts",
				WithSigner("user1"),
				WithArg("ids", []uint64{thoughtWithQuote}),
				WithArg("hide", []bool{true}),
			).
				AssertSuccess(t).
				AssertEvent(t, "Edited", map[string]interface{}{
					"id":   thoughtWithQuote,
					"hide": true,
				})
		})

		otu.O.Tx("reactToFindThoughts",
			WithSigner("user2"),
			WithArg("users", []string{"user1"}),
			WithArg("ids", []uint64{thoguhtId}),
			WithArg("reactions", []string{"fire"}),
			WithArg("undoReactionUsers", `[]`),
			WithArg("undoReactionIds", `[]`),
		).
			AssertSuccess(t)

		t.Run("Should be able to get a list of owned thoguhts with hidden status", func(t *testing.T) {

			res, err := otu.O.Script("getOwnedFindThoughts",
				WithArg("address", "user1"),
			).
				GetAsJson()

			assert.NoError(t, err)

			autogold.Equal(t, res)
		})

	*/
}
