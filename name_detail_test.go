package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestNameDetailScript(t *testing.T) {

	t.Run("Should be able to direct offer on name for sale and get by Name Detail Script", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			listForSale("user1").
			directOffer("user2", "user1", 4.0).
			setProfile("user1").
			setProfile("user2").
			/* place bid on other names */
			listForAuction("user2").
			bid("user1", "user2", 8.0)

		otu.setUUID(300)

		otu.O.TransactionFromFile("setRelatedAccount").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("dapper").String("user2")).
			Test(t).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.RelatedAccounts.RelatedFlowAccountAdded", map[string]interface{}{
				"name":    "dapper",
				"address": "0x179b6b1cb6755e31",
				"related": "0xf3fcd2c1a78f5eee",
			}))

		actual := otu.O.ScriptFromFile("getNameDetails").
			Args(otu.O.Arguments().
				String("user1")).
			RunReturnsJsonString()

		autogold.Equal(t, actual)
	})

}
