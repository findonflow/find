package test_main

import (
	"testing"

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
		result := o.ScriptFromFile("getNFTInfoByTypeIdentifier").
			Args(o.Arguments().String("A.f8d6e0586b0a20c7.Dandy.Collection")).
			RunReturnsInterface()

		expected := map[string]interface{}{
			"address":        "0xf8d6e0586b0a20c7",
			"allowedFTTypes": "",
			"icon":           "",
			"name":           "Dandy",
			"providerPath":   "/private/findDandy",
			"publicPath":     "/public/findDandy",
			"storagePath":    "/storage/findDandy",
			"type":           "Type<A.f8d6e0586b0a20c7.Dandy.Collection>()",
			"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.Collection",
		}
		assert.Equal(t, expected, result)

	})

	t.Run("Should be able to registry Dandy Token and get it by alias", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry()

		o := otu.O
		result := o.ScriptFromFile("getNFTInfoByAlias").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()

		expected := map[string]interface{}{
			"address":        "0xf8d6e0586b0a20c7",
			"allowedFTTypes": "",
			"icon":           "",
			"name":           "Dandy",
			"providerPath":   "/private/findDandy",
			"publicPath":     "/public/findDandy",
			"storagePath":    "/storage/findDandy",
			"type":           "Type<A.f8d6e0586b0a20c7.Dandy.Collection>()",
			"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.Collection",
		}
		assert.Equal(t, expected, result)

	})

	t.Run("Should be able to registry Dandy token and list it", func(t *testing.T) {
		expected := `
		{
			"A.f8d6e0586b0a20c7.Dandy.Collection": {
				"address":"0xf8d6e0586b0a20c7",
				"allowedFTTypes":"",
				"icon":"",
				"name":"Dandy",
				"providerPath":"/private/findDandy",
				"publicPath":"/public/findDandy",
				"storagePath":"/storage/findDandy",
				"type": "Type\u003cA.f8d6e0586b0a20c7.Dandy.Collection\u003e()",
				"typeIdentifier":"A.f8d6e0586b0a20c7.Dandy.Collection"}
		}
		`

		NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry().
			scriptEqualToJson("getNFTInfoAll", expected)

	})

	t.Run("Should not be able to overrride an nft without removing it first", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry()

		o := otu.O
		o.TransactionFromFile("setNFTInfo_Dandy").
			SignProposeAndPayAs("find").
			Args(o.Arguments()).
			Test(t).
			AssertFailure("This NonFungibleToken Register already exist")
	})

	t.Run("Should be able to registry and remove Dandy token by Alias, as well as return nil on scripts", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry().
			removeDandyInNFtRegistry("removeNFTInfoByAlias", "Dandy")

		o := otu.O
		aliasResult := o.ScriptFromFile("getNFTInfoByAlias").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, "", aliasResult)

		infoResult := o.ScriptFromFile("getNFTInfoByAlias").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, "", infoResult)

	})

	t.Run("Should be able to registry and remove Dandy token by Type Identifier, as well as return nil on scripts", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerDandyInNFTRegistry().
			removeDandyInNFtRegistry("removeNFTInfoByTypeIdentifier", "A.f8d6e0586b0a20c7.Dandy.Collection")

		o := otu.O
		aliasResult := o.ScriptFromFile("getNFTInfoByTypeIdentifier").
			Args(o.Arguments().String("A.f8d6e0586b0a20c7.Dandy.Collection")).
			RunReturnsInterface()
		assert.Equal(t, "", aliasResult)

		infoResult := o.ScriptFromFile("getNFTInfoByAlias").
			Args(o.Arguments().String("Dandy")).
			RunReturnsInterface()
		assert.Equal(t, "", infoResult)

	})

}
