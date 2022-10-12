package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
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

	otu.setUUID(400)

	var flowIOUId uint64
	var usdcIOUId uint64
	var fusdIOUId uint64
	var ducIOUId uint64

	t.Run("Should be able to create IOU with Flow", func(t *testing.T) {
		iouId, err := otu.O.Tx("createIOU",
			WithSigner("user1"),
			WithArg("name", "Flow"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUCreated", map[string]interface{}{
				"type":   "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"amount": 100.0,
			}).
			GetIdFromEvent("IOUCreated", "uuid")
		assert.NoError(t, err)

		flowIOUId = iouId
	})

	if flowIOUId == 0 {
		flowIOUId, _ = otu.O.Tx("createIOU",
			WithSigner("user1"),
			WithArg("name", "Flow"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			GetIdFromEvent("IOUCreated", "uuid")
	}

	t.Run("Should be able to topUp IOU with flow", func(t *testing.T) {
		otu.O.Tx("topUpIOU",
			WithSigner("user1"),
			WithArg("id", flowIOUId),
			WithArg("amount", 200.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUToppedUp", map[string]interface{}{
				"type":       "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"amount":     200.0,
				"fromAmount": 100.0,
				"toAmount":   300.0,
			})
	})

	t.Run("Balance will go back to the issuer when the IOU is destroyed", func(t *testing.T) {
		otu.O.Tx("testDestroyIOU",
			WithSigner("user1"),
			WithArg("id", flowIOUId),
		).
			AssertSuccess(t).
			AssertEvent(t, "FlowToken.TokensDeposited", map[string]interface{}{
				"amount": 300.0,
				"to":     otu.O.Address("user1"),
			})
	})

	flowIOUId, _ = otu.O.Tx("createIOU",
		WithSigner("user1"),
		WithArg("name", "Flow"),
		WithArg("amount", 100.0),
	).
		AssertSuccess(t).
		GetIdFromEvent("IOUCreated", "uuid")

	t.Run("Should be able to redeem IOU with Flow", func(t *testing.T) {
		otu.O.Tx("redeemIOU",
			WithSigner("user1"),
			WithArg("id", flowIOUId),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOURedeemed", map[string]interface{}{
				"type":   "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"amount": 100.0,
			})
	})

	t.Run("Should be able to create IOU with USDC", func(t *testing.T) {
		iouId, err := otu.O.Tx("createIOU",
			WithSigner("user1"),
			WithArg("name", "USDC"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUCreated", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.FiatToken.Vault",
				"amount": 100.0,
			}).
			GetIdFromEvent("IOUCreated", "uuid")

		assert.NoError(t, err)
		usdcIOUId = iouId
	})

	if usdcIOUId == 0 {
		usdcIOUId, _ = otu.O.Tx("createIOU",
			WithSigner("user1"),
			WithArg("name", "USDC"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			GetIdFromEvent("IOUCreated", "uuid")
	}

	t.Run("Should be able to topUp IOU with USDC", func(t *testing.T) {
		otu.O.Tx("topUpIOU",
			WithSigner("user1"),
			WithArg("id", usdcIOUId),
			WithArg("amount", 200.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUToppedUp", map[string]interface{}{
				"type":       "A.f8d6e0586b0a20c7.FiatToken.Vault",
				"amount":     200.0,
				"fromAmount": 100.0,
				"toAmount":   300.0,
			})
	})

	t.Run("Should be able to redeem IOU with USDC", func(t *testing.T) {
		otu.O.Tx("redeemIOU",
			WithSigner("user1"),
			WithArg("id", usdcIOUId),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOURedeemed", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.FiatToken.Vault",
				"amount": 300.0,
			})
	})

	t.Run("Should be able to create IOU with FUSD", func(t *testing.T) {
		iouId, err := otu.O.Tx("createIOU",
			WithSigner("user1"),
			WithArg("name", "FUSD"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUCreated", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.FUSD.Vault",
				"amount": 100.0,
			}).
			GetIdFromEvent("IOUCreated", "uuid")

		assert.NoError(t, err)
		fusdIOUId = iouId
	})

	if fusdIOUId == 0 {
		fusdIOUId, _ = otu.O.Tx("createIOU",
			WithSigner("user1"),
			WithArg("name", "FUSD"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			GetIdFromEvent("IOUCreated", "uuid")
	}

	t.Run("Should be able to topUp IOU with FUSD", func(t *testing.T) {
		otu.O.Tx("topUpIOU",
			WithSigner("user1"),
			WithArg("id", fusdIOUId),
			WithArg("amount", 200.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUToppedUp", map[string]interface{}{
				"type":       "A.f8d6e0586b0a20c7.FUSD.Vault",
				"amount":     200.0,
				"fromAmount": 100.0,
				"toAmount":   300.0,
			})
	})

	t.Run("Should be able to redeem IOU with FUSD", func(t *testing.T) {
		otu.O.Tx("redeemIOU",
			WithSigner("user1"),
			WithArg("id", fusdIOUId),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOURedeemed", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.FUSD.Vault",
				"amount": 300.0,
			})
	})

	t.Run("Should be able to create IOU with Dapper DUC", func(t *testing.T) {
		iouId, err := otu.O.Tx("createIOUDapper",
			WithSigner("user1"),
			WithPayloadSigner("account"),
			WithArg("name", "DUC"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUCreated", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.DapperUtilityCoin.Vault",
				"amount": 100.0,
			}).
			GetIdFromEvent("IOUCreated", "uuid")

		assert.NoError(t, err)
		ducIOUId = iouId
	})

	if ducIOUId == 0 {
		ducIOUId, _ = otu.O.Tx("createIOUDapper",
			WithSigner("user1"),
			WithPayloadSigner("account"),
			WithArg("name", "DUC"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			GetIdFromEvent("IOUCreated", "uuid")
	}

	t.Run("Should be able to topUp IOU with Dapper DUC", func(t *testing.T) {
		otu.O.Tx("topUpIOUDapper",
			WithSigner("user1"),
			WithPayloadSigner("account"),
			WithArg("id", ducIOUId),
			WithArg("amount", 200.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOUToppedUp", map[string]interface{}{
				"type":       "A.f8d6e0586b0a20c7.DapperUtilityCoin.Vault",
				"amount":     200.0,
				"fromAmount": 100.0,
				"toAmount":   300.0,
			})
	})

	t.Run("Should be able to redeem IOU with Dapper DUC", func(t *testing.T) {
		otu.O.Tx("redeemIOUDapper",
			WithSigner("user1"),
			WithPayloadSigner("account"),
			WithArg("id", ducIOUId),
		).
			AssertSuccess(t).
			AssertEvent(t, "IOURedeemed", map[string]interface{}{
				"type":   "A.f8d6e0586b0a20c7.DapperUtilityCoin.Vault",
				"amount": 300.0,
			})
	})

}
