package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
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

	setupDapperMarketForWearables(otu, "FUT", 0.025, 0.0)

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
			WithArg("marketplace", "dapper"),
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

	setupDapperMarketForWearables(otu, "DUC", 0.025, 0.0)

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
			WithArg("marketplace", "dapper"),
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
			WithArg("marketplace", "dapper"),
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

	otu := NewOverflowTest(t).
		setupFIND().
		createDapperUser("user1").
		createDapperUser("user2").
		createWearableUser("user1").
		createWearableUser("user2").
		registerDUCInRegistry()

	setupDapperMarketForWearables(otu, "DUC", 0.25, 0.0)

	id1 := otu.mintWearables("user1")
	addNFTCatalog(otu, "user1", id1)

	price := 10.0

	token, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(t, err)

	t.Run("Should be able to trade in a differently set up market", func(t *testing.T) {
		listWearablesForSaleFUT(otu, "user1", id1, price, token)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "dapper"),
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
					"amount":      0.44,
					"royaltyName": "dapper",
					"vaultType":   token,
				})

		sendWearables(otu, "user1", "user2", id1)
	})

	t.Run("Should be able to reconstruct the market with different fee structure", func(t *testing.T) {

		resetTenant(otu, "dapper")
		setupDapperMarketForWearables(otu, "DUC", 0.025, 0.00)

		listWearablesForSaleFUT(otu, "user1", id1, price, token)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "dapper"),
			WithArg("address", "user1"),
			WithArg("id", id1),
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

		sendWearables(otu, "user1", "user2", id1)

	})

}

func resetTenant(otu *OverflowTestUtils, tenant string) *OverflowTestUtils {

	otu.O.Tx(
		"remove_find_market_1",
		WithSigner("find-admin"),
		WithArg("tenant", tenant),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "TenantRemoved", map[string]interface{}{
			"tenant":  "dapper",
			"address": otu.O.Address(tenant),
		})

	otu.O.Tx(
		"remove_find_market_2",
		WithSigner(tenant),
	).
		AssertSuccess(otu.T)

	return otu
}

func setupDapperMarketForWearables(otu *OverflowTestUtils, coin string, findCut, tenantCut float64) *OverflowTestUtils {
	name := "dapper"
	// merchAddress := "0x01cf0e2f2f715450"
	// switch otu.O.Network {
	// case "testnet":
	// 	merchAddress = "0x4748780c8bf65e19"
	// 	name = "find-dapper"

	// case "mainnet":
	// 	merchAddress = "0x55459409d30274ee"
	// 	name = "find-dapper"
	// }

	o := otu.O
	t := otu.T

	o.Tx("adminSendFlow",
		WithSigner("find"),
		WithArg("receiver", name),
		WithArg("amount", 0.1),
	).
		AssertSuccess(t)

	o.Tx("createProfile",
		WithSigner(name),
		WithArg("name", name),
	).
		AssertSuccess(t)

	o.Tx("setup_find_market_1_dapper",
		WithSigner(name),
		WithArg("dapperAddress", "dapper"),
	).
		AssertSuccess(t)

	o.Tx("setup_find_market_2",
		WithSigner("find-admin"),
		WithArg("tenant", name),
		WithArg("tenantAddress", name),
		WithArg("findCut", findCut),
	).
		AssertSuccess(t)
	otu.setupInfrastructureCut(name)

	id, err := o.QualifiedIdentifier("Wearables", "NFT")
	assert.NoError(t, err)
	o.Tx("tenantsetMarketOptionDapper",
		WithSigner(name),
		WithArg("nftName", "Wearables"),
		WithArg("nftType", id),
		WithArg("cut", tenantCut),
	).
		AssertSuccess(t)

	return otu
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
		WithArg("marketplace", "dapper"),
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
