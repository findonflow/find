package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestFTRegistry(t *testing.T) {
	otu := NewOverflowTest(t).
		setupFIND().
		registerFTInFtRegistry("flow", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
			"alias":          "Flow",
			"typeIdentifier": "A.0ae53cb6e3f42a79.FlowToken.Vault",
		})

	o := otu.O
	t.Run("Should be able to registry flow token and get it", func(t *testing.T) {

		result, err := o.Script("getFTInfo",
			overflow.WithArg("aliasOrIdentifier", "Flow"),
		).
			GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.AutoGoldRename("Should be able to registry flow token and get it by alias", result)

		result, err = o.Script("getFTInfo",
			overflow.WithArg("aliasOrIdentifier", "A.0ae53cb6e3f42a79.FlowToken.Vault"),
		).
			GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.AutoGoldRename("Should be able to registry flow token and get it by identifier", result)
	})

	t.Run("Should not be able to overrride a ft without removing it first", func(t *testing.T) {

		o.Tx("adminSetFTInfo_flow",
			overflow.WithSigner("find"),
		).
			AssertFailure(t, "This FungibleToken Register already exist")

	})

	t.Run("Should be able to registry flow token, fusd token and get list from it", func(t *testing.T) {
		otu.registerFTInFtRegistry("fusd", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
			"alias":          "FUSD",
			"typeIdentifier": "A.f8d6e0586b0a20c7.FUSD.Vault",
		})

		result, err := o.Script("getFTInfoAll").GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.AutoGoldRename("Should not be able to overrride a ft without removing it first", result)
	})

	t.Run("Should be able to registry usdc token and get it", func(t *testing.T) {
		otu.registerFTInFtRegistry("usdc", "A.f8d6e0586b0a20c7.FTRegistry.FTInfoRegistered", map[string]interface{}{
			"alias":          "USDC",
			"typeIdentifier": "A.f8d6e0586b0a20c7.FiatToken.Vault",
		})

		result, err := o.Script("getFTInfo",
			overflow.WithArg("aliasOrIdentifier", "A.f8d6e0586b0a20c7.FiatToken.Vault"),
		).
			GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.AutoGoldRename("Should be able to registry usdc token and get it", result)
	})

	t.Run("Should be able to send usdc to another name", func(t *testing.T) {
		otu.createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2")

		o.Tx("sendFT",
			overflow.WithSigner("user2"),
			overflow.WithArg("name", "user1"),
			overflow.WithArg("amount", 5.0),
			overflow.WithArg("ftAliasOrIdentifier", "USDC"),
			overflow.WithArg("tag", "test"),
			overflow.WithArg("message", "This is a message"),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FiatToken.TokensDeposited", map[string]interface{}{
				"amount": 5.0,
				"to":     "0x179b6b1cb6755e31",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FiatToken.TokensWithdrawn", map[string]interface{}{
				"amount": 5.0,
				"from":   "0xf3fcd2c1a78f5eee",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FIND.FungibleTokenSent", map[string]interface{}{
				"from":      "0xf3fcd2c1a78f5eee",
				"fromName":  "user2",
				"toAddress": "0x179b6b1cb6755e31",
				"amount":    5.0,
				"name":      "user1",
				"tag":       "test",
				"message":   "This is a message",
			})
	})

	t.Run("Should be able to send fusd to another name", func(t *testing.T) {

		o.Tx("sendFT",
			overflow.WithSigner("user2"),
			overflow.WithArg("name", "user1"),
			overflow.WithArg("amount", 5.0),
			overflow.WithArg("ftAliasOrIdentifier", "FUSD"),
			overflow.WithArg("tag", "test"),
			overflow.WithArg("message", "This is a message"),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": 5.0,
				"to":     "0x179b6b1cb6755e31",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FUSD.TokensWithdrawn", map[string]interface{}{
				"amount": 5.0,
				"from":   "0xf3fcd2c1a78f5eee",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FIND.FungibleTokenSent", map[string]interface{}{
				"from":      "0xf3fcd2c1a78f5eee",
				"fromName":  "user2",
				"toAddress": "0x179b6b1cb6755e31",
				"amount":    5.0,
				"name":      "user1",
				"tag":       "test",
				"message":   "This is a message",
			})
	})

	t.Run("Should be able to send flow to another name", func(t *testing.T) {

		o.Tx("sendFT",
			overflow.WithSigner("user2"),
			overflow.WithArg("name", "user1"),
			overflow.WithArg("amount", 5.0),
			overflow.WithArg("ftAliasOrIdentifier", "Flow"),
			overflow.WithArg("tag", "test"),
			overflow.WithArg("message", "This is a message"),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
				"amount": 5.0,
				"to":     "0x179b6b1cb6755e31",
			}).
			AssertEvent(t, "A.0ae53cb6e3f42a79.FlowToken.TokensWithdrawn", map[string]interface{}{
				"amount": 5.0,
				"from":   "0xf3fcd2c1a78f5eee",
			}).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FIND.FungibleTokenSent", map[string]interface{}{
				"from":      "0xf3fcd2c1a78f5eee",
				"fromName":  "user2",
				"toAddress": "0x179b6b1cb6755e31",
				"amount":    5.0,
				"name":      "user1",
				"tag":       "test",
				"message":   "This is a message",
			})
	})

	t.Run("Should be able to registry and remove them", func(t *testing.T) {
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

		o.Script("getFTInfo",
			overflow.WithArg("aliasOrIdentifier", "A.f8d6e0586b0a20c7.FUSD.Vault"),
		).
			AssertWant(t, autogold.Want("aliasOrIdentifier", nil))

		o.Script("getFTInfo",
			overflow.WithArg("aliasOrIdentifier", "Flow"),
		).
			AssertWant(t, autogold.Want("aliasOrIdentifier", nil))

	})
}
