package main

import (
	"testing"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	"github.com/onflow/cadence"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestFin(t *testing.T) {
	g := gwtf.NewTestingEmulator()

	t.Run("Should be able to register a tag", func(t *testing.T) {

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
			UFix64Argument("60.0"). //duration of a lease, this is for testing
			Test(t).AssertSuccess().AssertNoEvents()

		tags := cadence.NewArray([]cadence.Value{cadence.String("tag1"), cadence.String("tag2")})

		g.TransactionFromFile("create_profile").
			SignProposeAndPayAs("user1").
			StringArgument("User1").
			StringArgument("This is user1").
			Argument(tags).
			BooleanArgument(true).
			Test(t).
			AssertSuccess().
			AssertEmitEvent(gwtf.NewTestEvent("A.f8d6e0586b0a20c7.Profile.Verification", map[string]interface{}{
				"account": "0x179b6b1cb6755e31",
				"message": "test",
			}))

		g.TransactionFromFile("mint_fusd").
			SignProposeAndPayAsService().
			AccountArgument("user1").
			UFix64Argument("100.0").
			Test(t).
			AssertSuccess().
			AssertEventCount(3)

		g.TransactionFromFile("register").
			SignProposeAndPayAs("user1").
			StringArgument("user1").
			Test(t).
			AssertSuccess().
			AssertEventCount(3)

	})

}
