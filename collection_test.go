package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCollectionScripts(t *testing.T) {

	t.Run("Should be able to mint Dandy and then get it by script", func(t *testing.T) {

		otu := NewOverflowTest(t)
		//nameAddress := otu.accountAddress("user1")
		otu.setupFIND().
			setupDandy("user1").
			registerDandyInNFTRegistry().
			mintThreeExampleDandies()

		o := otu.O
		result := o.ScriptFromFile("collections").
			Args(o.Arguments().Address("user1")).
			RunReturnsInterface()

		expected := map[string]interface{}{"collections": map[string]interface{}{},
			"curatedCollections": map[string]interface{}{},
			"items": map[string]interface{}{"Dandy80": map[string]interface{}{"contentType": "image",
				"id":        "80",
				"image":     "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
				"listPrice": "",
				"listToken": "",
				"name":      "Neo Motorcycle 1 of 3",
				"rarity":    "",
				"url":       "find.xyz"},
				"Dandy81": map[string]interface{}{"contentType": "image", "id": "81", "image": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp", "listPrice": "", "listToken": "", "name": "Neo Motorcycle 2 of 3", "rarity": "", "url": "find.xyz"},
				"Dandy82": map[string]interface{}{"contentType": "image", "id": "82", "image": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp", "listPrice": "", "listToken": "", "name": "Neo Motorcycle 3 of 3", "rarity": "", "url": "find.xyz"}}}
		assert.Equal(t, expected, result)

	})

	// t.Run("Should be able to mint Dandy and then get it by script", func(t *testing.T) {

	// 	otu := NewOverflowTest(t)
	// 	//nameAddress := otu.accountAddress("user1")
	// 	otu.setupFIND().
	// 		setupDandy("user1").
	// 		registerDandyInNFTRegistry().
	// 		mintThreeExampleDandies()

	// 	o := otu.O
	// 	result, _ := o.ScriptFromFile("collections").
	// 		Args(o.Arguments().Address("user1")).
	// 		RunReturns()
	// 	fmt.Println(result)
	// 	expected := map[string]interface{}{}
	// 	assert.Equal(t, expected, result)

	// })

}
