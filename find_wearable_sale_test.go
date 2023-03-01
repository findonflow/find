package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/findonflow/find/findGo"
	"github.com/stretchr/testify/assert"
)

func TestFindWearablesSaleFUT(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createDapperUser("user1").
		createDapperUser("user2").
		createWearableUser("user1").
		createWearableUser("user2").
		registerDUCInRegistry()

	ot := findGo.OverflowUtils{
		O: otu.O,
		T: otu.T,
	}

	ot.UpgradeFindDapperTenantSwitchboard()

	id1 := otu.mintWearables("user1")
	addNFTCatalog(otu, "user1", id1)

	price := 10.0

	token, err := otu.O.QualifiedIdentifier("FlowUtilityToken", "Vault")
	assert.NoError(t, err)

	t.Run("Should be able to list thru dapper market", func(t *testing.T) {

		listWearablesForSaleFUT(otu, "user1", id1, price, token)

	})

	t.Run("Should be able to buy thru dapper market, royalties are asserted", func(t *testing.T) {

		listWearablesForSaleFUT(otu, "user1", id1, price, token)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("address", "user1"),
			WithArg("id", id1),
			WithArg("amount", price),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":   otu.O.Address("find"),
					"amount":    0.25,
					"vaultType": token,
				})

		sendWearables(otu, "user1", "user2", id1)

	})

}

func TestFindWearablesSaleDUC(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createDapperUser("user1").
		createDapperUser("user2").
		createWearableUser("user1").
		createWearableUser("user2").
		registerDUCInRegistry()

	ot := findGo.OverflowUtils{
		O: otu.O,
		T: otu.T,
	}
	ot.UpgradeFindDapperTenantSwitchboard()

	id1 := otu.mintWearables("user1")
	addNFTCatalog(otu, "user1", id1)

	price := 10.0

	token, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(t, err)

	t.Run("Should be able to list thru dapper market", func(t *testing.T) {

		listWearablesForSaleFUT(otu, "user1", id1, price, token)

	})

	t.Run("Should be able to buy thru dapper market, royalties are asserted with minimum 0.44", func(t *testing.T) {

		listWearablesForSaleFUT(otu, "user1", id1, price, token)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("address", "user1"),
			WithArg("id", id1),
			WithArg("amount", price),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("find"),
					"amount":      0.25,
					"vaultType":   token,
					"royaltyName": "find",
				}).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("dapper"),
					"amount":      0.44,
					"royaltyName": "dapper",
					"vaultType":   token,
				})

		sendWearables(otu, "user1", "user2", id1)

	})

	t.Run("Should be able to buy thru dapper market, royalties are asserted", func(t *testing.T) {

		price := 100.0

		listWearablesForSaleFUT(otu, "user1", id1, price, token)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("address", "user1"),
			WithArg("id", id1),
			WithArg("amount", price),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("find"),
					"amount":      2.5,
					"royaltyName": "find",
					"vaultType":   token,
				}).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("dapper"),
					"amount":      1.0,
					"royaltyName": "dapper",
					"vaultType":   token,
				})

		sendWearables(otu, "user1", "user2", id1)
	})

}

func TestFindWearablesSaleResetMarket(t *testing.T) {

	// This test aims to mimic how we switch from market items now to new find market structure

	otu := NewOverflowTest(t).
		setupFIND().
		createDapperUser("user1").
		createDapperUser("user2").
		createWearableUser("user1").
		createWearableUser("user2").
		registerDUCInRegistry()

	otu.setFlowDandyMarketOption("dapper")
	price := 10.0

	token, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(t, err)

	dandyIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	otu.registerDapperUser("user1")
	otu.buyForgeDapper("user1")
	dandy := otu.mintThreeExampleDandies()[0]
	otu.registerDandyInNFTRegistry()

	t.Run("Should be able to trade in a differently set up market", func(t *testing.T) {
		otu.O.Tx("listNFTForSaleDapper",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("nftAliasOrIdentifier", dandyIden),
			WithArg("id", dandy),
			WithArg("ftAliasOrIdentifier", token),
			WithArg("directSellPrice", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(otu.T)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("address", "user1"),
			WithArg("id", dandy),
			WithArg("amount", price),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("find"),
					"amount":      0.25,
					"royaltyName": "find",
					"vaultType":   token,
				}).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("dapper"),
					"amount":      0.44,
					"royaltyName": "dapper",
					"vaultType":   token,
				})

	})

	wearable := otu.mintWearables("user1")
	addNFTCatalog(otu, "user1", wearable)

	ot := findGo.OverflowUtils{
		O: otu.O,
		T: otu.T,
	}
	ot.UpgradeFindDapperTenantSwitchboard()

	dandy = otu.mintThreeExampleDandies()[0]
	t.Run("Should still be able to trade original NFTs after the upgrade", func(t *testing.T) {
		otu.O.Tx("listNFTForSaleDapper",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("nftAliasOrIdentifier", dandyIden),
			WithArg("id", dandy),
			WithArg("ftAliasOrIdentifier", token),
			WithArg("directSellPrice", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(otu.T)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("address", "user1"),
			WithArg("id", dandy),
			WithArg("amount", price),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("find"),
					"amount":      0.25,
					"royaltyName": "find",
					"vaultType":   token,
				}).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("dapper"),
					"amount":      0.44,
					"royaltyName": "dapper",
					"vaultType":   token,
				})

	})

	t.Run("Should be able to sell wearables in DUC with different fee structure", func(t *testing.T) {

		listWearablesForSaleFUT(otu, "user1", wearable, price, token)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("address", "user1"),
			WithArg("id", wearable),
			WithArg("amount", price),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("find"),
					"amount":      0.25,
					"royaltyName": "find",
					"vaultType":   token,
				}).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("dapper"),
					"amount":      0.44,
					"royaltyName": "dapper",
					"vaultType":   token,
				})

		sendWearables(otu, "user1", "user2", wearable)

	})

	t.Run("Should be able to sell wearables in FUT with different fee structure", func(t *testing.T) {
		token, err := otu.O.QualifiedIdentifier("FlowUtilityToken", "Vault")
		assert.NoError(t, err)
		listWearablesForSaleFUT(otu, "user1", wearable, price, token)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("address", "user1"),
			WithArg("id", wearable),
			WithArg("amount", price),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("find"),
					"amount":      0.25,
					"royaltyName": "find",
					"vaultType":   token,
				})

		sendWearables(otu, "user1", "user2", wearable)

	})

	t.Run("Should be able to list and buy lease in the market with different fee structure", func(t *testing.T) {

		otu.registerDapperUserWithName("user1", "name1")

		ftIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
		assert.NoError(otu.T, err)

		otu.O.Tx("listLeaseForSaleDapper",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", ftIden),
			WithArg("directSellPrice", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(otu.T)

	})

	t.Run("Should be able to list and buy lease in the market with different fee structure", func(t *testing.T) {

		otu.listLeaseForSaleDUC("user1", "name1", price)

		otu.O.Tx("buyLeaseForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("sellerAccount", "user1"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindLeaseMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("find"),
					"amount":      0.25,
					"royaltyName": "find",
					"vaultType":   token,
				}).
			AssertEvent(otu.T, "FindLeaseMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("dapper"),
					"amount":      0.44,
					"royaltyName": "dapper",
					"vaultType":   token,
				})

	})

}

func addNFTCatalog(otu *OverflowTestUtils, user string, id uint64) *OverflowTestUtils {

	contractAddress := "0xf8d6e0586b0a20c7"
	switch otu.O.Network {
	case "testnet":
		contractAddress = "0x1e0493ee604e7598"

	case "mainnet":
		contractAddress = "0xe81193c424cfd3fb"
	}

	otu.O.Tx("adminAddNFTCatalog",
		WithSigner("find-admin"),
		WithArg("collectionIdentifier", "wearables"),
		WithArg("contractName", "Wearables"),
		WithArg("contractAddress", contractAddress),
		WithArg("addressWithNFT", user),
		WithArg("nftID", id),
		WithArg("publicPathIdentifier", "wearables"),
	).
		AssertSuccess(otu.T)

	return otu
}

func listWearablesForSaleFUT(otu *OverflowTestUtils, name string, id uint64, price float64, token string) []uint64 {

	nftIden, err := otu.O.QualifiedIdentifier("Wearables", "NFT")
	assert.NoError(otu.T, err)

	eventIden, err := otu.O.QualifiedIdentifier("FindMarketSale", "Sale")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("listNFTForSaleDapper",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", token),
		WithArg("directSellPrice", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		GetIdsFromEvent(eventIden, "id")

	return res
}

func sendWearables(otu *OverflowTestUtils, receiver string, sender string, id uint64) *OverflowTestUtils {

	otu.O.Tx(
		"sendWearables",
		WithSigner("user2"),
		WithArg("allReceivers", []string{otu.O.Address("user1")}),
		WithArg("ids", []uint64{id}),
		WithArg("memos", []string{"1"}),
	)

	return otu
}
