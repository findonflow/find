package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
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

		otu.O.Script("getNFTViews",
			overflow.WithArg("user", "user1"),
			overflow.WithArg("aliasOrIdentifier", "A.f8d6e0586b0a20c7.Dandy.NFT"),
			overflow.WithArg("id", id),
		).AssertWant(t,
			autogold.Want("Views", `[]interface {}{
  "A.f8d6e0586b0a20c7.FindViews.Nounce",
  "A.f8d6e0586b0a20c7.MetadataViews.NFTCollectionData",
  "A.f8d6e0586b0a20c7.MetadataViews.NFTCollectionDisplay",
  "A.f8d6e0586b0a20c7.MetadataViews.Display",
  "A.f8d6e0586b0a20c7.MetadataViews.Royalties",
  "A.f8d6e0586b0a20c7.MetadataViews.Medias",
  "A.f8d6e0586b0a20c7.FindViews.CreativeWork",
  "A.f8d6e0586b0a20c7.MetadataViews.ExternalURL",
  "A.f8d6e0586b0a20c7.MetadataViews.Traits",
  "A.f8d6e0586b0a20c7.MetadataViews.Editions",
}`),
		)
		otu.O.Script("getNFTView",
			overflow.WithArg("user", "user1"),
			overflow.WithArg("aliasOrIdentifier", "A.f8d6e0586b0a20c7.Dandy.NFT"),
			overflow.WithArg("id", id),
			overflow.WithArg("identifier", "A.f8d6e0586b0a20c7.MetadataViews.Display"),
		).AssertWant(t,
			autogold.Want("Display", map[string]interface{}{
				"description": "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK",
				"name":        "Neo Motorcycle 1 of 3",
				"thumbnail":   map[string]interface{}{"url": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"},
			}),
		)

		otu.O.Script("getNFTView",
			overflow.WithArg("user", "user1"),
			overflow.WithArg("aliasOrIdentifier", "A.f8d6e0586b0a20c7.Dandy.NFT"),
			overflow.WithArg("id", id),
			overflow.WithArg("identifier", "A.f8d6e0586b0a20c7.MetadataViews.ExternalURL"),
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
			overflow.WithArg("user", "user1"),
			overflow.WithArg("minter", "user1"),
		).GetAsInterface()

		if err != nil {
			panic(err)
		}

		assert.ElementsMatch(t, result, []interface{}{uint64(702), uint64(703), uint64(704)})

		otu.O.Script("getDandiesMinters",
			overflow.WithArg("user", "user1"),
		).AssertWant(t,
			autogold.Want("dandyMinters", `[]interface {}{
  "user1",
}`),
		)

		/* mint new dandies and withdraw all of them */
		dandiesIDs = append(dandiesIDs, otu.mintThreeExampleDandies()...)

		otu.O.Tx("devDestroyDandies",
			overflow.WithSigner("user1"),
			overflow.WithArg("ids", dandiesIDs),
		).AssertSuccess(t)

		otu.O.Script("getDandiesIDsFor",
			overflow.WithArg("user", "user1"),
			overflow.WithArg("minter", "user1"),
		).AssertWant(t,
			autogold.Want("noDandies", nil),
		)

		otu.O.Script("getDandiesMinters",
			overflow.WithArg("user", "user1"),
		).AssertWant(t,
			autogold.Want("noDandyMinters", nil),
		)

	})
}
