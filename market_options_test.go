package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
)

func TestMarketOptions(t *testing.T) {

	/* Test on TenantRules removal and setting */
	t.Run("Should be able to list if the rules are set for MarketSale, regardless of the others.", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow")

		price := 10.0
		ids := otu.mintThreeExampleDandies()

		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price)).
			Test(otu.T).
			AssertSuccess()

	})

	/* Test on SaleItem removal and setting */
	t.Run("Should be able to list if the rules are set for MarketSale, regardless of the others.", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow")

		price := 10.0
		ids := otu.mintThreeExampleDandies()

		/* Should success for both market types */
		otu.listNFTForEscrowedAuction("user1", ids[0], price).
			listNFTForSale("user1", ids[1], price)

		otu.removeMarketOption("FlowDandySale")

		/* Should fail for MarketSale */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[1]).
				String("Flow").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Nothing matches")

		/* Should success for auction escrowed */
		otu.listNFTForEscrowedAuction("user1", ids[2], price)

	})

	/* Test on TenantRules removal */
	t.Run("Should not be able to list Dandy with FUSD at first, but able after removing tenant rules.", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow")

		price := 10.0
		ids := otu.mintThreeExampleDandies()

		/* Should fail on listing MarketSale with FUSD */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Nothing matches")

		otu.removeTenantRule("FlowDandySale", "Flow")

		/* Should success on listing MarketSale with FUSD */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.ForSale", map[string]interface{}{
				"status": "active_listed",
				"amount": fmt.Sprintf("%.8f", price),
				"id":     fmt.Sprintf("%d", ids[1]),
				"seller": otu.accountAddress("user1"),
			}))

	})

	/* Test on setting TenantRules */
	t.Run("Should not be able to list Dandy with FUSD at first, but able after removing tenant rules.", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("Sale").
			setFlowDandyMarketOption("AuctionEscrow")

		price := 10.0
		ids := otu.mintThreeExampleDandies()

		/* Should fail on listing MarketSale with FUSD */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Nothing matches")

		otu.setTenantRuleFUSD("FlowDandySale")

		/* Should fail on listing MarketSale with FUSD */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Nothing matches")

		otu.removeTenantRule("FlowDandySale", "Flow")

		/* Should success on listing MarketSale with FUSD */
		otu.O.TransactionFromFile("listNFTForSale").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("Dandy").
				UInt64(ids[1]).
				String("FUSD").
				UFix64(price)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketSale.ForSale", map[string]interface{}{
				"status": "active_listed",
				"amount": fmt.Sprintf("%.8f", price),
				"id":     fmt.Sprintf("%d", ids[1]),
				"seller": otu.accountAddress("user1"),
			}))

	})

	// It works but need a better way to do the assert
	// t.Run("Should be able to get all the tenant rules.", func(t *testing.T) {
	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		setupDandy("user1").
	// 		createUser(100.0, "user2").
	// 		registerUser("user2").
	// 		registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("Sale").
	// 		setFlowDandyMarketOption("AuctionEscrow")

	// value, err := otu.O.ScriptFromFile("getTenantSaleItem").
	// 	Args(otu.O.Arguments().
	// 		Address("account")).
	// 	RunReturns()

	// if err != nil {
	// 	fmt.Println(err)
	// }

	// expected := "AuctionEscrow"

	// assert.Contains(otu.T, value, expected)

	// })

}
