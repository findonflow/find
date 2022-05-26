package test_main

import (
	"testing"

	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestNFTRegistry(t *testing.T) {

	t.Run("Should be able to registry Dandy token", func(t *testing.T) {
		NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry()
	})

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

	})

	t.Run("Should be able to registry Dandy Token and get it by alias", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry()

		o := otu.O
		result := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
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

	})

	t.Run("Should be able to registry Dandy token and list it", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry()

		result := otu.O.ScriptFromFile("getNFTInfoAll").RunReturnsJsonString()
		autogold.Equal(t, result)
	})

	t.Run("Should not be able to overrride an nft without removing it first", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry()

		o := otu.O
		o.TransactionFromFile("adminSetNFTInfo_Dandy").
			SignProposeAndPayAs("find").
			Args(o.Arguments()).
			Test(t).
			AssertFailure("This NonFungibleToken Register already exist")
	})

	t.Run("Should be able to registry and remove Dandy token by Alias, as well as return nil on scripts", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry().
			removeDandyInNFtRegistry("adminRemoveNFTInfoByAlias", "Dandy")

		o := otu.O
		aliasResult := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, "", aliasResult)

		infoResult := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, "", infoResult)

	})

	t.Run("Should be able to registry and remove Dandy token by Type Identifier, as well as return nil on scripts", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry().
			removeDandyInNFtRegistry("adminRemoveNFTInfoByTypeIdentifier", "A.f8d6e0586b0a20c7.Dandy.NFT")

		o := otu.O
		aliasResult := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("A.f8d6e0586b0a20c7.Dandy.NFT")).
			RunReturnsInterface()
		assert.Equal(t, "", aliasResult)

		infoResult := o.ScriptFromFile("getNFTInfo").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, "", infoResult)

	})

}
