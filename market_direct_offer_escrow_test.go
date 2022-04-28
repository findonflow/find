package test_main

import (
	"fmt"
	"testing"

	"github.com/bjartek/overflow/overflow"
)

func TestMarketDirectOfferEscrow(t *testing.T) {

	price := 10.0
	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price)

		otu.saleItemListed("user1", "directoffer", price)
		otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

	})

	t.Run("Should be able to increase offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "directoffer", 15.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)
	})

	t.Run("Should be able to reject offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price).
			rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	t.Run("Should be able to retract offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price).
			retractOfferDirectOfferEscrowed("user2", "user1", id)
	})

	//return money when outbid

	t.Run("Should return money when outbid", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price)

		newPrice := 11.0
		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(newPrice)).
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
				"amount": fmt.Sprintf("%.8f", newPrice),
				"id":     fmt.Sprintf("%d", id),
				"buyer":  otu.accountAddress("user3"),
				"status": "offered",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
				"amount": fmt.Sprintf("%.8f", price),
				"to":     otu.accountAddress("user2"),
			}))
		//TODO: should there be an event emitted that you get your money back?

	})

	/* Tests on Rules */
	t.Run("Should not be able to direct offer after deprecated", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow")

		otu.alterMarketOption("DirectOfferEscrow", "deprecate")

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

	})

	t.Run("Should not be able to increase offer if deprecated but able to accept offer", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price)

		otu.alterMarketOption("DirectOfferEscrow", "deprecate")

		otu.O.TransactionFromFile("increaseBidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				UInt64(id).
				UFix64(5)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.saleItemListed("user1", "directoffer", 10.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 10.0)
	})

	t.Run("Should be able to reject offer when deprecated", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price).
			alterMarketOption("DirectOfferEscrow", "deprecate").
			rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	t.Run("Should not be able to direct offer after stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow")

		otu.alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				Account("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

	})

	t.Run("Should not be able to increase offer nor buy if stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price)

		otu.alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.TransactionFromFile("increaseBidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				UInt64(id).
				UFix64(5)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.saleItemListed("user1", "directoffer", 10.0)

		otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				UInt64(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")
	})

	t.Run("Should not be able to reject offer after stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price).
			alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.TransactionFromFile("cancelMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				UInt64Array(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")
	})

	t.Run("Should be able to able to direct offer, add bit and accept offer after enabled", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			alterMarketOption("DirectOfferEscrow", "deprecate").
			alterMarketOption("DirectOfferEscrow", "enable").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price).
			increaseDirectOfferMarketEscrowed("user2", id, 5.0, 15.0).
			saleItemListed("user1", "directoffer", 15.0).
			acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)
	})

	t.Run("Should be able to able to direct offerand reject after enabled", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			alterMarketOption("DirectOfferEscrow", "deprecate").
			alterMarketOption("DirectOfferEscrow", "enable").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price).
			rejectDirectOfferEscrowed("user1", id, 10.0)
	})

	t.Run("Should not be able to make offer by user3 when deprecated or stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price).
			alterMarketOption("DirectOfferEscrow", "deprecate")

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price + 10.0)).
			Test(otu.T).
			AssertFailure("Tenant has deprected mutation options on this item")

		otu.alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				Account("user1").
				String("Dandy").
				UInt64(id).
				String("Flow").
				UFix64(price + 10.0)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")
	})

	t.Run("Should be able to retract offer when deprecated, but not when stopped", func(t *testing.T) {
		otu := NewOverflowTest(t)

		id := otu.setupMarketAndDandy()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			directOfferMarketEscrowed("user2", "user1", id, price).
			saleItemListed("user1", "directoffer", price).
			alterMarketOption("DirectOfferEscrow", "stop")

		otu.O.TransactionFromFile("retractOfferMarketDirectOfferEscrowed").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				UInt64(id)).
			Test(otu.T).
			AssertFailure("Tenant has stopped this item")

		otu.alterMarketOption("DirectOfferEscrow", "deprecate").
			retractOfferDirectOfferEscrowed("user2", "user1", id)
	})

}
