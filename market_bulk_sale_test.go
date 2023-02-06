package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
)

func TestMarketAndLeaseSale(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		setupDandy("user1").
		createUser(100.0, "user2").
		registerUser("user2").
		createUser(100.0, "user3").
		registerUser("user3").
		setFlowDandyMarketOption("find").
		setProfile("user1").
		setProfile("user2")

	otu.setUUID(400)

	ids := otu.mintThreeExampleDandies()
	names := []string{
		"name1",
		"name2",
	}

	for _, name := range names {
		otu.registerUserWithName("user1", name)
	}

	listingTx := otu.O.TxFileNameFN(
		"listForSaleMultiple",
		WithSigner("user1"),
		WithArg("marketplace", "find"),

		WithArg("validUntil", otu.currentTime()+100.0),
	)

	otu.registerFtInRegistry()

	fusdIdentifier, err := otu.O.QualifiedIdentifier("FUSD", "Vault")
	assert.NoError(t, err)

	ftIdentifier, err := otu.O.QualifiedIdentifier("FlowToken", "Vault")
	assert.NoError(t, err)

	nftIdentifier, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(t, err)

	leaseIdentifier, err := otu.O.QualifiedIdentifier("FIND", "Lease")
	assert.NoError(t, err)

	t.Run("Should be able to list dandy and lease for sale", func(t *testing.T) {

		res := listingTx(
			WithArg("nftAliasOrIdentifiers", []string{nftIdentifier, nftIdentifier, nftIdentifier, leaseIdentifier, leaseIdentifier}),
			WithArg("ids", []interface{}{ids[0], ids[1], ids[2], names[0], names[1]}),
			WithArg("ftAliasOrIdentifiers", []string{ftIdentifier, ftIdentifier, ftIdentifier, fusdIdentifier, fusdIdentifier}),
			WithArg("directSellPrices", []float64{1.0, 2.0, 3.0, 4.0, 5.0}),
		)

		res.AssertSuccess(t)

		status := "active_listed"

		for i, id := range ids {
			res.AssertEvent(t, "FindMarketSale.Sale", map[string]interface{}{
				"tenant":     "find",
				"id":         id,
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"amount":     1.0 + float64(i),
				"status":     status,
				"vaultType":  ftIdentifier,
			})
		}

		for i, name := range names {
			res.AssertEvent(t, "FIND.Sale", map[string]interface{}{
				"name":       name,
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"amount":     4.0 + float64(i),
				"status":     status,
				"vaultType":  fusdIdentifier,
			})
		}

	})

	t.Run("Should be able to buy dandy and lease for sale", func(t *testing.T) {

		res := otu.O.Tx(
			"buyForSaleMultiple",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithAddresses("users", "user1", "user1", "user1", "user1", "user1"),
			WithArg("ids", []interface{}{ids[0], ids[1], ids[2], names[0], names[1]}),
			WithArg("amounts", []float64{1.0, 2.0, 3.0, 4.0, 5.0}),
		)

		res.AssertSuccess(t)
		status := "sold"

		for i, id := range ids {
			res.AssertEvent(t, "FindMarketSale.Sale", map[string]interface{}{
				"tenant":     "find",
				"id":         id,
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"amount":     1.0 + float64(i),
				"status":     status,
				"vaultType":  ftIdentifier,
			})
		}

		for i, name := range names {
			res.AssertEvent(t, "FIND.Sale", map[string]interface{}{
				"name":       name,
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"amount":     4.0 + float64(i),
				"status":     status,
				"vaultType":  fusdIdentifier,
			})
		}

	})

}
