package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestFindIOU(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(100.0, "user1")

	mintFund := otu.O.TxFN(
		WithSigner("account"),
		WithArg("amount", 10000.0),
		WithArg("recipient", "user1"),
	)

	mintFund("testMintFusd").AssertSuccess(t)

	mintFund("testMintFlow").AssertSuccess(t)

	mintFund("testMintUsdc").AssertSuccess(t)

	otu.registerFtInRegistry().
		registerDUCInRegistry()

	otu.O.Tx("adminInitDUC",
		WithSigner("account"),
		WithArg("dapperAddress", "account"),
	).AssertSuccess(t)

	otu.setUUID(400)

	t.Run("Should be able to create IOU with Flow", func(t *testing.T) {
		otu.O.Tx("createIOU",
			WithSigner("user1"),
			WithArg("name", "Flow"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUCreated", map[string]interface{}{
				"type":   "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"amount": 100.0,
			})
	})

	t.Run("Should not be able to destroy IOU", func(t *testing.T) {
		otu.O.Tx("testDestroyIOU",
			WithSigner("user1"),
			WithArg("name", "Flow"),
		).
			AssertFailure(t, "balance of vault in IOU cannot be non-zero when destroy")
	})

	t.Run("Should be able to redeem IOU with Flow", func(t *testing.T) {
		otu.O.Tx("redeemIOU",
			WithSigner("user1"),
			WithArg("name", "Flow"),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOURedeemed", map[string]interface{}{
				"type":   "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"amount": 100.0,
			})
	})

	t.Run("Should be able to create IOU with USDC", func(t *testing.T) {
		otu.O.Tx("createIOU",
			WithSigner("user1"),
			WithArg("name", "USDC"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUCreated", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.FiatToken.Vault",
				"amount": 100.0,
			})
	})

	t.Run("Should be able to redeem IOU with USDC", func(t *testing.T) {
		otu.O.Tx("redeemIOU",
			WithSigner("user1"),
			WithArg("name", "USDC"),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOURedeemed", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.FiatToken.Vault",
				"amount": 100.0,
			})
	})

	t.Run("Should be able to create IOU with FUSD", func(t *testing.T) {
		otu.O.Tx("createIOU",
			WithSigner("user1"),
			WithArg("name", "FUSD"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUCreated", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.FUSD.Vault",
				"amount": 100.0,
			})
	})

	t.Run("Should be able to redeem IOU with FUSD", func(t *testing.T) {
		otu.O.Tx("redeemIOU",
			WithSigner("user1"),
			WithArg("name", "FUSD"),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOURedeemed", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.FUSD.Vault",
				"amount": 100.0,
			})
	})

	t.Run("Should be able to create IOU with Dapper DUC", func(t *testing.T) {
		otu.O.Tx("createDapperIOU",
			WithSigner("user1"),
			WithPayloadSigner("account"),
			WithArg("name", "DUC"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUCreated", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.DapperUtilityCoin.Vault",
				"amount": 100.0,
			})
	})

	t.Run("Should be able to redeem IOU with Dapper DUC", func(t *testing.T) {
		otu.O.Tx("redeemDapperIOU",
			WithSigner("user1"),
			WithPayloadSigner("account"),
			WithArg("name", "DUC"),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOURedeemed", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.DapperUtilityCoin.Vault",
				"amount": 100.0,
			})
	})

}
