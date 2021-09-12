package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
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
		//TODO: Give a better error message here?

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

		//TODO: test with more premutations here
		//do i need this now?
		gt.GWTF.TransactionFromFile("janitor").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Locked", map[string]interface{}{
				"lockedUntil": "39312003.00000000",
				"name":        "user1",
			}))

		gt.expireLease()

		gt.registerUserTransaction("user1").
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Freed", map[string]interface{}{
				"name":          "user1",
				"previousOwner": "0x179b6b1cb6755e31",
			}))
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

func registerUser(g *gwtf.GoWithTheFlow, t *testing.T, name string) {

	g.TransactionFromFile("register").
		SignProposeAndPayAs(name).
		StringArgument(name).
		Test(t).
		AssertSuccess().
		AssertEventCount(3)
}

func createUser(g *gwtf.GoWithTheFlow, t *testing.T, fusd string, name string) {
	names := cadence.NewArray([]cadence.Value{cadence.String("name1"), cadence.String("name2")})

	g.TransactionFromFile("create_profile").
		SignProposeAndPayAs(name).
		StringArgument(name).
		StringArgument("This is a user").
		Argument(names).
		BooleanArgument(true).
		Test(t).
		AssertSuccess()

	g.TransactionFromFile("mint_fusd").
		SignProposeAndPayAsService().
		AccountArgument(name).
		UFix64Argument(fusd).
		Test(t).
		AssertSuccess().
		AssertEventCount(3)
}

func setupFIND(g *gwtf.GoWithTheFlow, t *testing.T) {
	//first step create the adminClient as the fin user

	g.TransactionFromFile("setup_fin_1_create_client").
		SignProposeAndPayAs("fin").
		Test(t).AssertSuccess().AssertNoEvents()

	//link in the server in the versus client
	g.TransactionFromFile("setup_fin_2_register_client").
		SignProposeAndPayAsService().
		AccountArgument("fin").
		Test(t).AssertSuccess().AssertNoEvents()

	//set up fin network as the fin user
	g.TransactionFromFile("setup_fin_3_create_network").
		SignProposeAndPayAs("fin").
		UFix64Argument(fmt.Sprintf("%f", leaseDurationFloat)).
		Test(t).AssertSuccess().AssertNoEvents()

	g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("1.0").Test(t).AssertSuccess()
}
