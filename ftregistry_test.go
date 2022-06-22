package test_main

import (
	"testing"

	"github.com/bjartek/overflow/overflow"
	"github.com/stretchr/testify/assert"
)

func TestFTRegistry(t *testing.T) {

	t.Run("Should be able to registry flow token and get it", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerFTInFtRegistry("flow", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
				"alias":          "Flow",
				"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			})

		o := otu.O
		result := o.ScriptFromFile("getFTInfo").
			Args(o.Arguments().String("Flow")).
			RunReturnsJsonString()

		otu.AutoGold("by_alias", result)

		result = o.ScriptFromFile("getFTInfo").
			Args(o.Arguments().String("A.0ae53cb6e3f42a79.FlowToken.Vault")).
			RunReturnsJsonString()

		otu.AutoGold("by_identifier", result)

		/* Should not be able to overrride a ft without removing it first */
		o.TransactionFromFile("adminSetFTInfo_flow").
			SignProposeAndPayAs("find").
			Args(o.Arguments()).
			Test(t).
			AssertFailure("This FungibleToken Register already exist")

		/* Should be able to registry flow token, fusd token and get list from it */
		otu.registerFTInFtRegistry("fusd", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
			"alias":          "FUSD",
			"typeIdentifier": "A.f8d6e0586b0a20c7.FUSD.Vault",
		})

		result = otu.O.ScriptFromFile("getFTInfoAll").RunReturnsJsonString()
		otu.AutoGold("get_FUSD", result)

		/* Should be able to registry usdc token and get it */
		otu.registerFTInFtRegistry("usdc", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
			"alias":          "USDC",
			"typeIdentifier": "A.f8d6e0586b0a20c7.FiatToken.Vault",
		})

		result = o.ScriptFromFile("getFTInfo").
			Args(o.Arguments().String("A.f8d6e0586b0a20c7.FiatToken.Vault")).
			RunReturnsJsonString()

		otu.AutoGold("get_USDC", result)

		/* Should be able to send usdc to another name */
		otu.createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2")

		o.TransactionFromFile("sendFT").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("user1").
				UFix64(5.0).
				String("USDC").
				String("test").
				String("This is a message")).
			Test(t).AssertSuccess().
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FiatToken.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
				"to":     "0x179b6b1cb6755e31",
			})).
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FiatToken.TokensWithdrawn", map[string]interface{}{
				"amount": "5.00000000",
				"from":   "0xf3fcd2c1a78f5eee",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.FungibleTokenSent", map[string]interface{}{
				"from":      "0xf3fcd2c1a78f5eee",
				"fromName":  "user2",
				"toAddress": "0x179b6b1cb6755e31",
				"amount":    "5.00000000",
				"name":      "user1",
				"tag":       "test",
				"message":   "This is a message",
			}))

		/* Should be able to send fusd to another name */
		o.TransactionFromFile("sendFT").
			SignProposeAndPayAs("user2").
			Args(o.Arguments().
				String("user1").
				UFix64(5.0).
				String("FUSD").
				String("test").
				String("This is a message")).
			Test(t).AssertSuccess().
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
				"to":     "0x179b6b1cb6755e31",
			})).
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensWithdrawn", map[string]interface{}{
				"amount": "5.00000000",
				"from":   "0xf3fcd2c1a78f5eee",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.FungibleTokenSent", map[string]interface{}{
				"from":      "0xf3fcd2c1a78f5eee",
				"fromName":  "user2",
				"toAddress": "0x179b6b1cb6755e31",
				"amount":    "5.00000000",
				"name":      "user1",
				"tag":       "test",
				"message":   "This is a message",
			}))

		/* Should be able to send flow to another name */
		o.TransactionFromFile("sendFT").
			SignProposeAndPayAs("user2").
			Args(o.Arguments().
				String("user1").
				UFix64(5.0).
				String("Flow").
				String("test").
				String("This is a message")).
			Test(t).AssertSuccess().
			AssertEmitEvent(overflow.NewTestEvent("A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
				"to":     "0x179b6b1cb6755e31",
			})).
			AssertEmitEvent(overflow.NewTestEvent("A.0ae53cb6e3f42a79.FlowToken.TokensWithdrawn", map[string]interface{}{
				"amount": "5.00000000",
				"from":   "0xf3fcd2c1a78f5eee",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.FungibleTokenSent", map[string]interface{}{
				"from":      "0xf3fcd2c1a78f5eee",
				"fromName":  "user2",
				"toAddress": "0x179b6b1cb6755e31",
				"amount":    "5.00000000",
				"name":      "user1",
				"tag":       "test",
				"message":   "This is a message",
			}))

		/* Should be able to remove them */
		otu.removeFTInFtRegistry("adminRemoveFTInfoByAlias", "FUSD",
			"A.f8d6e0586b0a20c7.FTRegistry.FTInfoRemoved", map[string]interface{}{
				"alias":          "FUSD",
				"typeIdentifier": "A.f8d6e0586b0a20c7.FUSD.Vault",
			}).
			removeFTInFtRegistry("adminRemoveFTInfoByTypeIdentifier", "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"A.f8d6e0586b0a20c7.FTRegistry.FTInfoRemoved", map[string]interface{}{
					"alias":          "Flow",
					"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
				})

		aliasResult := o.ScriptFromFile("getFTInfo").
			Args(o.Arguments().String("A.f8d6e0586b0a20c7.FUSD.Vault")).
			RunReturnsInterface()
		assert.Equal(t, "", aliasResult)

		infoResult := o.ScriptFromFile("getFTInfo").
			Args(o.Arguments().String("Flow")).
			RunReturnsInterface()
		assert.Equal(t, "", infoResult)

	})
}
