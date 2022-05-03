package test_main

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCollectionScripts(t *testing.T) {

	t.Run("Should be able to mint Dandy and then get it by script", func(t *testing.T) {

		expected := `
		 {
			 "collections":  {
				"Dandy" : ["Dandy81", "Dandy82", "Dandy80"]
			 },
			"curatedCollections":  {},
				 "items":   {
					 "Dandy80":   {
					 	"contentType": "image",
					 	"id":  "80",
						"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
						"uuid": "80",
					 	"image":  "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					 	"name":  "Neo Motorcycle 1 of 3",
					 	"rarity":  "",
					 	"url": "find.xyz",
						 "metadata": {},
						 "collection": "Dandy"
					 	 },
					 "Dandy81":  {
						 "contentType":  "image",
						 "id":  "81",
						 "typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
						 "uuid": "81",
						 "image":  "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						"name":  "Neo Motorcycle 2 of 3",
						 "rarity":  "",
						 "url":  "find.xyz",
						 "metadata": {},
						 "collection": "Dandy"
						  },
					 "Dandy82":   {
						 "contentType":  "image",
						 "id":  "82",
						 "typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
						 "uuid": "82",
						 "image":  "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						 "name":  "Neo Motorcycle 3 of 3",
						 "rarity":  "",
						 "url": "find.xyz",
						 "metadata": {},
						 "collection": "Dandy"
						}
				  }
			  }
		`

		otu := NewOverflowTest(t)
		otu.setupFIND().
			setupDandy("user1").
			registerDandyInNFTRegistry().
			mintThreeExampleDandies()

		result := otu.O.ScriptFromFile("collections").
			Args(otu.O.Arguments().Address("user1")).
			RunReturnsJsonString()
		assert.JSONEq(otu.T, expected, result)

	})

	t.Run("Should be able to mint Dandy and then get it by script Index", func(t *testing.T) {

		expected := `
		{"Dandy": ["81", "82", "80"]}
		`

		otu := NewOverflowTest(t)
		otu.setupFIND().
			setupDandy("user1").
			registerDandyInNFTRegistry().
			mintThreeExampleDandies()

		result := otu.O.ScriptFromFile("collectionIndex").
			Args(otu.O.Arguments().Address("user1")).
			RunReturnsJsonString()
		assert.JSONEq(otu.T, expected, result)

	})

	t.Run("Should be able to query the Dandies by resolve partial collection scripts", func(t *testing.T) {

		expected := `
		[{
			"collection": "Dandy",
			"contentType": "image",
			"id": "80",
			"image": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
			"metadata": {},
			"name": "Neo Motorcycle 1 of 3",
			"rarity": "",
			"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
			"url": "find.xyz",
			"uuid": "80"
		},
		{
			"collection": "Dandy",
			"contentType": "image",
			"id": "81",
			"image": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
			"metadata": {},
			"name": "Neo Motorcycle 2 of 3",
			"rarity": "",
			"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
			"url": "find.xyz",
			"uuid": "81"
		},
		{
			"collection": "Dandy",
			"contentType": "image",
			"id": "82",
			"image": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
			"metadata": {},
			"name": "Neo Motorcycle 3 of 3",
			"rarity": "",
			"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
			"url": "find.xyz",
			"uuid": "82"
		}]
		`

		otu := NewOverflowTest(t)
		otu.setupFIND().
			setupDandy("user1").
			registerDandyInNFTRegistry().
			mintThreeExampleDandies()

		result := otu.O.ScriptFromFile("resolvePartialCollection").
			Args(otu.O.Arguments().
				Address("user1").
				StringArray("Dandy", "Dandy", "Dandy").
				UInt64Array(80, 81, 82)).
			RunReturnsJsonString()

		fmt.Println(result)
		assert.JSONEq(otu.T, expected, result)

	})
}
