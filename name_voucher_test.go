package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
)

func TestNameVoucher(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	initUser := func(s string) *OverflowTestUtils {
		otu.O.Tx(
			"initNameVoucher",
			WithSigner(s),
		).
			AssertSuccess(otu.T)

		return otu
	}
	minCharLength := 4

	ot.Run(t, "Should be able to mint NFT to User 1 with collection", func(t *testing.T) {
		initUser("user1")

		otu.O.Tx(
			"adminMintAndAirdropNameVoucher",
			WithSigner("find-admin"),
			WithAddresses("users", "user1"),
			WithArg("minCharLength", minCharLength),
		).
			AssertSuccess(t).
			AssertEvent(t, "Minted", map[string]interface{}{
				"address":       otu.O.Address("find"),
				"minCharLength": minCharLength,
			}).
			AssertEvent(t, "Deposit", map[string]interface{}{
				"to": otu.O.Address("user1"),
			})
	})

	ot.Run(t, "Should be able to use the voucher to register new name", func(t *testing.T) {
		initUser("user1")

		id, _ := otu.O.Tx(
			"adminMintAndAirdropNameVoucher",
			WithSigner("find-admin"),
			WithAddresses("users", "user1"),
			WithArg("minCharLength", minCharLength),
		).
			AssertSuccess(t).
			AssertEvent(t, "Minted", map[string]interface{}{
				"address":       otu.O.Address("find"),
				"minCharLength": minCharLength,
			}).
			AssertEvent(t, "Deposit", map[string]interface{}{
				"to": otu.O.Address("user1"),
			}).GetIdFromEvent("Minted", "id")

		otu.O.Tx(
			"redeemNameVoucher",
			WithSigner("user1"),
			WithArg("id", id),
			WithArg("name", "test"),
		).
			AssertSuccess(t).
			AssertEvent(t, "Redeemed", map[string]interface{}{
				"id":            id,
				"address":       otu.O.Address("user1"),
				"minCharLength": 4,
				"findName":      "test",
				"action":        "register",
			})
	})

	ot.Run(t, "Should be able to mint NFT directly from lost and found", func(t *testing.T) {
		minCharLength := 5

		res := otu.O.Tx(
			"adminMintAndAirdropNameVoucher",
			WithSigner("find-admin"),
			WithAddresses("users", "user1"),
			WithArg("minCharLength", minCharLength),
		).
			AssertSuccess(t).
			AssertEvent(t, "Minted", map[string]interface{}{
				"address":       otu.O.Address("find"),
				"minCharLength": minCharLength,
			}).
			AssertEvent(t, "AirdroppedToLostAndFound", map[string]interface{}{
				"from": otu.O.Address("find"),
				"to":   otu.O.Address("user1"),
			})

		ticketID, err := res.GetIdFromEvent("AirdroppedToLostAndFound", "ticketID")
		assert.NoError(t, err)
		otu.O.Tx(
			"redeemNameVoucher",
			WithSigner("user1"),
			WithArg("id", ticketID),
			WithArg("name", "testingisgood"),
		).
			AssertSuccess(t).
			AssertEvent(t, "NameVoucher.Redeemed", map[string]interface{}{
				"address":       otu.O.Address("user1"),
				"minCharLength": 5,
				"findName":      "testingisgood",
				"action":        "register",
			})
	})
}
