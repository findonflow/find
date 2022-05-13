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
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFtInRegistry()
		dandyIds := otu.mintThreeExampleDandies()

		id := dandyIds[0]
		res := otu.O.ScriptFromFile("dandyViews").Args(otu.O.Arguments().String("user1").UInt64(id)).RunReturnsJsonString()
		assert.JSONEq(t, `[
						        	            	    "A.f8d6e0586b0a20c7.Dandy.MinterPlatform",
			        	            	          "A.f8d6e0586b0a20c7.FindViews.Nounce",
																				"A.f8d6e0586b0a20c7.FindViews.Grouping",
						        	            	    "String",
						        	            	    "A.f8d6e0586b0a20c7.MetadataViews.Display",
					        	            	      "A.f8d6e0586b0a20c7.MetadataViews.Royalties",
																				"A.f8d6e0586b0a20c7.MetadataViews.ExternalURL",
																				"A.f8d6e0586b0a20c7.FindViews.SerialNumber",
																				"A.f8d6e0586b0a20c7.MetadataViews.HTTPFile",
																				"A.f8d6e0586b0a20c7.FindViews.CreativeWork"
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

		result := otu.O.ScriptFromFile("view").Args(otu.O.Arguments().
			Account("user1").
			String("findDandy").
			UInt64(id).
			String("A.f8d6e0586b0a20c7.MetadataViews.Display")).RunReturnsJsonString()
		assert.JSONEq(t, display, result)

		externalUrl := `
{ "url" : "https://find.xyz/collection/user1/dandy/103"}

`
		urlResult := otu.O.ScriptFromFile("view").Args(otu.O.Arguments().
			Account("user1").
			String("findDandy").
			UInt64(id).
			String("A.f8d6e0586b0a20c7.MetadataViews.ExternalURL")).RunReturnsJsonString()
		assert.JSONEq(t, externalUrl, urlResult)

	})
}
