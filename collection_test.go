package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCollectionScripts(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	t.Run("Should be able to get dandies by script", func(t *testing.T) {
		var data []CollectionData
		err := otu.O.Script("getNFTCatalogItems",
			WithArg("user", "user1"),
			WithArg("collectionIDs", map[string][]uint64{dandyNFTType(otu): dandyIds}),
		).MarshalPointerAs(fmt.Sprintf("/%s", dandyNFTType(otu)), &data)
		require.NoError(t, err)

		autogold.Equal(t, data)
	})

	t.Run("Should be able to get soul bounded items by script", func(t *testing.T) {
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

		var data []CollectionData
		err = otu.O.Script("getNFTCatalogItems",
			WithArg("user", otu.O.Address("find")),
			WithArg("collectionIDs", map[string]interface{}{exampleNFTIden: typedIds}),
		).MarshalPointerAs(fmt.Sprintf("/%s", exampleNFTIden), &data)

		assert.NoError(t, err)

		autogold.Equal(t, data)
	})
}
