package test_main

import (
	"testing"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestDandy(t *testing.T) {

	t.Run("Should be able to mint 3 dandy nfts", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1")

		otu.O.TransactionFromFile("buyAddon").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("user1").String("forge").UFix64(50.0)).
			Test(otu.T).
			AssertSuccess()

			//TOOD: assert events
		otu.O.TransactionFromFile("mintDandy").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("user1")).
			Test(otu.T).
			AssertSuccess().AssertEventCount(6)

		/*
			res := g.GWTF.ScriptFromFile("dandyViews").StringArgument("user1").UInt64Argument(23).RunReturnsJsonString()
			fmt.Println(res)
			assert.Equal(t, res, "")
		*/
	})
}
