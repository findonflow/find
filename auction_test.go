package main

import (
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestAuction(t *testing.T) {

	t.Run("Should list a tag for sale", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIN(g, t, "5.0")

		createUser(g, t, "100.0", "user1")

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEventCount(3)

		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("1.0").Test(t).AssertSuccess()

		g.TransactionFromFile("sell").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEventName("A.f8d6e0586b0a20c7.FIN.ForSale")

		result := g.ScriptFromFile("lease_status").StringArgument("user1").AccountArgument("user1").RunReturnsInterface()
		dict, _ := result.(map[string]interface{})

		//		t.Logf("%v", dict)
		assert.Equal(t, dict["salePrice"], "10.00000000")
		assert.Equal(t, dict["tag"], "user1")
		assert.Equal(t, dict["latestBid"], "")
		assert.Equal(t, dict["latestBidBy"], "")

	})

	t.Run("Should not start auction if bid lower then sale price", func(t *testing.T) {

		g := gwtf.NewTestingEmulator()
		setupFIN(g, t, "5.0")

		createUser(g, t, "100.0", "user1")
		createUser(g, t, "100.0", "user2")

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user2").
			StringArgument("user2").
			Test(t).
			AssertSuccess().
			AssertEventCount(3)

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEventCount(3)

		g.TransactionFromFile("clock").SignProposeAndPayAs("fin").UFix64Argument("1.0").Test(t).AssertSuccess()

		g.TransactionFromFile("sell").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			UFix64Argument("10.0").
			Test(t).
			AssertSuccess().
			AssertEmitEventName("A.f8d6e0586b0a20c7.FIN.ForSale")

		g.TransactionFromFile("bid").
			SignProposeAndPayAs("user2").
			StringArgument("user1").
			UFix64Argument("5.0").
			Test(t).
			AssertSuccess()

		result := g.ScriptFromFile("lease_status").StringArgument("user1").AccountArgument("user1").RunReturnsInterface()
		dict, _ := result.(map[string]interface{})

		//		t.Logf("%v", dict)
		assert.Equal(t, dict["salePrice"], "10.00000000")
		assert.Equal(t, dict["tag"], "user1")
		assert.Equal(t, dict["latestBid"], "5.00000000")
		assert.Equal(t, dict["latestBidBy"], "0x")

	})

}
