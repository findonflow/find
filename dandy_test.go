package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestDandy(t *testing.T) {

	t.Run("Should be able to mint 3 dandy nfts and display them", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1")

		dandyIds := otu.mintThreeExampleDandies()

		id := dandyIds[0]
		res := otu.O.ScriptFromFile("dandyViews").Args(otu.O.Arguments().String("user1").UInt64(id)).RunReturnsJsonString()
		assert.JSONEq(t, `[
			        	            	    "A.f8d6e0586b0a20c7.Dandy.MinterPlatform",
			        	            	    "String",
			        	            	    "A.f8d6e0586b0a20c7.MetadataViews.Display",
			        	            	    "AnyStruct{A.f8d6e0586b0a20c7.TypedMetadata.Royalty}",
																	"A.f8d6e0586b0a20c7.MetadataViews.HTTPFile",
			        	            	    "A.f8d6e0586b0a20c7.TypedMetadata.Editioned",
			        	            	    "A.f8d6e0586b0a20c7.Dandy.Royalties",
			        	            	    "A.f8d6e0586b0a20c7.TypedMetadata.CreativeWork"
			        	            	]`, res)

		display := `
	{
     "description": "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK",
     "name": "Neo Motorcycle 1 of 3",
     "thumbnail": {
         "url": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"
     }
 }
`
		result := otu.O.ScriptFromFile("dandy").Args(otu.O.Arguments().String("user1").UInt64(id).String("A.f8d6e0586b0a20c7.MetadataViews.Display")).RunReturnsJsonString()
		assert.JSONEq(t, display, result)
	})

	t.Run("Should be able to list a dandy for sale and buy it", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2")

		price := 10.0
		id := otu.mintThreeExampleDandies()[0]
		otu.listDandyForSale("user1", id, price)

		otu.buyDandyForSale("user2", "user1", id, price)

	})
}
