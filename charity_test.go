package test_main

import (
	"testing"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestCharity(t *testing.T) {

	t.Run("Should be able to mint a charity nft", func(t *testing.T) {
		NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			setupCharity("user1").
			mintCharity("test", "https://test.png", "user1")
	})
}
