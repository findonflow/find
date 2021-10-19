package test_main

import (
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestFIND(t *testing.T) {

	t.Run("Should be able to register a name", func(t *testing.T) {
		NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			registerUser("user1")
	})

	t.Run("Should get error if you try to register a name and dont have enough money", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("5.0", "user1")

		gt.GWTF.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("usr").
			Test(t).
			AssertFailure("Amount withdrawn must be less than or equal than the balance of the Vault")

	})

	t.Run("Should get error if you try to register a name that is too short", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("5.0", "user1")

		gt.GWTF.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("ur").
			Test(t).
			AssertFailure("A FIND name has to be minimum 3 letters long")

	})

	t.Run("Should get error if you try to register a name that is already claimed", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("10.0", "user1").
			registerUser("user1")

		gt.GWTF.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertFailure("Name already registered")

	})

	t.Run("Should allow registering a lease after it is freed", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			registerUser("user1")

		gt.expireLease().tickClock("2.0")

		gt.GWTF.TransactionFromFile("status").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).AssertFailure("locked")

		gt.expireLease()
		gt.registerUser("user1")
	})

	t.Run("Should be able to lookup address", func(t *testing.T) {

		NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			registerUser("user1").
			assertLookupAddress("0x179b6b1cb6755e31")
	})

	t.Run("Should not be able to lookup lease after expired", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			registerUser("user1").
			expireLease().
			tickClock("2.0")

		value := gt.GWTF.ScriptFromFile("status").StringArgument("user1").RunReturnsInterface()
		assert.Equal(t, "", value)

	})

	t.Run("Should be able to send ft to another name", func(t *testing.T) {

		gt := NewGWTFTest(t).
			setupFIND().
			createUser("100.0", "user1").
			createUser("100.0", "user2").
			registerUser("user1")

		gt.GWTF.TransactionFromFile("send").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
				"to":     "0x179b6b1cb6755e31",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensWithdrawn", map[string]interface{}{
				"amount": "5.00000000",
				"from":   "0xf3fcd2c1a78f5eee",
			}))

	})
}
