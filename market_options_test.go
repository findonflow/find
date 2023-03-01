package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

func TestMarketOptions(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		setupDandy("user1").
		createUser(100.0, "user2").
		registerUser("user2").
		setFlowDandyMarketOption("Sale").
		setFlowDandyMarketOption("AuctionEscrow")

	price := 10.0
	ids := otu.mintThreeExampleDandies()
	otu.registerFtInRegistry()

	otu.setUUID(400)

	listingTx := otu.O.TxFN(
		WithSigner("user1"),
		WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
		WithArg("id", ids[1]),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("directSellPrice", price),
		WithArg("validUntil", 100.0),
	)

	/* Test on TenantRules removal and setting */
	t.Run("Should be able to list if the rules are set for MarketSale, regardless of the others.", func(t *testing.T) {

		listingTx("listNFTForSale").
			AssertSuccess(t)

		otu.delistAllNFT("user1")
	})

	/* Test on SaleItem removal and setting */
	t.Run("Should be able to list if the rules are set for MarketSale, regardless of the others.", func(t *testing.T) {

		/* Should success for both market types */
		otu.listNFTForEscrowedAuction("user1", ids[0], price).
			listNFTForSale("user1", ids[1], price)

		otu.removeMarketOption("FlowDandySale")

		/* Should fail for MarketSale */
		listingTx("listNFTForSale").
			AssertFailure(t, "Nothing matches")

		/* Should success for auction escrowed */
		otu.listNFTForEscrowedAuction("user1", ids[2], price)

		otu.setFlowDandyMarketOption("Sale")
		otu.delistAllNFT("user1")

	})

	/* Test on TenantRules removal */
	t.Run("Should not be able to list Dandy with FUSD at first, but able after removing tenant rules.", func(t *testing.T) {

		/* Should fail on listing MarketSale with FUSD */
		listingTx("listNFTForSale",
			WithArg("ftAliasOrIdentifier", "FUSD"),
		).
			AssertFailure(t, "Nothing matches")

		otu.removeTenantRule("FlowDandySale", "Flow")

		/* Should success on listing MarketSale with FUSD */
		listingTx("listNFTForSale").
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindMarketSale", "Sale"), map[string]interface{}{
				"status": "active_listed",
				"amount": price,
				"id":     ids[1],
				"seller": otu.O.Address("user1"),
			})

		/* Reset */
		otu.delistAllNFT("user1")
		otu.removeMarketOption("FlowDandySale").
			setFlowDandyMarketOption("Sale")

	})

	/* Test on setting TenantRules */
	t.Run("Should not be able to list Dandy with FUSD at first, but able after removing tenant rules.", func(t *testing.T) {

		/* Should fail on listing MarketSale with FUSD */
		listingTx("listNFTForSale").
			AssertFailure(t, "Nothing matches")

		otu.setTenantRuleFUSD("FlowDandySale")

		/* Should fail on listing MarketSale with FUSD */
		listingTx("listNFTForSale").
			AssertFailure(t, "Nothing matches")

		otu.removeTenantRule("FlowDandySale", "Flow")

		/* Should success on listing MarketSale with FUSD */
		listingTx("listNFTForSale").
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindMarketSale", "Sale"), map[string]interface{}{
				"status": "active_listed",
				"amount": price,
				"id":     ids[1],
				"seller": otu.O.Address("user1"),
			})

		/* Reset */
		otu.delistAllNFT("user1")
		otu.removeMarketOption("FlowDandySale").
			setFlowDandyMarketOption("Sale")

	})

}
