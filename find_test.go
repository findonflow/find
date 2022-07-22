package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestFIND(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(100.0, "user1").
		registerUser("user1")

	t.Run("Should be able to register a name", func(t *testing.T) {

		result := otu.O.ScriptFromFile("getLeases").RunReturnsJsonString()

		autogold.Equal(t, result)
	})

	t.Run("Should get error if you try to register a name and dont have enough money", func(t *testing.T) {

		otu.O.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("usr").UFix64(500.0)).
			Test(t).
			AssertFailure("Amount withdrawn must be less than or equal than the balance of the Vault")

	})

	t.Run("Should get error if you try to register a name that is too short", func(t *testing.T) {

		otu.O.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("ur").UFix64(5.0)).
			Test(t).
			AssertFailure("A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")

	})

	t.Run("Should get error if you try to register a name that is already claimed", func(t *testing.T) {

		otu.O.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("user1").UFix64(5.0)).
			Test(t).
			AssertFailure("Name already registered")

	})

	t.Run("Should allow registering a lease after it is freed", func(t *testing.T) {

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
			Test(t).
			AssertFailure("locked").
			AssertComputationLessThenOrEqual(70)

		otu.expireLease()
		otu.registerUser("user1")
	})

	t.Run("Should be able to lookup address", func(t *testing.T) {

		otu.assertLookupAddress("user1", "0x179b6b1cb6755e31")
	})

	t.Run("Should not be able to lookup lease after expired", func(t *testing.T) {

		otu.expireLease().
			tickClock(2.0)

		value := otu.O.ScriptFromFile("getNameStatus").Args(otu.O.Arguments().String("user1")).RunReturnsInterface()
		assert.Equal(t, nil, value)

	})

	t.Run("Admin should be able to register without paying FUSD", func(t *testing.T) {

		otu.createUser(10.0, "find")

		otu.O.TransactionFromFile("adminRegisterName").
			SignProposeAndPayAs("find").
			Args(otu.O.Arguments().StringArray("find-admin").Account("find")).
			Test(otu.T).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Register", map[string]interface{}{
				"name": "find-admin",
			}))

	})

	otu = NewOverflowTest(t).
		setupFIND().
		createUser(100.0, "user1").
		registerUser("user1").
		createUser(100.0, "user2").
		registerUser("user2")

	t.Run("Should be able to send lease to another name", func(t *testing.T) {

		otu.O.TransactionFromFile("moveNameTO").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("user1").String("user2")).
			Test(t).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Moved", map[string]interface{}{
				"name": "user1",
			}))
	})

	t.Run("Should automatically set Find Name to empty if sender have none", func(t *testing.T) {

		value := otu.O.ScriptFromFile("getName").Args(otu.O.Arguments().Account("user1")).RunReturnsJsonString()
		fmt.Println(value)
		assert.Equal(t, "", value)

		otu.moveNameTo("user2", "user1", "user1")

	})

	t.Run("Should automatically set Find Name if sender have one", func(t *testing.T) {

		otu.registerUserWithName("user1", "name1").
			moveNameTo("user1", "user2", "user1")

		value := otu.O.ScriptFromFile("getName").Args(otu.O.Arguments().Account("user1")).RunReturnsJsonString()
		fmt.Println(value)
		assert.Equal(t, `"name1"`, value)

		otu.moveNameTo("user2", "user1", "user1")

	})

	otu = NewOverflowTest(t).
		setupFIND().
		createUser(100.0, "user1").
		registerUser("user1").
		createUser(100.0, "user2").
		registerUser("user2").
		setProfile("user2")

	t.Run("Should be able to register related account and remove it", func(t *testing.T) {

		otu.O.TransactionFromFile("setRelatedAccount").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("dapper").String("user2")).
			Test(t).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.RelatedAccounts.RelatedFlowAccountAdded", map[string]interface{}{
				"name":    "dapper",
				"address": "0x179b6b1cb6755e31",
				"related": "0xf3fcd2c1a78f5eee",
			}))

		value := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		fmt.Println(value)
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

		otu.O.TransactionFromFile("setPrivateMode").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().Boolean(true)).
			Test(t).AssertSuccess()

		value := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()

		assert.Contains(t, value, `"privateMode": true`)

		otu.O.TransactionFromFile("setPrivateMode").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().Boolean(false)).
			Test(t).AssertSuccess()

		//TEST: fix this later, to brittle
		value = otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()
		assert.Contains(t, value, `"privateMode": false`)

	})

	t.Run("Should be able to getStatus of new user", func(t *testing.T) {

		nameAddress := otu.accountAddress("user3")
		value := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String(nameAddress)).RunReturnsJsonString()
		autogold.Equal(t, value)

	})

	t.Run("If a user holds an invalid find name, get status should not return it", func(t *testing.T) {

		nameAddress := otu.accountAddress("user2")
		otu.moveNameTo("user2", "user1", "user2")
		value := otu.O.ScriptFromFile("getStatus").Args(otu.O.Arguments().String(nameAddress)).RunReturnsJsonString()
		autogold.Equal(t, value)

	})

	t.Run("Should be able to create and edit the social link", func(t *testing.T) {

		otu = NewOverflowTest(t).
			setupFIND().
			createUser(30.0, "user1").
			registerUser("user1").
			createUser(30.0, "user2").
			registerUser("user2")

		result := otu.O.TransactionFromFile("editProfile").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("user1").
				String("This is description").
				String("This is avatar").
				StringArray("This is tag").
				Boolean(true).
				StringMap(map[string]string{"CryptoTwitter": "0xBjartek", "FindTwitter": "find"}).
				StringMap(map[string]string{"CryptoTwitter": "Twitter", "FindTwitter": "Twitter"}).
				StringMap(map[string]string{"CryptoTwitter": "https://twitter.com/0xBjartek", "FindTwitter": "https://twitter.com/findonflow"}).
				StringArray()).
			Test(t).
			AssertSuccess()

		otu.AutoGold("first_edit", result.Events)

		profile := otu.O.ScriptFromFile("getProfile").
			Args(otu.O.Arguments().
				String("user1")).
			RunReturnsJsonString()

		otu.AutoGold("full_links", profile)

		// Remove find links
		result2 := otu.O.TransactionFromFile("editProfile").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("user1").
				String("This is description").
				String("This is avatar").
				StringArray("This is tag").
				Boolean(true).
				StringMap(map[string]string{}).
				StringMap(map[string]string{}).
				StringMap(map[string]string{}).
				StringArray("FindTwitter")).
			Test(t).
			AssertSuccess()

		otu.AutoGold("second_edit", result2.Events)

		profile = otu.O.ScriptFromFile("getProfile").Args(otu.O.Arguments().String("user1")).RunReturnsJsonString()

		otu.AutoGold("link_removed", profile)
	})

	t.Run("Should be able to buy addons that are on Network", func(t *testing.T) {

		user := "user1"
		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, user).
			createUser(100.0, "user2").
			setProfile(user).
			setProfile("user2").
			registerUser(user).
			registerUser("user2")

		otu.O.TransactionFromFile("buyAddon").
			SignProposeAndPayAs(user).
			Args(otu.O.Arguments().
				String(user).
				String("forge").
				UFix64(50.0)).
			Test(otu.T).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.AddonActivated", map[string]interface{}{
				"name":  user,
				"addon": "forge",
			}))

		/* Should not be able to buy addons with wrong balance */
		otu.O.TransactionFromFile("buyAddon").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("user2").
				String("forge").
				UFix64(10.0)).
			Test(otu.T).
			AssertFailure("Expect 50.00000000 FUSD for forge addon")

		/* Should not be able to buy addons that does not exist */
		otu.O.TransactionFromFile("buyAddon").
			SignProposeAndPayAs(user).
			Args(otu.O.Arguments().
				String(user).
				String("dandy").
				UFix64(10.0)).
			Test(otu.T).
			AssertFailure("This addon is not available.")

	})

	t.Run("Should be able to fund users with profile but without find name", func(t *testing.T) {

		user := "user1"
		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, user).
			createUser(100.0, "user2").
			setProfile(user).
			setProfile("user2").
			registerUser(user).
			registerFtInRegistry()

		user2 := otu.accountAddress("user2")

		otu.O.Tx("sendFT",
			overflow.SignProposeAndPayAs(user),
			overflow.Arg("name", user2),
			overflow.Arg("amount", 10.0),
			overflow.Arg("ftAliasOrIdentifier", "Flow"),
			overflow.Arg("tag", `""`),
			overflow.Arg("message", `""`),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FungibleTokenSent")

		otu.O.Tx("sendFT",
			overflow.SignProposeAndPayAs("user2"),
			overflow.Arg("name", user),
			overflow.Arg("amount", 10.0),
			overflow.Arg("ftAliasOrIdentifier", "Flow"),
			overflow.Arg("tag", `""`),
			overflow.Arg("message", `""`),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FungibleTokenSent")

	})

}
