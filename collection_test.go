package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestCollectionScripts(t *testing.T) {
	otu := NewOverflowTest(t)

	otu.setupFIND().
		createUser(10000.0, "user1").
		registerUser("user1").
		buyForge("user1").
		registerUserWithNameAndForge("user1", "neomotorcycle").
		registerUserWithNameAndForge("user1", "xtingles").
		registerUserWithNameAndForge("user1", "flovatar").
		registerUserWithNameAndForge("user1", "ufcstrike").
		registerUserWithNameAndForge("user1", "jambb").
		registerUserWithNameAndForge("user1", "bitku").
		registerUserWithNameAndForge("user1", "goatedgoats").
		registerUserWithNameAndForge("user1", "klktn")

	ids := otu.O.Tx("devMintDandyTO",
		WithSigner("user1"),
		WithArg("name", "user1"),
		WithArg("maxEdition", 1),
		WithArg("artist", "Neo"),
		WithArg("nftName", "Motorcycle"),
		WithArg("nftDescription", `Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK`),
		WithArg("nftUrl", "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"),
		WithArg("rarity", "rare"),
		WithArg("rarityNum", 50.0),
		WithArg("to", "user1"),
	).
		AssertSuccess(t).GetIdsFromEvent("Minted", "id")

	otu.registerDandyInNFTRegistry()

	t.Run("Should be able to get dandies by script", func(t *testing.T) {
		result, err := otu.O.Script("getNFTCatalogItems",
			WithArg("user", "user1"),
			WithArg("collectionIDs", map[string][]uint64{dandyNFTType(otu): ids}),
		).GetWithPointer(fmt.Sprintf("/%s", dandyNFTType(otu)))
		if err != nil {
			panic(err)
		}

		// TODO: we need to find a way to assert this better
		assert.NotNil(t, result)
	})

	t.Run("Should be able to get soul bounded items by script", func(t *testing.T) {
		otu.registerExampleNFTInNFTRegistry()

		exampleNFTIden := exampleNFTType(otu)

		ids, err := otu.O.Script("getNFTCatalogIDs",
			WithArg("user", otu.O.Address("find")),
			WithArg("collections", `[]`),
		).
			GetWithPointer(fmt.Sprintf("/%s/extraIDs", exampleNFTIden))

		assert.NoError(t, err)

		typedIds, ok := ids.([]interface{})

		if !ok {
			panic(ids)
		}

		result, err := otu.O.Script("getNFTCatalogItems",
			WithArg("user", otu.O.Address("find")),
			WithArg("collectionIDs", map[string]interface{}{exampleNFTIden: typedIds}),
		).
			GetWithPointer(fmt.Sprintf("/%s", exampleNFTIden))
		if err != nil {
			panic(err)
		}

		autogold.Equal(t, result)
	})
}
