package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestGas(t *testing.T) {

	t.Run("Test lookup.", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1").
			registerUserWithName("user1", "abcde").
			registerUserWithName("user1", "eeeee").
			registerUserWithName("user1", "aaaaaa").
			registerUserWithName("user1", "bbbbb").
			registerUserWithName("user1", "ccccc").
			registerUserWithName("user1", "ddddd")

		otu.O.Tx("devResolveName",
			WithSigner("user1"),
			WithArg("user", otu.O.Account("user1").Address().String()),
		).
			AssertDebugLog(t, otu.O.Address("user1")).
			AssertComputationLessThenOrEqual(t, 200)

	})

}
