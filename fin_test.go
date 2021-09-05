package main

import (
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

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

		createUser(g, t, "100.0", "user1")

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Register", map[string]interface{}{
				"expireAt": "31536001.00000000",
				"owner":    "0x179b6b1cb6755e31",
				"name":     "user1",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
				"to":     "0x1cf0e2f2f715450",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensWithdrawn", map[string]interface{}{
				"amount": "5.00000000",
				"from":   "0x179b6b1cb6755e31",
			}))
	})

	t.Run("Should get error if you try to register a name and dont have enough money", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

		createUser(g, t, "5.0", "user1")

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("usr").
			Test(t).
			AssertFailure("Amount withdrawn must be less than or equal than the balance of the Vault")

	})

	t.Run("Should get error if you try to register a name that is too short", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

		createUser(g, t, "5.0", "user1")

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("ur").
			Test(t).
			AssertFailure("A FIND name has to be minimum 3 letters long")

	})
	t.Run("Should get error if you try to register a name that is already claimed", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

		createUser(g, t, "10.0", "user1")

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess()

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertFailure("Tag already registered")

	})

	t.Run("Should allow registering a lease after it is freed", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

		createUser(g, t, "10.0", "user1")

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess()

		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument(leaseDuration).Test(t).AssertSuccess()
		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("2.0").Test(t).AssertSuccess()
		g.TransactionFromFile("status").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).AssertFailure("locked")

		//do i need this now?
		g.TransactionFromFile("update_status").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Locked", map[string]interface{}{
				"lockedUntil": "39312003.00000000",
				"name":        "user1",
			}))

		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument(leaseDuration).Test(t).AssertSuccess()

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Freed", map[string]interface{}{
				"name":          "user1",
				"previousOwner": "0x179b6b1cb6755e31",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Register", map[string]interface{}{
				"expireAt": "94608003.00000000",
				"owner":    "0x179b6b1cb6755e31",
				"name":     "user1",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
				"to":     "0x1cf0e2f2f715450",
			})).
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensWithdrawn", map[string]interface{}{
				"amount": "5.00000000",
				"from":   "0x179b6b1cb6755e31",
			}))

	})

	t.Run("Should be able to lookup address", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

		createUser(g, t, "10.0", "user1")

		registerUser(g, t, "user1")

		value := g.Script(`import FIND from "../contracts/FIND.cdc"
pub fun main(name: String) :  Address? {
    return FIND.lookupAddress(name)
}
		`).StringArgument("user1").RunReturnsInterface()
		assert.Equal(t, "0x179b6b1cb6755e31", value)

	})

	t.Run("Should not be able to lookup lease after expired", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

		createUser(g, t, "10.0", "user1")

		registerUser(g, t, "user1")

		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument(leaseDuration).Test(t).AssertSuccess()
		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("2.0").Test(t).AssertSuccess()

		value := g.ScriptFromFile("status").StringArgument("user1").RunReturnsInterface()
		assert.Equal(t, "", value)

	})

	t.Run("Should be able to send ft to another name", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIND(g, t)

		createUser(g, t, "10.0", "user1")
		createUser(g, t, "10.0", "user2")

		registerUser(g, t, "user1")

		g.TransactionFromFile("send").
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

//a year
const leaseDuration = "31536000.0"

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
		UFix64Argument(leaseDuration).
		Test(t).AssertSuccess().AssertNoEvents()

	g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("1.0").Test(t).AssertSuccess()
}
