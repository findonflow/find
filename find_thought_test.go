package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
)

func TestFindThought(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	// this is a strange pattern...
	user1 := ot.O.FlowAddress("user1").Bytes()
	user1Bytes := cadence.BytesToAddress(user1)
	user := cadence.NewOptional(user1Bytes)
	inputId, err := otu.createOptional(dandyIds[0])
	assert.NoError(t, err)
	inputIdentifier, err := otu.createOptional(dandyIdentifier)
	assert.NoError(t, err)

	ot.Run(t, "Should be able to post a thought", func(t *testing.T) {
		thoughtId := otu.postExampleThought()

		var data []ThoughtData
		err := otu.O.Script("getFindThoughts",
			WithAddresses("addresses", "user1"),
			WithArg("ids", []uint64{thoughtId}),
		).MarshalAs(&data)

		assert.NoError(t, err)
		autogold.Equal(t, data)
	})

	newHeader := "This is new header"
	newBody := "This is new body"
	newTags := []string{"tag4", "tag5", "@fest"}

	ot.Run(t, "Should be able to edit a thought", func(t *testing.T) {
		thoughtId := otu.postExampleThought()

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
				"tags":        []interface{}{"tag4", "tag5", "@fest"},
			})
	})

	ot.Run(t, "Should be able to react to a thought", func(t *testing.T) {
		thoughtId := otu.postExampleThought()
		otu.reactToThought(thoughtId, "fire")
	})

	ot.Run(t, "Should be able to get a list of different thoguhts by a script with reacted list", func(t *testing.T) {
		thoughtId := otu.postExampleThought()
		otu.reactToThought(thoughtId, "fire")

		var data []ThoughtData
		err := otu.O.Script("getFindThoughts",
			WithAddresses("addresses", "user1"),
			WithArg("ids", []uint64{thoughtId}),
		).MarshalAs(&data)

		assert.NoError(t, err)
		autogold.Equal(t, data)
	})

	ot.Run(t, "Should be able to undo reaction to a thought", func(t *testing.T) {
		thoughtId := otu.postExampleThought()
		otu.reactToThought(thoughtId, "fire")

		otu.O.Tx("reactToFindThoughts",
			WithSigner("user2"),
			WithArg("users", `[]`),
			WithArg("ids", `[]`),
			WithArg("reactions", `[]`),
			WithArg("undoReactionUsers", []string{"user1"}),
			WithArg("undoReactionIds", []uint64{thoughtId}),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Reacted", map[string]interface{}{
				"id":          thoughtId,
				"by":          otu.O.Address("user2"),
				"byName":      "user2",
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
			})
	})

	ot.Run(t, "Should be able to delete a thought", func(t *testing.T) {
		thoughtId := otu.postExampleThought()

		otu.O.Tx("deleteFindThoughts",
			WithSigner("user1"),
			WithArg("ids", []uint64{thoughtId}),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Deleted", map[string]interface{}{
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
			})
	})

	ot.Run(t, "Should be able to post a thought with NFT", func(t *testing.T) {
		nftInfo, err := otu.O.Script(`
			import MetadataViews from "../contracts/standard/MetadataViews.cdc"
			import ViewResolver from "../contracts/standard/ViewResolver.cdc"
			import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
			import FindMarket from "../contracts/FindMarket.cdc"
			import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
			import FindViews from "../contracts/FindViews.cdc"

			access(all) fun main(quoteNFTOwner: Address?, quoteNFTType: String?, quoteNFTId: UInt64?) : FindMarket.NFTInfo? {

				var nftPointer : FindViews.ViewReadPointer? = nil
				if quoteNFTOwner != nil {
						let path = FINDNFTCatalog.getCollectionDataForType(nftTypeIdentifier: quoteNFTType!)?.publicPath ?? panic("This nft type is not supported by NFT Catalog. Type : ".concat(quoteNFTType!))
						let cap = getAccount(quoteNFTOwner!).capabilities.get<&{NonFungibleToken.Collection}>(path)!
						nftPointer = FindViews.ViewReadPointer(cap: cap, id: quoteNFTId!)
						let rv = nftPointer!.getViewResolver()
						return FindMarket.NFTInfo(rv, id: nftPointer!.id, detail: true)
				}
				return nil
			}
			`,
			WithArg("quoteNFTOwner", user),
			WithArg("quoteNFTType", inputIdentifier),
			WithArg("quoteNFTId", inputId),
		).
			GetAsInterface()

		assert.NoError(t, err)

		thoughtId, _ := otu.O.Tx("publishFindThought",
			WithSigner("user1"),
			WithArg("header", "head"),
			WithArg("body", "body"),
			WithArg("tags", []string{"tag1", "tag2", "@find"}),
			WithArg("mediaHash", nil),
			WithArg("mediaType", nil),
			WithArg("quoteNFTOwner", user),
			WithArg("quoteNFTType", inputIdentifier),
			WithArg("quoteNFTId", inputId),
			WithArg("quoteCreator", nil),
			WithArg("quoteId", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Published", map[string]interface{}{
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"nfts":        []interface{}{nftInfo},
				"tags":        []interface{}{"tag1", "tag2", "@find"},
			}).
			GetIdFromEvent("FindThoughts.Published", "id")

		var data []ThoughtData
		err = otu.O.Script("getFindThoughts",
			WithAddresses("addresses", "user1"),
			WithArg("ids", []uint64{thoughtId}),
		).MarshalAs(&data)

		assert.NoError(t, err)
		autogold.Equal(t, data)
	})

	ot.Run(t, "Should be able to post a thought with quote", func(t *testing.T) {
		thoughtId := otu.postExampleThought()
		inputThoughtId, err := otu.createOptional(thoughtId)
		assert.NoError(t, err)

		thought, err := otu.O.Tx("publishFindThought",
			WithSigner("user1"),
			WithArg("header", "header"),
			WithArg("body", "body"),
			WithArg("tags", []string{"tag1"}),
			WithArg("mediaHash", nil),
			WithArg("mediaType", nil),
			WithArg("quoteNFTOwner", nil),
			WithArg("quoteNFTType", nil),
			WithArg("quoteNFTId", nil),
			WithArg("quoteCreator", user),
			WithArg("quoteId", inputThoughtId),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindThoughts.Published", map[string]interface{}{
				"creator":     otu.O.Address("user1"),
				"creatorName": "user1",
				"tags":        []interface{}{"tag1"},
				"quoteOwner":  otu.O.Address("user1"),
				"quoteId":     thoughtId,
			}).
			GetIdFromEvent("FindThoughts.Published", "id")
		assert.NoError(t, err)

		var data []ThoughtData
		err = otu.O.Script("getFindThoughts",
			WithAddresses("addresses", "user1"),
			WithArg("ids", []uint64{thought}),
		).MarshalAs(&data)

		assert.NoError(t, err)
		autogold.Equal(t, data)
	})

	ot.Run(t, "Should be able to hide thoughts", func(t *testing.T) {
		thoughtId := otu.postExampleThought()

		otu.O.Tx("hideFindThoughts",
			WithSigner("user1"),
			WithArg("ids", []uint64{thoughtId}),
			WithArg("hide", []bool{true}),
		).
			AssertSuccess(t).
			AssertEvent(t, "Edited", map[string]interface{}{
				"id":   thoughtId,
				"hide": true,
			})

		var data []ThoughtData
		err := otu.O.Script("getOwnedFindThoughts",
			WithArg("address", "user1"),
		).MarshalAs(&data)

		assert.NoError(t, err)
		autogold.Equal(t, data)
	})
}

type ThoughtData struct {
	Body               string            `json:"body"`
	Created            int               `json:"created"`
	Creator            string            `json:"creator"`
	CreatorAvatar      string            `json:"creatorAvatar"`
	CreatorName        string            `json:"creatorName"`
	CreatorProfileName string            `json:"creatorProfileName"`
	Header             string            `json:"header"`
	Hidden             bool              `json:"hidden"`
	Medias             map[string]string `json:"medias"`
	Reacted            interface{}       `json:"reacted"`
	ReactedUsers       interface{}       `json:"reactedUsers"`
	Reactions          map[string]int    `json:"reactions"`
	Tags               []string          `json:"tags"`
	QuotedThought      *ThoughtData      `json:"quotedThought"`
	NFT                []NftDetail       `json:"nft"`
}
