package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestNFTRegistry(t *testing.T) {

	t.Run("Should be able to registry Dandy Token and get it", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry()

		o := otu.O
		result := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("A.f8d6e0586b0a20c7.Dandy.NFT")).
			RunReturnsInterface()

		expected := map[string]interface{}{
			"address":                "0xf8d6e0586b0a20c7",
			"allowedFTTypes":         "",
			"icon":                   "",
			"externalFixedUrl":       "find.xyz",
			"alias":                  "Dandy",
			"providerPath":           "/private/findDandy",
			"providerPathIdentifier": "findDandy",
			"publicPath":             "/public/findDandy",
			"publicPathIdentifier":   "findDandy",
			"storagePath":            "/storage/findDandy",
			"storagePathIdentifier":  "findDandy",
			"type":                   "Type<A.f8d6e0586b0a20c7.Dandy.NFT>()",
			"typeIdentifier":         "A.f8d6e0586b0a20c7.Dandy.NFT",
		}
		assert.Equal(t, expected, result)

		result = o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()

		assert.Equal(t, expected, result)

		result = otu.O.ScriptFromFile("getNFTInfoAll").RunReturnsJsonString()
		otu.AutoGold("getNFTInfoAll", result)

		/* Should not be able to overrride an nft without removing it first */
		o.TransactionFromFile("adminSetNFTInfo_Dandy").
			SignProposeAndPayAs("find").
			Args(o.Arguments()).
			Test(t).
			AssertFailure("This NonFungibleToken Register already exist")

		/* Should be removable by alias */
		otu.removeDandyInNFtRegistry("adminRemoveNFTInfoByAlias", "Dandy")

		aliasResult := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, "", aliasResult)

		infoResult := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, "", infoResult)

		/* Should be removable by Identifier */
		otu.registerDandyInNFTRegistry().
			removeDandyInNFtRegistry("adminRemoveNFTInfoByTypeIdentifier", "A.f8d6e0586b0a20c7.Dandy.NFT")

		aliasResult = o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("A.f8d6e0586b0a20c7.Dandy.NFT")).
			RunReturnsInterface()
		assert.Equal(t, "", aliasResult)

		infoResult = o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, "", infoResult)

	})


}
