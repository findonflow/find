package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"golang.org/x/exp/slices"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestDandy(t *testing.T) {
	otu := NewOverflowTest(t).
		setupFIND().
		setupDandy("user1").
		createUser(100.0, "user2").
		registerUser("user2")

	t.Run("Should be able to mint 3 dandy nfts and display them", func(t *testing.T) {

		otu.setUUID(500)

		dandyIds := otu.mintThreeExampleDandies()
		otu.registerFtInRegistry()

		id := dandyIds[0]

		viewList := []string{
			otu.identifier("FindViews", "Nounce"),
			otu.identifier("MetadataViews", "NFTCollectionData"),
			otu.identifier("MetadataViews", "NFTCollectionDisplay"),
			otu.identifier("MetadataViews", "Display"),
			otu.identifier("MetadataViews", "Royalties"),
			otu.identifier("MetadataViews", "Editions"),
			otu.identifier("MetadataViews", "Traits"),
			otu.identifier("MetadataViews", "ExternalURL"),
			otu.identifier("MetadataViews", "CreativeWork"),
			otu.identifier("MetadataViews", "Medias"),
		}

		res, err := otu.O.Script("getNFTViews",
			WithArg("user", "user1"),
			WithArg("aliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
		).
			GetAsInterface()
		require.NoError(t, err)

		resList, ok := res.([]interface{})
		require.True(t, ok)
		for _, item := range resList {
			stringItem := item.(string)
			slices.Contains(viewList, stringItem)
		}

		otu.O.Script("getNFTView",
			WithArg("user", "user1"),
			WithArg("aliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("identifier", otu.identifier("MetadataViews", "Display")),
		).AssertWant(t,
			autogold.Want("Display", map[string]interface{}{
				"description": "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK",
				"name":        "Neo Motorcycle 1 of 3",
				"thumbnail":   map[string]interface{}{"url": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"},
			}),
		)

		otu.O.Script("getNFTView",
			WithArg("user", "user1"),
			WithArg("aliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("identifier", otu.identifier("MetadataViews", "ExternalURL")),
		).AssertWant(t,
			autogold.Want("ExternalURL", map[string]interface{}{"url": "https://find.xyz/collection/user1/dandy/502"}),
		)

		for _, dandy := range dandyIds {
			otu.sendDandy("user2", "user1", dandy)
		}

	})

	/* Test on dandy nft indexing {Mapping of minter} */
	t.Run("Should be able to return the correct minter and dandies list", func(t *testing.T) {

		otu.setUUID(700)

		dandiesIDs := otu.mintThreeExampleDandies()

		result, err := otu.O.Script("getDandiesIDsFor",
			WithArg("user", "user1"),
			WithArg("minter", "user1"),
		).GetAsInterface()

		if err != nil {
			panic(err)
		}

		assert.ElementsMatch(t, result, []interface{}{uint64(702), uint64(703), uint64(704)})

		otu.O.Script("getDandiesMinters",
			WithArg("user", "user1"),
		).AssertWant(t,
			autogold.Want("dandyMinters", `[]interface {}{
  "user1",
}`),
		)

		/* mint new dandies and withdraw all of them */
		dandiesIDs = append(dandiesIDs, otu.mintThreeExampleDandies()...)

		otu.O.Tx("devDestroyDandies",
			WithSigner("user1"),
			WithArg("ids", dandiesIDs),
		).AssertSuccess(t)

		otu.O.Script("getDandiesIDsFor",
			WithArg("user", "user1"),
			WithArg("minter", "user1"),
		).AssertWant(t,
			autogold.Want("noDandies", nil),
		)

		otu.O.Script("getDandiesMinters",
			WithArg("user", "user1"),
		).AssertWant(t,
			autogold.Want("noDandyMinters", nil),
		)

	})
}
