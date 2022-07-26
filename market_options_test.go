package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
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

	otu.setUUID(300)

	/* Test on TenantRules removal and setting */
	t.Run("Should be able to list if the rules are set for MarketSale, regardless of the others.", func(t *testing.T) {

		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertSuccess()

		otu.delistAllNFT("user1")
	})

	/* Test on SaleItem removal and setting */
	t.Run("Should be able to list if the rules are set for MarketSale, regardless of the others.", func(t *testing.T) {

		/* Should success for both market types */
		otu.listNFTForEscrowedAuction("user1", ids[0], price).
			listNFTForSale("user1", ids[1], price)

		otu.removeMarketOption("FlowDandySale")

		/* Should fail for MarketSale */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Nothing matches")

		/* Should success for auction escrowed */
		otu.listNFTForEscrowedAuction("user1", ids[2], price)

		otu.setFlowDandyMarketOption("Sale")
		otu.delistAllNFT("user1")

	})

	/* Test on TenantRules removal */
	t.Run("Should not be able to list Dandy with FUSD at first, but able after removing tenant rules.", func(t *testing.T) {

		/* Should fail on listing MarketSale with FUSD */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Nothing matches")

		otu.removeTenantRule("FlowDandySale", "Flow")

		/* Should success on listing MarketSale with FUSD */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.Sale", map[string]interface{}{
				"status": "active_listed",
				"amount": price,
				"id":     ids[1],
				"seller": otu.accountAddress("user1"),
			}))

		/* Reset */
		otu.delistAllNFT("user1")
		otu.removeMarketOption("FlowDandySale").
			setFlowDandyMarketOption("Sale")

	})

	/* Test on setting TenantRules */
	t.Run("Should not be able to list Dandy with FUSD at first, but able after removing tenant rules.", func(t *testing.T) {

		/* Should fail on listing MarketSale with FUSD */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Nothing matches")

		otu.setTenantRuleFUSD("FlowDandySale")

		/* Should fail on listing MarketSale with FUSD */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).
			AssertFailure("Nothing matches")

		otu.removeTenantRule("FlowDandySale", "Flow")

		/* Should success on listing MarketSale with FUSD */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				Account("account").
				String("A.f8d6e0586b0a20c7.Dandy.NFT").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price).
				UFix64(100.0)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.Sale", map[string]interface{}{
				"status": "active_listed",
				"amount": price,
				"id":     ids[1],
				"seller": otu.accountAddress("user1"),
			}))

		/* Reset */
		otu.delistAllNFT("user1")
		otu.removeMarketOption("FlowDandySale").
			setFlowDandyMarketOption("Sale")

	})

}
