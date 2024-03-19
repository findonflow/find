package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow/v2"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/require"
)

func TestCollectionScripts(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	ot.Run(t, "Should be able to get dandies by script", func(t *testing.T) {
		var data []CollectionData
		err := otu.O.Script("getNFTCatalogItems",
			WithArg("user", "user1"),
			WithArg("collectionIDs", map[string][]uint64{dandyNFTType(otu): dandyIds}),
		).MarshalPointerAs(fmt.Sprintf("/%s", dandyNFTType(otu)), &data)
		require.NoError(t, err)

		autogold.Equal(t, data)
	})
}
