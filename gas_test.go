package test_main

import (
	"testing"
)

func TestGas(t *testing.T) {

	// t.Run("Test reverse lookup.", func(t *testing.T) {
	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "user1").
	// 		registerUser("user1")
	// 		// registerUserWithName("user1", "abcde").
	// 		// registerUserWithName("user1", "eeeee").
	// 		// registerUserWithName("user1", "aaaaaa").
	// 		// registerUserWithName("user1", "bbbbb").
	// 		// registerUserWithName("user1", "ccccc").
	// 		// registerUserWithName("user1", "ddddd").
	// 		// setFindName("user1", "")

	// 	result := otu.O.TransactionFromFile("test").
	// 		SignProposeAndPayAs("user1").
	// 		Args(otu.O.Arguments().
	// 			Account("user1")).
	// 		Test(t).
	// 		AssertSuccess()
	// 	result.AssertDebugLog("user1").
	// 		AssertComputationLessThenOrEqual(48)

	// })

	t.Run("Test lookup.", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1")
			// registerUserWithName("user1", "abcde").
			// registerUserWithName("user1", "eeeee").
			// registerUserWithName("user1", "aaaaaa").
			// registerUserWithName("user1", "bbbbb").
			// registerUserWithName("user1", "ccccc").
			// registerUserWithName("user1", "ddddd").
			// setFindName("user1", "")

		result := otu.O.TransactionFromFile("devResolveName").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("179b6b1cb6755e31")).
			Test(t).
			AssertSuccess()
		result.AssertDebugLog("0x179b6b1cb6755e31").
			AssertComputationLessThenOrEqual(200)

	})

}
