package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestFTRegistry(t *testing.T) {

	t.Run("Should be able to registry flow token", func(t *testing.T) {
		NewOverflowTest(t).
			setupFIND().
			registerFTInFtRegistry("flow", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
				"alias":          "Flow",
				"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			})

	})

	t.Run("Should be able to registry flow token and get it", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerFTInFtRegistry("flow", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
				"alias":          "Flow",
				"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			})

		o := otu.O
		result := o.ScriptFromFile("getFTInfoByTypeIdentifier").
			Args(o.Arguments().String("A.0ae53cb6e3f42a79.FlowToken.Vault")).
			RunReturnsInterface()

		expected := map[string]interface{}{
			"alias":          "Flow",
			"balancePath":    "/public/flowTokenBalance",
			"icon":           "",
			"receiverPath":   "/public/flowTokenReceiver",
			"tag":            []interface{}{"utility coin"},
			"type":           "Type<A.0ae53cb6e3f42a79.FlowToken.Vault>()",
			"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			"vaultPath":      "/storage/flowTokenVault",
		}
		assert.Equal(t, expected, result)

	})

	t.Run("Should be able to registry flow token and get it by alias", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerFTInFtRegistry("flow", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
				"alias":          "Flow",
				"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			})

		o := otu.O
		result := o.ScriptFromFile("getFTInfoByAlias").
			Args(o.Arguments().String("Flow")).
			RunReturnsInterface()

		expected := map[string]interface{}{
			"alias":          "Flow",
			"balancePath":    "/public/flowTokenBalance",
			"icon":           "",
			"receiverPath":   "/public/flowTokenReceiver",
			"tag":            []interface{}{"utility coin"},
			"type":           "Type<A.0ae53cb6e3f42a79.FlowToken.Vault>()",
			"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			"vaultPath":      "/storage/flowTokenVault",
		}
		assert.Equal(t, expected, result)

	})

	t.Run("Should be able to registry flow token, fusd token and get list from it", func(t *testing.T) {
		expected := `
		{
		    "A.0ae53cb6e3f42a79.FlowToken.Vault": {
		        "alias": "Flow",
		        "balancePath": "/public/flowTokenBalance",
		        "icon": "",
				"tag" : ["utility coin"],
		        "receiverPath": "/public/flowTokenReceiver",
		        "type": "Type\u003cA.0ae53cb6e3f42a79.FlowToken.Vault\u003e()",
		        "typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
		        "vaultPath": "/storage/flowTokenVault"
		    },
			"A.f8d6e0586b0a20c7.FUSD.Vault": {
		        "alias": "FUSD",
		        "balancePath": "/public/fusdBalance",
		        "icon": "",
				"tag" : ["stablecoin"],
		        "receiverPath": "/public/fusdReceiver",
		        "type": "Type\u003cA.f8d6e0586b0a20c7.FUSD.Vault\u003e()",
		        "typeIdentifier": "A.f8d6e0586b0a20c7.FUSD.Vault",
		        "vaultPath": "/storage/fusdVault"
		    }
		}
		`
		NewOverflowTest(t).
			setupFIND().
			registerFTInFtRegistry("flow", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
				"alias":          "Flow",
				"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			}).
			registerFTInFtRegistry("fusd", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
				"alias":          "FUSD",
				"typeIdentifier": "A.f8d6e0586b0a20c7.FUSD.Vault",
			}).
			scriptEqualToJson("getFTInfoAll", expected)

	})

	t.Run("Should not be able to overrride a ft without removing it first", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerFTInFtRegistry("flow", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
				"alias":          "Flow",
				"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			})

		o := otu.O
		o.TransactionFromFile("setFTInfo_flow").
			SignProposeAndPayAs("find").
			Args(o.Arguments()).
			Test(t).
			AssertFailure("This FungibleToken Register already exist")
	})

	t.Run("Should be able to registry and remove flow token by Alias, as well as return nil on scripts", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerFTInFtRegistry("flow", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
				"alias":          "Flow",
				"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			}).
			removeFTInFtRegistry("removeFTInfoByAlias", "Flow",
				"A.f8d6e0586b0a20c7.FTRegistry.FTInfoRemoved", map[string]interface{}{
					"alias":          "Flow",
					"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
				})

		o := otu.O
		aliasResult := o.ScriptFromFile("getFTInfoByAlias").
			Args(o.Arguments().String("Flow")).
			RunReturnsInterface()
		assert.Equal(t, "", aliasResult)

		infoResult := o.ScriptFromFile("getFTInfoByAlias").
			Args(o.Arguments().String("Flow")).
			RunReturnsInterface()
		assert.Equal(t, "", infoResult)

	})

	t.Run("Should be able to registry and remove flow token by Type Identifier, as well as return nil on scripts", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			registerFTInFtRegistry("flow", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
				"alias":          "Flow",
				"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			}).
			removeFTInFtRegistry("removeFTInfoByTypeIdentifier", "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"A.f8d6e0586b0a20c7.FTRegistry.FTInfoRemoved", map[string]interface{}{
					"alias":          "Flow",
					"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
				})

		o := otu.O
		aliasResult := o.ScriptFromFile("getFTInfoByTypeIdentifier").
			Args(o.Arguments().String("A.0ae53cb6e3f42a79.FlowToken.Vault")).
			RunReturnsInterface()
		assert.Equal(t, "", aliasResult)

		infoResult := o.ScriptFromFile("getFTInfoByAlias").
			Args(o.Arguments().String("Flow")).
			RunReturnsInterface()
		assert.Equal(t, "", infoResult)

	})

}
