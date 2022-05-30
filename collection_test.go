package test_main

import (
	"testing"

	"github.com/hexops/autogold"
)

func TestCollectionScripts(t *testing.T) {

	t.Run("Should be able to mint Dandy and then get it by script", func(t *testing.T) {

		otu := NewOverflowTest(t)
		otu.setupFIND().
			setupDandy("user1").
			registerDandyInNFTRegistry().
			mintThreeExampleDandies()

		result := otu.O.ScriptFromFile("getCollections").
			Args(otu.O.Arguments().String("user1")).
			RunReturnsJsonString()

		autogold.Equal(t, result)
	})

}
