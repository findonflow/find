package test_main

import (
	"testing"

	. "github.com/bjartek/overflow/v2"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestEntitlments(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	ot.Run(t, "Should not be able to change the name of another user", func(t *testing.T) {
		res := otu.O.Tx("devsetProfileNameError",
			WithSigner("user2"),
			WithArg("address", "user1"),
			WithArg("newName", "badUser"),
		)
		res.AssertFailure(t, "function requires `Owner` authorization, but reference is unauthorized")
	})
}
