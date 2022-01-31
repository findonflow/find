package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestDandy(t *testing.T) {

	t.Run("Should be able to mint 3 dandy nfts", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1").
			buyForge("user1")

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
	})
}
