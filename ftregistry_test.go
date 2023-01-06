package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestFTRegistry(t *testing.T) {
	otu := NewOverflowTest(t).
		setupFIND()

	otu.registerFTInFtRegistry("flow", otu.identifier("FTRegistry", "FTInfoRegistered"), map[string]interface{}{
		"alias":          "Flow",
		"typeIdentifier": otu.identifier("FlowToken", "Vault"),
	})

	o := otu.O
	t.Run("Should be able to registry flow token and get it", func(t *testing.T) {

		result, err := o.Script("getFTInfo",
			WithArg("aliasOrIdentifier", "Flow"),
		).
			GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.AutoGoldRename("Should be able to registry flow token and get it by alias", result)

		result, err = o.Script("getFTInfo",
			WithArg("aliasOrIdentifier", otu.identifier("FlowToken", "Vault")),
		).
			GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.AutoGoldRename("Should be able to registry flow token and get it by identifier", result)
	})

	t.Run("Should not be able to overrride a ft without removing it first", func(t *testing.T) {

		o.Tx("adminSetFTInfo_flow",
			WithSigner("find-admin"),
		).
			AssertFailure(t, "This FungibleToken Register already exist")

	})

	t.Run("Should be able to registry flow token, fusd token and get list from it", func(t *testing.T) {
		otu.registerFTInFtRegistry("fusd", otu.identifier("FTRegistry", "FTInfoRegistered"), map[string]interface{}{
			"alias":          "FUSD",
			"typeIdentifier": otu.identifier("FUSD", "Vault"),
		})

		result, err := o.Script("getFTInfoAll").GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.AutoGoldRename("Should not be able to overrride a ft without removing it first", result)
	})

	t.Run("Should be able to registry usdc token and get it", func(t *testing.T) {
		otu.registerFTInFtRegistry("usdc", otu.identifier("FTRegistry", "FTInfoRegistered"), map[string]interface{}{
			"alias":          "USDC",
			"typeIdentifier": otu.identifier("FiatToken", "Vault"),
		})

		result, err := o.Script("getFTInfo",
			WithArg("aliasOrIdentifier", otu.identifier("FiatToken", "Vault")),
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
			WithSigner("user2"),
			WithArg("name", "user1"),
			WithArg("amount", 5.0),
			WithArg("ftAliasOrIdentifier", "USDC"),
			WithArg("tag", "test"),
			WithArg("message", "This is a message"),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FiatToken", "TokensDeposited"), map[string]interface{}{
				"amount": 5.0,
				"to":     otu.O.Address("user1"),
			}).
			AssertEvent(t, otu.identifier("FiatToken", "TokensWithdrawn"), map[string]interface{}{
				"amount": 5.0,
				"from":   otu.O.Address("user2"),
			}).
			AssertEvent(t, otu.identifier("FIND", "FungibleTokenSent"), map[string]interface{}{
				"from":      otu.O.Address("user2"),
				"fromName":  "user2",
				"toAddress": otu.O.Address("user1"),
				"amount":    5.0,
				"name":      "user1",
				"tag":       "test",
				"message":   "This is a message",
			})
	})

	t.Run("Should be able to send fusd to another name", func(t *testing.T) {

		o.Tx("sendFT",
			WithSigner("user2"),
			WithArg("name", "user1"),
			WithArg("amount", 5.0),
			WithArg("ftAliasOrIdentifier", "FUSD"),
			WithArg("tag", "test"),
			WithArg("message", "This is a message"),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FUSD", "TokensDeposited"), map[string]interface{}{
				"amount": 5.0,
				"to":     otu.O.Address("user1"),
			}).
			AssertEvent(t, otu.identifier("FUSD", "TokensWithdrawn"), map[string]interface{}{
				"amount": 5.0,
				"from":   otu.O.Address("user2"),
			}).
			AssertEvent(t, otu.identifier("FIND", "FungibleTokenSent"), map[string]interface{}{
				"from":      otu.O.Address("user2"),
				"fromName":  "user2",
				"toAddress": otu.O.Address("user1"),
				"amount":    5.0,
				"name":      "user1",
				"tag":       "test",
				"message":   "This is a message",
			})
	})

	t.Run("Should be able to send flow to another name", func(t *testing.T) {

		o.Tx("sendFT",
			WithSigner("user2"),
			WithArg("name", "user1"),
			WithArg("amount", 5.0),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("tag", "test"),
			WithArg("message", "This is a message"),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FlowToken", "TokensDeposited"), map[string]interface{}{
				"amount": 5.0,
				"to":     otu.O.Address("user1"),
			}).
			AssertEvent(t, otu.identifier("FlowToken", "TokensWithdrawn"), map[string]interface{}{
				"amount": 5.0,
				"from":   otu.O.Address("user2"),
			}).
			AssertEvent(t, otu.identifier("FIND", "FungibleTokenSent"), map[string]interface{}{
				"from":      otu.O.Address("user2"),
				"fromName":  "user2",
				"toAddress": otu.O.Address("user1"),
				"amount":    5.0,
				"name":      "user1",
				"tag":       "test",
				"message":   "This is a message",
			})
	})

	t.Run("Should be able to registry and remove them", func(t *testing.T) {
		otu.removeFTInFtRegistry("adminRemoveFTInfoByAlias", "FUSD",
			otu.identifier("FTRegistry", "FTInfoRemoved"), map[string]interface{}{
				"alias":          "FUSD",
				"typeIdentifier": otu.identifier("FUSD", "Vault"),
			}).
			removeFTInFtRegistry("adminRemoveFTInfoByTypeIdentifier", otu.identifier("FlowToken", "Vault"),
				otu.identifier("FTRegistry", "FTInfoRemoved"), map[string]interface{}{
					"alias":          "Flow",
					"typeIdentifier": otu.identifier("FlowToken", "Vault"),
				})

		o.Script("getFTInfo",
			WithArg("aliasOrIdentifier", otu.identifier("FUSD", "Vault")),
		).
			AssertWant(t, autogold.Want("aliasOrIdentifier", nil))

		o.Script("getFTInfo",
			WithArg("aliasOrIdentifier", "Flow"),
		).
			AssertWant(t, autogold.Want("aliasOrIdentifier", nil))

	})
}
