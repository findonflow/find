package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestMarketDUCRoyalty(t *testing.T) {

	otu := NewOverflowTest(t)

	setupDapper(otu).
		setupDandy("user1").
		createUser(100.0, "user2").
		registerUser("user2").
		createUser(100.0, "user3").
		registerUser("user3").
		setProfile("user1").
		setProfile("user2")
	price := 10.0

	otu.setUUID(400)
	otu.createDapperUser("find").
		createDapperUser("user1").
		createDapperUser("user2").
		createDapperUser("user3")

	royaltyIdentifier := otu.identifier("FindMarket", "RoyaltyPaid")
	DUCType := otu.identifier("DapperUtilityCoin", "Vault")

	id := otu.mintThreeExampleDandies()[0]

	otu.registerFTInFtRegistry("duc", otu.identifier("FTRegistry", "FTInfoRegistered"), map[string]interface{}{
		"alias":          "DUC",
		"typeIdentifier": DUCType,
	}).
		registerDandyInNFTRegistry()

	otu.O.Tx("adminMainnetAddItem",
		WithSigner("find-admin"),
		WithArg("tenant", "find"),
		WithArg("ftName", "duc"),
		WithArg("ftTypes", []string{DUCType}),
		WithArg("nftName", "dandy"),
		WithArg("nftTypes", []string{dandyNFTType(otu)}),
		WithArg("listingName", "all"),
		WithArg("listingTypes", `[]`),
	).
		AssertSuccess(t).
		AssertEvent(t, "TenantAllowRules", map[string]interface{}{
			"tenant":   "onefootball",
			"ruleName": "allducdandy",
		})

	t.Run("Minimum Royalty should be paid to minter with DUC FindMarketSale", func(t *testing.T) {

		listNFTForSaleDUC(otu, "user1", id, price)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("merchantAddress", "dapper"),
			WithArg("marketplace", "find"),
			WithArg("address", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.65,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "onefootball",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.65,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "onefootball",
			})
		otu.sendDandy("user1", "user2", id)

	})

	t.Run("Should Pay royalty with DUC FindMarketSale", func(t *testing.T) {

		price = 1000.0

		listNFTForSaleDUC(otu, "user1", id, price)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("merchantAddress", "dapper"),
			WithArg("marketplace", "find"),
			WithArg("address", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      50.0,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "onefootball",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      25.0,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "onefootball",
			})
		otu.sendDandy("user1", "user2", id)

	})

	t.Run("Minimum Royalty should be paid to minter with DUC FindMarketAuctionSoft", func(t *testing.T) {

		price = 5.0

		listNFTForSoftAuction(otu, "user1", id, price).
			saleItemListed("user1", "active_listed", price)
		auctionBidMarketSoft(otu, "user2", "user1", id, price+5.0)

		otu.tickClock(500.0)

		otu.O.Tx("fulfillMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
			WithArg("amount", 10.0),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.65,
				"royaltyName": "creator",
				"tenant":      "onefootball",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.65,
				"royaltyName": "find forge",
				"tenant":      "onefootball",
			})

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Should Pay royalty with DUC FindMarketAuctionSoft", func(t *testing.T) {

		price = 1000.0

		listNFTForSoftAuction(otu, "user1", id, price).
			saleItemListed("user1", "active_listed", price)
		auctionBidMarketSoft(otu, "user2", "user1", id, price+5.0)

		otu.tickClock(500.0)

		otu.O.Tx("fulfillMarketAuctionSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
			WithArg("amount", price+5.0),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      50.25,
				"royaltyName": "creator",
				"tenant":      "onefootball",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      25.125,
				"royaltyName": "find forge",
				"tenant":      "onefootball",
			})

		otu.sendDandy("user1", "user2", id)
	})

	t.Run("Minimum Royalty should be paid to minter with DUC FindMarketDirectOfferSoft", func(t *testing.T) {

		price = 10.0

		directOfferMarketSoft(otu, "user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)
		acceptDirectOfferMarketSoft(otu, "user1", id, "user2", price)

		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.65,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "onefootball",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.65,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "onefootball",
			})

		otu.sendDandy("user1", "user2", id)

	})

	t.Run("Should Pay royalty with DUC FindMarketDirectOfferSoft", func(t *testing.T) {

		price = 1000.0

		directOfferMarketSoft(otu, "user2", "user1", id, price).
			saleItemListed("user1", "active_ongoing", price)
		acceptDirectOfferMarketSoft(otu, "user1", id, "user2", price)

		otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("marketplace", "find"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      50.0,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "onefootball",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      25.0,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "onefootball",
			})

		otu.sendDandy("user1", "user2", id)

	})

	t.Run("Should not be able to list with price less than min price", func(t *testing.T) {

		price = 0.5
		name := "user1"
		otu.O.Tx("listNFTForSaleDapper",
			WithSigner(name),
			WithArg("marketplace", "find"),
			WithArg("dapperAddress", "dapper"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", DUCType),
			WithArg("directSellPrice", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Listing price should be greater than 0.65")

		otu.O.Tx("listNFTForAuctionSoftDapper",
			WithSigner(name),
			WithArg("dapperAddress", "dapper"),
			WithArg("marketplace", "find"),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", DUCType),
			WithArg("price", price),
			WithArg("auctionReservePrice", price+5.0),
			WithArg("auctionDuration", 300.0),
			WithArg("auctionExtensionOnLateBid", 60.0),
			WithArg("minimumBidIncrement", 1.0),
			WithArg("auctionValidUntil", otu.currentTime()+10.0),
		).
			AssertFailure(t, "Auction start price should be greater than 0.65")

		otu.O.Tx("bidMarketDirectOfferSoftDapper",
			WithSigner("user2"),
			WithArg("dapperAddress", "dapper"),
			WithArg("marketplace", "find"),
			WithArg("user", name),
			WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "A.f8d6e0586b0a20c7.DapperUtilityCoin.Vault"),
			WithArg("amount", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Offer price should be greater than 0.65")
	})

}

func setupDapper(otu *OverflowTestUtils) *OverflowTestUtils {
	//first step create the adminClient as the fin user

	dapperSigner := WithSigner("dapper")
	findSigner := WithSigner("find-admin")
	saSigner := WithSigner("find")

	otu.O.Tx("setup_fin_1_create_client", findSigner).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	//link in the server in the versus client
	otu.O.Tx("setup_fin_2_register_client",
		saSigner,
		WithArg("ownerAddress", "find-admin"),
	).AssertSuccess(otu.T).AssertNoEvents(otu.T)

	//set up fin network as the fin user
	otu.O.Tx("setup_fin_3_create_network", findSigner).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	otu.O.Tx("setup_find_market_1", dapperSigner).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	//link in the server in the versus client
	otu.O.Tx("setup_find_dapper_market",
		findSigner,
		WithArg("adminAddress", "dapper"),
		WithArg("tenantAddress", "find"),
		WithArg("name", "onefootball"),
	).AssertSuccess(otu.T)

	// Setup Lease Market
	otu.O.Tx("setup_find_market_1",
		WithSigner("find-forge")).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	//link in the server in the client
	otu.O.Tx("setup_find_lease_market_2",
		WithSigner("find-admin"),
		WithArg("tenantAddress", "find-forge"),
	).AssertSuccess(otu.T)

	otu.createDapperUser("find")
	otu.createDapperUser("find-forge")

	//link in the server in the versus client
	otu.O.Tx("devSetResidualAddress",
		findSigner,
		WithArg("address", "find"),
	).AssertSuccess(otu.T)

	otu.O.Tx("adminInitDapper",
		dapperSigner,
		WithArg("dapperAddress", "find"),
	).AssertSuccess(otu.T)

	return otu.tickClock(1.0)
}

func listNFTForSaleDUC(otu *OverflowTestUtils, name string, id uint64, price float64) *OverflowTestUtils {

	DUCType := otu.identifier("DapperUtilityCoin", "Vault")
	otu.O.Tx("listNFTForSaleDapper",
		WithSigner(name),
		WithArg("marketplace", "find"),
		WithArg("dapperAddress", "dapper"),
		WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", DUCType),
		WithArg("directSellPrice", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketSale.Sale", map[string]interface{}{
			"status": "active_listed",
			"amount": price,
			"id":     id,
			"seller": otu.O.Address(name),
		})

	return otu
}

func listNFTForSoftAuction(otu *OverflowTestUtils, name string, id uint64, price float64) *OverflowTestUtils {

	DUCType := otu.identifier("DapperUtilityCoin", "Vault")
	otu.O.Tx("listNFTForAuctionSoftDapper",
		WithSigner(name),
		WithArg("dapperAddress", "dapper"),
		WithArg("marketplace", "find"),
		WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", DUCType),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+10.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"status":              "active_listed",
			"amount":              price,
			"auctionReservePrice": price + 5.0,
			"id":                  id,
			"seller":              otu.O.Address(name),
		})

	return otu

}

func auctionBidMarketSoft(otu *OverflowTestUtils, name string, seller string, id uint64, price float64) *OverflowTestUtils {

	otu.O.Tx("bidMarketAuctionSoftDapper",
		WithSigner(name),
		WithArg("dapperAddress", "dapper"),
		WithArg("marketplace", "find"),
		WithArg("user", seller),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_ongoing",
		})

	return otu
}

func directOfferMarketSoft(otu *OverflowTestUtils, name string, seller string, id uint64, price float64) *OverflowTestUtils {

	DUCType := otu.identifier("DapperUtilityCoin", "Vault")
	otu.O.Tx("bidMarketDirectOfferSoftDapper",
		WithSigner(name),
		WithArg("dapperAddress", "dapper"),
		WithArg("marketplace", "find"),
		WithArg("user", seller),
		WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", DUCType),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
		})

	return otu

}

func acceptDirectOfferMarketSoft(otu *OverflowTestUtils, name string, id uint64, buyer string, price float64) *OverflowTestUtils {

	otu.O.Tx("acceptDirectOfferSoftDapper",
		WithSigner(name),
		WithArg("dapperAddress", "dapper"),
		WithArg("marketplace", "find"),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"id":     id,
			"seller": otu.O.Address(name),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "active_accepted",
		})

	return otu
}
