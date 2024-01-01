package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestRelatedAccounts(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	ot.Run(t, "Should be able to get identifier", func(t *testing.T) {
		otu.addRelatedAccount("user1", "Blocto", "ETH", "0x1")

		otu.O.Script("devgetRelatedAccountIdentifier",
			WithArg("user", "user1"),
			WithArg("name", "Blocto"),
			WithArg("network", "ETH"),
			WithArg("address", "0x1"),
		).
			AssertWant(t, autogold.Want("ETH_Blocto_0x1", "ETH_Blocto_0x1"))
	})

	ot.Run(t, "Should be able to get Related wallet in network", func(t *testing.T) {
		otu.addRelatedAccount("user1", "Blocto", "ETH", "0x1")
		res := otu.O.Script("devgetRelatedAccounts",
			WithArg("user", "user1"),
			WithArg("network", "ETH"),
		).AssertWant(t, autogold.Want("devgetRelatedAccounts : ETH", map[string]interface{}{"ETH_Blocto": []interface{}{"0x1"}}))
		assert.NoError(t, res.Err)
	})

	ot.Run(t, "Should be able to get Related wallet in Flow", func(t *testing.T) {
		otu.addRelatedAccount("user1", "Blocto", "Flow", "user2")
		otu.addRelatedAccount("user1", "Blocto", "Flow", "user3")
		otu.addRelatedAccount("user1", "Find", "Flow", "find")

		res := otu.O.Script("devgetRelatedFlowAccounts",
			WithArg("user", "user1"),
		).
			AssertWant(t, autogold.Want("devgetRelatedFlowAccounts : Flow", map[string]interface{}{"Flow_Blocto": []interface{}{otu.O.Address("user2"), otu.O.Address("user3")}, "Flow_Find": []interface{}{otu.O.Address("find")}}))
		assert.NoError(t, res.Err)
	})

	ot.Run(t, "Should be able to get all Related wallet in network", func(t *testing.T) {
		otu.addRelatedAccount("user1", "Blocto", "ETH", "0x1")
		otu.addRelatedAccount("user1", "Blocto", "ETH", "0x2")
		otu.addRelatedAccount("user1", "Blocto", "ETH", "0x4")
		otu.addRelatedAccount("user1", "Find", "ETH", "0x3")
		otu.addRelatedAccount("user1", "Find", "ETH", "0x5")
		otu.addRelatedAccount("user1", "Blocto", "Flow", "user2")
		otu.addRelatedAccount("user1", "Blocto", "Flow", "user3")
		otu.addRelatedAccount("user1", "Find", "Flow", "find")

		res := otu.O.Script("getAllRelatedAccounts",
			WithArg("user", "user1"),
		).
			AssertWant(t, autogold.Want("devgetAllRelatedFlowAccounts", map[string]interface{}{"ETH": map[string]interface{}{"ETH_Blocto": []interface{}{"0x1", "0x2", "0x4"}, "ETH_Find": []interface{}{"0x3", "0x5"}}, "Flow": map[string]interface{}{"Flow_Blocto": []interface{}{otu.O.Address("user2"), otu.O.Address("user3")}, "Flow_Find": []interface{}{otu.O.Address("find")}}}))
		assert.NoError(t, res.Err)
	})
	ot.Run(t, "Should be able to update wallet", func(t *testing.T) {
		otu.addRelatedAccount("user1", "Blocto", "ETH", "0x1")

		res := otu.O.Script("devgetRelatedAccounts",
			WithArg("user", "user1"),
			WithArg("network", "ETH"),
		).AssertWant(t, autogold.Want("devgetRelatedAccounts : ETH", map[string]interface{}{"ETH_Blocto": []interface{}{"0x1"}}))
		assert.NoError(t, res.Err)

		otu.updateRelatedAccount("user1", "Blocto", "ETH", "0x1", "0x1000000")

		res = otu.O.Script("devgetRelatedAccounts",
			WithArg("user", "user1"),
			WithArg("network", "ETH"),
		).AssertWant(t, autogold.Want("devgetRelatedAccounts : ETH", map[string]interface{}{"ETH_Blocto": []interface{}{"0x1000000"}}))
		assert.NoError(t, res.Err)
	})
}
