package test_main

import (
	"testing"

	"github.com/bjartek/overflow/overflow"
	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestFIND(t *testing.T) {

	t.Run("Should be able to register a name", func(t *testing.T) {
		NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1")
	})

	t.Run("Should get error if you try to register a name and dont have enough money", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(30.0, "user1")

		otu.O.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("usr").UFix64(500.0)).
			Test(t).
			AssertFailure("Amount withdrawn must be less than or equal than the balance of the Vault")

	})

	t.Run("Should get error if you try to register a name that is too short", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(30.0, "user1")

		otu.O.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("ur").UFix64(5.0)).
			Test(t).
			AssertFailure("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")

	})

	t.Run("Should get error if you try to register a name that is already claimed", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(30.0, "user1").
			registerUser("user1")

		otu.O.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("user1").UFix64(5.0)).
			Test(t).
			AssertFailure("Name already registered")

	})

	t.Run("Should allow registering a lease after it is freed", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1")

		otu.expireLease().tickClock(2.0)

		otu.O.Transaction(`
		import FIND from "../contracts/FIND.cdc"

		transaction(name: String) {

		    prepare(account: AuthAccount) {
		        let status=FIND.status(name)
						if status.status == FIND.LeaseStatus.LOCKED {
							panic("locked")
						}
						if status.status == FIND.LeaseStatus.FREE {
							panic("free")
						}
		    }
		}
		`).
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("user1")).
			Test(t).AssertFailure("locked")

		otu.expireLease()
		otu.registerUser("user1")
	})

	t.Run("Should be able to lookup address", func(t *testing.T) {

		NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1").
			assertLookupAddress("user1", "0x179b6b1cb6755e31")
	})

	t.Run("Should not be able to lookup lease after expired", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1").
			expireLease().
			tickClock(2.0)

		value := otu.O.ScriptFromFile("status").Args(otu.O.Arguments().String("user1")).RunReturnsInterface()
		assert.Equal(t, "", value)

	})

	t.Run("Admin should be able to register without paying FUSD", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(10.0, "find")

		otu.O.TransactionFromFile("registerAdmin").
			SignProposeAndPayAs("find").
			Args(otu.O.Arguments().StringArray("find-admin").Account("find")).
			Test(otu.T).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Register", map[string]interface{}{
				"name": "find-admin",
			}))

	})

	t.Run("Should be able to send lease to another name", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2")

		otu.O.TransactionFromFile("moveNameToName").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("user1").String("user2")).
			Test(t).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Moved", map[string]interface{}{
				"name": "user1",
			}))
	})

	t.Run("Should be able to register related account and remove it", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1")

		otu.O.TransactionFromFile("setRelatedAccount").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("dapper").Account("user2")).
			Test(t).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.RelatedAccounts.RelatedFlowAccountAdded", map[string]interface{}{
				"name":    "dapper",
				"address": "0x179b6b1cb6755e31",
				"related": "0xf3fcd2c1a78f5eee",
			}))

		value := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		assert.Contains(t, value, `"dapper": "0xf3fcd2c1a78f5eee"`)

		otu.O.TransactionFromFile("removeRelatedAccount").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("dapper")).
			Test(t).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.RelatedAccounts.RelatedFlowAccountRemoved", map[string]interface{}{
				"name":    "dapper",
				"address": "0x179b6b1cb6755e31",
				"related": "0xf3fcd2c1a78f5eee",
			}))

		value = otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		assert.NotContains(t, value, `"dapper": "0xf3fcd2c1a78f5eee"`)

	})

	t.Run("Should be able to set private mode", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1")

		otu.O.TransactionFromFile("setPrivateMode").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().Boolean(true)).
			Test(t).AssertSuccess()

		value := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		assert.Contains(t, value, `"privateMode": "true"`)

		otu.O.TransactionFromFile("setPrivateMode").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().Boolean(false)).
			Test(t).AssertSuccess()

		value = otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		assert.Contains(t, value, `"privateMode": "false"`)

	})

}
