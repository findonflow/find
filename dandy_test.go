package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestDandy(t *testing.T) {

	t.Run("Should be able to mint 3 dandy nfts and display them", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2")

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
  "A.f8d6e0586b0a20c7.FindViews.CreativeWork",
  "A.f8d6e0586b0a20c7.MetadataViews.Traits",
  "A.f8d6e0586b0a20c7.MetadataViews.Editions",
  "A.f8d6e0586b0a20c7.MetadataViews.ExternalURL",
  "A.f8d6e0586b0a20c7.MetadataViews.Medias",
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
			autogold.Want("ExternalURL", map[string]interface{}{"url": "https://find.xyz/collection/user1/dandy/247"}),
		)

	})

	/* Test on dandy nft indexing {Mapping of minter} */
	t.Run("Should be able to return the correct minter and dandies list", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2")
		dandiesIDs := otu.mintThreeExampleDandies()
		otu.registerFtInRegistry()

		otu.O.Script("getDandiesIDsFor",
			overflow.WithArg("user", "user1"),
			overflow.WithArg("minter", "user1"),
		).AssertWant(t,
			autogold.Want("allDandies", "[]interface {}{\n  247,\n  248,\n  249,\n}"),
		)

		otu.O.Script("getDandiesMinters",
			overflow.WithArg("user", "user1"),
		).AssertWant(t,
			autogold.Want("dandyMinters", `[]interface {}{
  "user1",
}`),
		)

		/* mint new dandies and withdraw all of them */
		dandiesIDs = append(dandiesIDs, otu.mintThreeExampleDandies()...)

		otu.O.TransactionFromFile("testDestroyDandies").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				UInt64Array(dandiesIDs...)).
			Test(otu.T).
			AssertSuccess()

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
