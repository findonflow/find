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
		setFlowDandyMarketOption()

	price := 10.0
	ids := otu.mintThreeExampleDandies()
	otu.registerFtInRegistry()

	otu.setUUID(400)

	listingTx := otu.O.TxFN(
		WithSigner("user1"),
		WithArg("marketplace", "find"),
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

		otu.removeMarketOption("FlowDandyEscrow")

		/* Should fail for MarketSale */
		listingTx("listNFTForSale").
			AssertFailure(t, "Nothing matches")

		otu.setFlowDandyMarketOption()
		otu.delistAllNFT("user1")

	})

}
