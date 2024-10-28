package test_main

import (
	"testing"

	. "github.com/bjartek/overflow/v2"
)

func TestFTRegistry(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	o := otu.O
	ot.Run(t, "Should be able to registry flow token and get it", func(t *testing.T) {
		result, err := o.Script("devgetFTInfo",
			WithArg("aliasOrIdentifier", "Flow"),
		).
			GetAsJson()
		if err != nil {
			panic(err)
		}

		otu.AutoGoldRename("Should be able to registry flow token and get it by alias", result)

		result, err = o.Script("devgetFTInfo",
			WithArg("aliasOrIdentifier", otu.identifier("FlowToken", "Vault")),
		).
			GetAsJson()
		if err != nil {
			panic(err)
		}

		otu.AutoGoldRename("Should be able to registry flow token and get it by identifier", result)
	})

	ot.Run(t, "Should not be able to overrride a ft without removing it first", func(t *testing.T) {
		o.Tx("adminSetFTInfo_flow",
			WithSigner("find-admin"),
		).
			AssertFailure(t, "This FungibleToken Register already exist")
	})

	ot.Run(t, "Should be able to registry flow token, fusd token and get list from it", func(t *testing.T) {
		result, err := o.Script("devgetFTInfoAll").GetAsJson()
		if err != nil {
			panic(err)
		}

		otu.AutoGoldRename("Should not be able to overrride a ft without removing it first", result)
	})

	ot.Run(t, "Should be able to send flow to another name", func(t *testing.T) {
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
}
