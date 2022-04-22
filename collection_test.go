package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCollectionScripts(t *testing.T) {

	t.Run("Should be able to mint Dandy and then get it by script", func(t *testing.T) {

		expected := `
		 {
			 "collections":  {},
			"curatedCollections":  {},
				 "items":   {
					 "Dandy80":   {
					 	"contentType": "image",
					 	"id":  "80",
					 	"image":  "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					 	"listPrice":  "",
					 	"listToken":  "",
					 	"name":  "Neo Motorcycle 1 of 3",
					 	"rarity":  "",
					 	"url": "find.xyz"
					 	 },
					 "Dandy81":  {
						 "contentType":  "image",
						 "id":  "81",
						 "image":  "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						 "listPrice":  "",
						"listToken":  "",
						"name":  "Neo Motorcycle 2 of 3",
						 "rarity":  "",
						 "url":  "find.xyz"
						  },
					 "Dandy82":   {
						 "contentType":  "image",
						 "id":  "82",
						 "image":  "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						 "listPrice":  "",
						 "listToken":  "",
						 "name":  "Neo Motorcycle 3 of 3",
						 "rarity":  "",
						 "url": "find.xyz"}
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
}
