package test_main

import (
	"fmt"
	"testing"

	"github.com/hexops/autogold"
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
		res := otu.O.ScriptFromFile("getNFTViews").Args(otu.O.Arguments().String("user1").String("Dandy").UInt64(id)).RunReturnsJsonString()

		result := otu.O.ScriptFromFile("getNFTView").Args(otu.O.Arguments().
			String("user1").
			String("Dandy").
			UInt64(id).
			String("A.f8d6e0586b0a20c7.MetadataViews.Display")).RunReturnsJsonString()

		urlResult := otu.O.ScriptFromFile("getNFTView").Args(otu.O.Arguments().
			String("user1").
			String("A.f8d6e0586b0a20c7.Dandy.NFT").
			UInt64(id).
			String("A.f8d6e0586b0a20c7.MetadataViews.ExternalURL")).RunReturnsJsonString()

		overallResult := fmt.Sprintf("%s%s%s", res, result, urlResult)
		autogold.Equal(t, overallResult)

	})
}
