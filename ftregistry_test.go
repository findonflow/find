package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestFTRegistry(t *testing.T) {

	t.Run("Should be able to registry flow token", func(t *testing.T) {
		NewOverflowTest(t).
			setupFIND().
			registerFlowInFtRegistry()
	})

	t.Run("Should be able to registry flow token and get it", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerFlowInFtRegistry()

		o := otu.O
		result := o.ScriptFromFile("getFTInfoByTypeIdentifier").
			Args(o.Arguments().String("A.0ae53cb6e3f42a79.FlowToken.Vault")).
			RunReturnsInterface()

		expected := map[string]interface{}{
			"alias":          "Flow",
			"balancePath":    "/public/flowTokenBalance",
			"icon":           "",
			"receiverPath":   "/public/flowTokenReceiver",
			"type":           "Type<A.0ae53cb6e3f42a79.FlowToken.Vault>()",
			"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			"vaultPath":      "/storage/flowTokenVault",
		}
		assert.Equal(t, expected, result)

	})

	t.Run("Should be able to registry flow token and get it by alias", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerFlowInFtRegistry()

		o := otu.O
		result := o.ScriptFromFile("getFTInfoByAlias").
			Args(o.Arguments().String("Flow")).
			RunReturnsInterface()

		expected := map[string]interface{}{
			"alias":          "Flow",
			"balancePath":    "/public/flowTokenBalance",
			"icon":           "",
			"receiverPath":   "/public/flowTokenReceiver",
			"type":           "Type<A.0ae53cb6e3f42a79.FlowToken.Vault>()",
			"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			"vaultPath":      "/storage/flowTokenVault",
		}
		assert.Equal(t, expected, result)

	})
	t.Run("Should be able to registry flow token and list it", func(t *testing.T) {
		expected := `
{
    "A.0ae53cb6e3f42a79.FlowToken.Vault": {
        "alias": "Flow",
        "balancePath": "/public/flowTokenBalance",
        "icon": "",
        "receiverPath": "/public/flowTokenReceiver",
        "type": "Type\u003cA.0ae53cb6e3f42a79.FlowToken.Vault\u003e()",
        "typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
        "vaultPath": "/storage/flowTokenVault"
    }
}
`
		NewOverflowTest(t).
			setupFIND().
			registerFlowInFtRegistry().
			scriptEqualToJson("getFTInfoAll", expected)

	})

	t.Run("Should not be able to overrride a ft without removing it first", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerFlowInFtRegistry()

		o := otu.O
		o.TransactionFromFile("setFTInfo_flow").
			SignProposeAndPayAs("find").
			Args(o.Arguments()).
			Test(t).
			AssertFailure("This FungibleToken Register already exist")
	})

}
