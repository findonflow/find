package test_main

import (
	"testing"

	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestNFTRegistry(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		registerDandyInNFTRegistry()

	o := otu.O

	danyTokenWant := autogold.Want("dandy_token", map[string]interface{}{
		"address":                "0xf8d6e0586b0a20c7",
		"externalFixedUrl":       "find.xyz",
		"alias":                  "Dandy",
		"providerPath":           "/private/findDandy",
		"providerPathIdentifier": "findDandy",
		"publicPath":             "/public/findDandy",
		"publicPathIdentifier":   "findDandy",
		"storagePath":            "/storage/findDandy",
		"storagePathIdentifier":  "findDandy",
		"type":                   "A.f8d6e0586b0a20c7.Dandy.NFT",
		"typeIdentifier":         "A.f8d6e0586b0a20c7.Dandy.NFT",
	})

	t.Run("Should be able to registry Dandy Token and get it", func(t *testing.T) {

		result := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("A.f8d6e0586b0a20c7.Dandy.NFT")).
			RunReturnsInterface()

		danyTokenWant.Equal(t, result)
	})
	t.Run("Should be able to registry Dandy token and list it", func(t *testing.T) {
		result := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()

		danyTokenWant.Equal(t, result)

		result = otu.O.ScriptFromFile("getNFTInfoAll").RunReturnsJsonString()
		otu.AutoGoldRename("Should be able to registry Dandy token and list it", result)
	})

	t.Run("Should not be able to overrride an nft without removing it first", func(t *testing.T) {
		/* Should not be able to overrride an nft without removing it first */
		o.TransactionFromFile("adminSetNFTInfo_Dandy").
			SignProposeAndPayAs("find").
			Args(o.Arguments()).
			Test(t).
			AssertFailure("This NonFungibleToken Register already exist")
	})

	t.Run("Should be able to registry and remove Dandy token by Alias, as well as return nil on scripts", func(t *testing.T) {
		/* Should be removable by alias */
		otu.removeDandyInNFtRegistry("adminRemoveNFTInfoByAlias", "Dandy")

		aliasResult := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, nil, aliasResult)

		infoResult := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, nil, infoResult)
	})

	t.Run("Should be able to registry and remove Dandy token by Type Identifier, as well as return nil on scripts", func(t *testing.T) {
		/* Should be removable by Identifier */
		otu.registerDandyInNFTRegistry().
			removeDandyInNFtRegistry("adminRemoveNFTInfoByTypeIdentifier", "A.f8d6e0586b0a20c7.Dandy.NFT")

		aliasResult := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("A.f8d6e0586b0a20c7.Dandy.NFT")).
			RunReturnsInterface()
		assert.Equal(t, nil, aliasResult)

		infoResult := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, nil, infoResult)

	})

}
