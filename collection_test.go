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
			"collections": {
				"Dandy": [
					"Dandy88",
					"Dandy89",
					"Dandy87"
				]
			},
			"curatedCollections": {},
			"items": {
				"Dandy87": {
					"collection": "Dandy",
					"contentType": "image",
					"id": "87",
					"image": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"metadata": {},
					"name": "Neo Motorcycle 1 of 3",
					"rarity": "",
					"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"url": "find.xyz",
					"uuid": "87"
				},
				"Dandy88": {
					"collection": "Dandy",
					"contentType": "image",
					"id": "88",
					"image": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"metadata": {},
					"name": "Neo Motorcycle 2 of 3",
					"rarity": "",
					"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"url": "find.xyz",
					"uuid": "88"
				},
				"Dandy89": {
					"collection": "Dandy",
					"contentType": "image",
					"id": "89",
					"image": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"metadata": {},
					"name": "Neo Motorcycle 3 of 3",
					"rarity": "",
					"typeIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"url": "find.xyz",
					"uuid": "89"
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
		fmt.Println(result)
		assert.JSONEq(otu.T, expected, result)

	})

}
