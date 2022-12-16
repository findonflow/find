package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestRelatedAccounts(t *testing.T) {

	otu := NewOverflowTest(t)

	otu.O.Tx("devsetupRelatedAccount",
		WithSigner("user1"),
	).
		AssertSuccess(t)

	t.Run("Should be able to get identifier", func(t *testing.T) {

		otu.O.Script("devgetRelatedAccountIdentifier",
			WithArg("user", "user1"),
			WithArg("name", "Blocto"),
			WithArg("network", "ETH"),
			WithArg("address", "0x1"),
		).
			AssertWant(t, autogold.Want("ETH_Blocto_0x1", "ETH_Blocto_0x1"))
	})

	t.Run("Should be able to add wallet", func(t *testing.T) {
		otu.addRelatedAccount("user1", "Blocto", "ETH", "0x1")
		otu.addRelatedAccount("user1", "Blocto", "ETH", "0x2")
		otu.addRelatedAccount("user1", "Blocto", "ETH", "0x4")
		otu.addRelatedAccount("user1", "Find", "ETH", "0x3")
		otu.addRelatedAccount("user1", "Find", "ETH", "0x5")
	})

	t.Run("Should be able to add flow wallet", func(t *testing.T) {
		otu.addRelatedAccount("user1", "Blocto", "Flow", "user2")
		otu.addRelatedAccount("user1", "Blocto", "Flow", "user3")
		otu.addRelatedAccount("user1", "Find", "Flow", "find")

	})

	t.Run("Should be able to get Related wallet in network", func(t *testing.T) {

		res := otu.O.Script("devgetRelatedAccounts",
			WithArg("user", "user1"),
			WithArg("network", "ETH"),
		).
			AssertWant(t, autogold.Want("devgetRelatedAccounts : ETH", map[string]interface{}{"ETH_Blocto": []interface{}{"0x1", "0x2", "0x4"}, "ETH_Find": []interface{}{"0x3", "0x5"}}))
		assert.NoError(t, res.Err)
	})

	t.Run("Should be able to get Related wallet in Flow", func(t *testing.T) {

		res := otu.O.Script("devgetRelatedFlowAccounts",
			WithArg("user", "user1"),
		).
			AssertWant(t, autogold.Want("devgetRelatedFlowAccounts : Flow", map[string]interface{}{"Flow_Blocto": []interface{}{otu.O.Address("user2"), otu.O.Address("user3")}, "Flow_Find": []interface{}{otu.O.Address("find")}}))
		assert.NoError(t, res.Err)
	})

	t.Run("Should be able to get all Related wallet in network", func(t *testing.T) {

		res := otu.O.Script("getAllRelatedAccounts",
			WithArg("user", "user1"),
		).
			AssertWant(t, autogold.Want("devgetAllRelatedFlowAccounts", map[string]interface{}{"ETH": map[string]interface{}{"ETH_Blocto": []interface{}{"0x1", "0x2", "0x4"}, "ETH_Find": []interface{}{"0x3", "0x5"}}, "Flow": map[string]interface{}{"Flow_Blocto": []interface{}{otu.O.Address("user2"), otu.O.Address("user3")}, "Flow_Find": []interface{}{otu.O.Address("find")}}}))
		assert.NoError(t, res.Err)
	})

	t.Run("Should be able to update wallet", func(t *testing.T) {
		otu.updateRelatedAccount("user1", "Blocto", "ETH", "0x1", "0x1000000")
	})

	t.Run("Should be able to get updated Related wallet in network", func(t *testing.T) {

		res := otu.O.Script("devgetRelatedAccounts",
			WithArg("user", "user1"),
			WithArg("network", "ETH"),
		).
			AssertWant(t, autogold.Want("devgetRelatedAccounts : ETH", map[string]interface{}{"ETH_Blocto": []interface{}{"0x2", "0x4", "0x1000000"}, "ETH_Find": []interface{}{"0x3", "0x5"}}))
		assert.NoError(t, res.Err)
	})

	t.Run("Should be able to update flow wallet", func(t *testing.T) {
		otu.updateRelatedAccount("user1", "Blocto", "Flow", "user3", "user1")
	})

	t.Run("Should be able to get updated Related wallet in Flow", func(t *testing.T) {

		res := otu.O.Script("devgetRelatedFlowAccounts",
			WithArg("user", "user1"),
		).
			AssertWant(t, autogold.Want("devgetRelatedFlowAccounts : Flow", map[string]interface{}{"Flow_Blocto": []interface{}{otu.O.Address("user2"), otu.O.Address("user1")}, "Flow_Find": []interface{}{otu.O.Address("find")}}))
		assert.NoError(t, res.Err)
	})

	t.Run("Should be able to remove wallet", func(t *testing.T) {
		otu.removeRelatedAccount("user1", "Blocto", "ETH", "0x1000000")
	})

	t.Run("Should be able to get updated Related wallet in network", func(t *testing.T) {

		res := otu.O.Script("devgetRelatedAccounts",
			WithArg("user", "user1"),
			WithArg("network", "ETH"),
		).
			AssertWant(t, autogold.Want("devgetRelatedAccounts : ETH", map[string]interface{}{"ETH_Blocto": []interface{}{"0x2", "0x4"}, "ETH_Find": []interface{}{"0x3", "0x5"}}))
		assert.NoError(t, res.Err)
	})

	t.Run("Should be able to remove flow wallet", func(t *testing.T) {
		otu.removeRelatedAccount("user1", "Blocto", "Flow", "user1")
	})

	t.Run("Should be able to get updated Related wallet in Flow", func(t *testing.T) {

		res := otu.O.Script("devgetRelatedFlowAccounts",
			WithArg("user", "user1"),
		).
			AssertWant(t, autogold.Want("devgetRelatedFlowAccounts : Flow", map[string]interface{}{"Flow_Blocto": []interface{}{otu.O.Address("user2")}, "Flow_Find": []interface{}{otu.O.Address("find")}}))
		assert.NoError(t, res.Err)
	})

	type TestCases struct {
		network string
		address string
		want    autogold.Value
	}

	testCases := []TestCases{
		{
			network: "Flow",
			address: otu.O.Address("user3"),
			want:    autogold.Want("user3 false", false),
		},
		{
			network: "Flow",
			address: otu.O.Address("user1"),
			want:    autogold.Want("user1 false", false),
		},
		{
			network: "Flow",
			address: otu.O.Address("user2"),
			want:    autogold.Want("user2 true", true),
		},
		{
			network: "ETH",
			address: "0x1000000",
			want:    autogold.Want("0x1000000 false", false),
		},
		{
			network: "ETH",
			address: "0x1",
			want:    autogold.Want("0x1 false", false),
		},
		{
			network: "ETH",
			address: "0x2",
			want:    autogold.Want("0x2 true", true),
		},
		{
			network: "Aptos",
			address: "0x1",
			want:    autogold.Want("Aptos false", false),
		},
	}

	for _, tc := range testCases {
		t.Run(fmt.Sprintf("Should be able to verify with related accounts on network, testCase : %s", tc.want.Name()), func(t *testing.T) {

			res := otu.O.Script("devgetVerifyRelatedAccounts",
				WithArg("user", "user1"),
				WithArg("network", tc.network),
				WithArg("address", tc.address),
			).
				AssertWant(t, tc.want)
			assert.NoError(t, res.Err)

		})
	}

}
 