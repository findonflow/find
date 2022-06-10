package test_main

import (
	"testing"

	"github.com/bjartek/overflow/overflow"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestAuction(t *testing.T) {

	t.Run("Should list a name for sale", func(t *testing.T) {

		NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1").
			listForSale("user1")

	})

	t.Run("Should be able list names for sale and delist some", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1").
			registerUserWithName("user1", "name1").
			registerUserWithName("user1", "name2").
			listForSale("user1").
			listNameForSale("user1", "name1").
			listNameForSale("user1", "name1")

		expected := []*overflow.FormatedEvent{
			overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sale", map[string]interface{}{
				"amount":      "10.00000000",
				"buyer":       "",
				"buyerName":   "",
				"lockedUntil": "39312001.00000000",
				"name":        "user1",
				"seller":      "0x179b6b1cb6755e31",
				"sellerName":  "user1",
				"status":      "cancel",
				"uuid":        "86",
				"validUntil":  "31536001.00000000",
				"vaultType":   "A.f8d6e0586b0a20c7.FUSD.Vault",
			}),
			overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sale", map[string]interface{}{
				"amount":      "10.00000000",
				"buyer":       "",
				"buyerName":   "",
				"lockedUntil": "39312001.00000000",
				"name":        "name1",
				"seller":      "0x179b6b1cb6755e31",
				"sellerName":  "user1",
				"status":      "cancel",
				"uuid":        "88",
				"validUntil":  "31536001.00000000",
				"vaultType":   "A.f8d6e0586b0a20c7.FUSD.Vault",
			}),
		}

		otu.O.TransactionFromFile("delistNameSale").
			SignProposeAndPayAs("user1"). //the buy
			Args(otu.O.Arguments().StringArray("user1", "name1")).
			Test(t).
			AssertSuccess().
			AssertEmitEvent(expected...)

	})

	t.Run("Should be able list names for sale and delist them ALL", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1").
			registerUserWithName("user1", "name1").
			registerUserWithName("user1", "name2").
			listForSale("user1").
			listNameForSale("user1", "name1").
			listNameForSale("user1", "name2")

		expected := []*overflow.FormatedEvent{
			overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sale", map[string]interface{}{
				"amount":      "10.00000000",
				"buyer":       "",
				"buyerName":   "",
				"lockedUntil": "39312001.00000000",
				"name":        "user1",
				"seller":      "0x179b6b1cb6755e31",
				"sellerName":  "user1",
				"status":      "cancel",
				"uuid":        "86",
				"validUntil":  "31536001.00000000",
				"vaultType":   "A.f8d6e0586b0a20c7.FUSD.Vault",
			}),
			overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sale", map[string]interface{}{
				"amount":      "10.00000000",
				"buyer":       "",
				"buyerName":   "",
				"lockedUntil": "39312001.00000000",
				"name":        "name1",
				"seller":      "0x179b6b1cb6755e31",
				"sellerName":  "user1",
				"status":      "cancel",
				"uuid":        "88",
				"validUntil":  "31536001.00000000",
				"vaultType":   "A.f8d6e0586b0a20c7.FUSD.Vault",
			}),
			overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sale", map[string]interface{}{
				"amount":      "10.00000000",
				"buyer":       "",
				"buyerName":   "",
				"lockedUntil": "39312001.00000000",
				"name":        "name2",
				"seller":      "0x179b6b1cb6755e31",
				"sellerName":  "user1",
				"status":      "cancel",
				"uuid":        "90",
				"validUntil":  "31536001.00000000",
				"vaultType":   "A.f8d6e0586b0a20c7.FUSD.Vault",
			}),
		}

		otu.O.TransactionFromFile("delistAllNameSale").
			SignProposeAndPayAs("user1"). //the buy
			Test(t).
			AssertSuccess().
			AssertEmitEvent(expected...)

	})

	t.Run("Should be able to direct offer on name for sale", func(t *testing.T) {

		NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			listForSale("user1").
			directOffer("user2", "user1", 4.0)
	})

	t.Run("Should be able to direct offer on name for sale and fulfill it", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			listForSale("user1").
			directOffer("user2", "user1", 4.0)

		otu.O.TransactionFromFile("fulfillName").
			SignProposeAndPayAs("user1"). //the buy
			Args(otu.O.Arguments().String("user1")).
			Test(t).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sale", map[string]interface{}{
				"name":        "user1",
				"seller":      otu.accountAddress("user1"),
				"sellerName":  "user1",
				"lockedUntil": "39312001.00000000",
				"buyerName":   "user2",
				"validUntil":  "31536001.00000000",
				"status":      "sold",
			})).
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "3.80000000",
				"to":     "0x179b6b1cb6755e31",
			})).
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "0.20000000",
				"to":     "0x01cf0e2f2f715450",
			}))
	})

	t.Run("Should be able to sell lease from auction buyer can fulfill auction", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			createUser(100.0, "user3").
			registerUser("user1").
			registerUser("user2").
			registerUser("user3").
			listForAuction("user1").
			bid("user2", "user1", 8.0).
			bid("user3", "user1", 20.0).
			expireAuction()

		otu.O.TransactionFromFile("fulfillNameAuction").
			SignProposeAndPayAs("user3"). //the buy
			Args(otu.O.Arguments().
				Account("user1").
				String("user1")).
			Test(t).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
				"name":       "user1",
				"seller":     otu.accountAddress("user1"),
				"sellerName": "user1",
				"amount":     "20.00000000",
				"status":     "sold",
				"buyer":      otu.accountAddress("user3"),
				"buyerName":  "user3",
			})).
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "19.00000000",
				"to":     "0x179b6b1cb6755e31",
			})).
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "1.00000000",
				"to":     "0x01cf0e2f2f715450",
			}))

	})

	t.Run("Should not allow auction bid lower then the current one", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			createUser(100.0, "user3").
			registerUser("user1").
			registerUser("user2").
			registerUser("user3").
			listForAuction("user1").
			bid("user2", "user1", 8.0).
			auctionBid("user3", "user1", 20.0)

		otu.O.TransactionFromFile("bidName").SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("user1").
				UFix64(10.0)).
			Test(otu.T).
			AssertFailure("bid must be larger then previous bid")
	})

	t.Run("Should be able to sell lease from offer directly", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1")

		buyer := "user2"
		name := "user1"
		amount := 10.0

		otu.O.TransactionFromFile("bidName").SignProposeAndPayAs(buyer).
			Args(otu.O.Arguments().
				String(name).
				UFix64(amount)).
			Test(otu.T).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.Sale", map[string]interface{}{
				"name":       "user1",
				"seller":     otu.accountAddress("user1"),
				"sellerName": "user1",
				"amount":     "10.00000000",
				"status":     "sold",
				"buyer":      otu.accountAddress(buyer),
				"buyerName":  buyer,
			})).
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "9.50000000",
				"to":     "0x179b6b1cb6755e31",
			})).
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "0.50000000",
				"to":     "0x01cf0e2f2f715450",
			}))
	})

	t.Run("Should not start auction if bid lower then sale price", func(t *testing.T) {

		NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			directOffer("user2", "user1", 4.0)

	})

	t.Run("Should not accept direct offer bid less then current one", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			createUser(100.0, "user3").
			registerUser("user1").
			registerUser("user2").
			registerUser("user3").
			directOffer("user2", "user1", 10.0)

		otu.O.TransactionFromFile("bidName").SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().
				String("user1").
				UFix64(5.0)).
			Test(otu.T).
			AssertFailure("There is already a higher bid on this lease")
	})

	t.Run("Should not be able to increase direct offer price less than increment", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			createUser(100.0, "user3").
			registerUser("user1").
			registerUser("user2").
			registerUser("user3").
			directOffer("user2", "user1", 10.0)

		otu.O.TransactionFromFile("increaseNameBid").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("user1").
				UFix64(0.0)).
			Test(otu.T).
			AssertFailure("Increment should be greater than 10.00000000")

	})

	t.Run("Should start auction if we start out with smaller bid and then increase it with locked user", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			expireLease().
			listForAuction("user1").
			directOffer("user2", "user1", 4.0)

		otu.O.TransactionFromFile("increaseNameBid").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("user1").
				UFix64(10.0)).
			Test(t).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
				"name":      "user1",
				"seller":    otu.accountAddress("user1"),
				"amount":    "14.00000000",
				"status":    "active_ongoing",
				"buyerName": "user2",
			}))
	})

	t.Run("Should not allow double bid from same author", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			expireLease().
			listForAuction("user1").
			bid("user2", "user1", 10.0)

		otu.O.TransactionFromFile("bidName").SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("user1").
				UFix64(15.0)).
			Test(otu.T).
			AssertFailure("You already have the latest bid on this item, use the incraseBid transaction")

	})

	t.Run("Should start auction if we start out with smaller bid and then increase it", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			directOffer("user2", "user1", 4.0)

		otu.O.TransactionFromFile("increaseNameBid").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("user1").
				UFix64(10.0)).
			Test(t).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
				"name":       "user1",
				"seller":     "0x179b6b1cb6755e31",
				"sellerName": "user1",
				"amount":     "14.00000000",
				"status":     "active_ongoing",
				"buyerName":  "user2",
			}))
	})

	t.Run("Should not be able to increase bid less than increment", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			directOffer("user2", "user1", 4.0)

		otu.O.TransactionFromFile("increaseNameBid").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("user1").
				UFix64(0.0)).
			Test(t).
			AssertFailure("Increment should be greater than 10.00000000")

	})

	t.Run("Should be able to increase auction bid", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			bid("user2", "user1", 5.0)

		otu.O.TransactionFromFile("increaseNameBid").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().
				String("user1").
				UFix64(10.0)).
			Test(t).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
				"name":       "user1",
				"seller":     "0x179b6b1cb6755e31",
				"sellerName": "user1",
				"amount":     "15.00000000",
				"status":     "active_ongoing",
				"buyerName":  "user2",
			}))

	})

	t.Run("Should be able to manually start auction with lower bid", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			directOffer("user2", "user1", 4.0)

		otu.O.TransactionFromFile("startNameAuction").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().
				String("user1")).
			Test(t).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
				"name":       "user1",
				"seller":     "0x179b6b1cb6755e31",
				"sellerName": "user1",
				"amount":     "4.00000000",
				"status":     "active_ongoing",
				"buyerName":  "user2",
			}))

	})

	//todo test when user is locked
	t.Run("Should be able to cancel blind bid", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			directOffer("user2", "user1", 4.0)

		otu.O.TransactionFromFile("cancelNameBid").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().StringArray("user1")).
			Test(t).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.DirectOffer", map[string]interface{}{
				"name":       "user1",
				"seller":     "0x179b6b1cb6755e31",
				"sellerName": "user1",
				"amount":     "4.00000000",
				"status":     "cancel_rejected",
				"buyerName":  "user2",
			}))
	})

	t.Run("Should be able to cancel blind bid when user locked", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1").
			directOffer("user2", "user1", 4.0).
			expireLease()

		otu.assertLookupAddress("user2", "")

		otu.O.TransactionFromFile("cancelNameBid").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().StringArray("user1")).
			Test(t).
			AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.DirectOffer", map[string]interface{}{
				"name":       "user1",
				"seller":     "0x179b6b1cb6755e31",
				"sellerName": "user1",
				"amount":     "4.00000000",
				"status":     "cancel_rejected",
				"buyerName":  "user2",
			}))
	})

	t.Run("Should not be able to cancel bid when auction has started", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			bid("user2", "user1", 5.0)

		otu.O.TransactionFromFile("cancelNameBid").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().StringArray("user1")).
			Test(t).
			AssertFailure("Cannot cancel a bid that is in an auction")
	})

	t.Run("Should return money if outbid", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			createUser(100.0, "user3").
			registerUser("user1").
			registerUser("user2").
			registerUser("user3").
			listForAuction("user1").
			bid("user2", "user1", 5.0)

		otu.O.TransactionFromFile("bidName").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().String("user1").UFix64(15.0)).
			Test(t).
			AssertSuccess().
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
				"to":     "0xf3fcd2c1a78f5eee",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
				"name":       "user1",
				"seller":     "0x179b6b1cb6755e31",
				"sellerName": "user1",
				"amount":     "15.00000000",
				"status":     "active_ongoing",
				"buyerName":  "user3",
			}))

	})

	t.Run("Should extend auction on late bid", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			createUser(100.0, "user3").
			registerUser("user1").
			registerUser("user2").
			registerUser("user3").
			listForAuction("user1").
			bid("user2", "user1", 5.0)

		otu.tickClock(86380.0)

		otu.O.TransactionFromFile("bidName").
			SignProposeAndPayAs("user3").
			Args(otu.O.Arguments().String("user1").UFix64(15.0)).
			Test(t).
			AssertSuccess().
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
				"to":     "0xf3fcd2c1a78f5eee",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
				"name":       "user1",
				"seller":     "0x179b6b1cb6755e31",
				"sellerName": "user1",
				"amount":     "15.00000000",
				"status":     "active_ongoing",
				"buyerName":  "user3",
			}))

	})

	t.Run("Should be able to cancel unfinished auction", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			bid("user2", "user1", 5.0)

		otu.O.TransactionFromFile("cancelNameAuction").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().StringArray("user1")).
			Test(t).
			AssertEmitEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensDeposited", map[string]interface{}{
				"amount": "5.00000000",
				"to":     "0xf3fcd2c1a78f5eee",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FUSD.TokensWithdrawn", map[string]interface{}{
				"amount": "5.00000000",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
				"name":       "user1",
				"seller":     "0x179b6b1cb6755e31",
				"sellerName": "user1",
				"amount":     "5.00000000",
				"status":     "cancel_listing",
				"buyerName":  "user2",
			}))

	})

	t.Run("Should not be able to bid on lease that is free, and not cleaned up", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForSale("user1")

		otu.expireLease().tickClock(2.0)
		otu.expireLock().tickClock(2.0)

		otu.O.TransactionFromFile("bidName").
			SignProposeAndPayAs("user2").
			Args(otu.O.Arguments().String("user1").UFix64(10.0)).
			Test(t).
			AssertFailure("cannot bid on name that is free")

	})

	t.Run("Should not be able to cancel finished auction", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			listForAuction("user1").
			bid("user2", "user1", 25.0).
			expireAuction().tickClock(2.0)

		otu.O.TransactionFromFile("cancelNameAuction").
			SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().StringArray("user1")).
			Test(t).
			AssertFailure("Cannot cancel finished auction")

	})

	t.Run("Should not be able to direct offer on your own name", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1")

		otu.O.TransactionFromFile("bidName").SignProposeAndPayAs("user1").
			Args(otu.O.Arguments().String("user1").UFix64(5.0)).
			Test(otu.T).
			AssertFailure("cannot bid on your own name")

	})

	t.Run("Should cancel previous bid if put for auction", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			createUser(100.0, "user2").
			registerUser("user1").
			registerUser("user2").
			directOffer("user2", "user1", 5.0)

		name := "user1"
		otu.O.TransactionFromFile("listNameForAuction").
			SignProposeAndPayAs(name).
			Args(otu.O.Arguments().
				String(name).
				UFix64(5.0).  //startAuctionPrice
				UFix64(20.0). //reserve price
				UFix64(auctionDurationFloat).
				UFix64(300.0)). //extention on late bid
			Test(otu.T).AssertSuccess().
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.EnglishAuction", map[string]interface{}{
				"name":       name,
				"seller":     otu.accountAddress(name),
				"sellerName": name,
				"amount":     "5.00000000",
				"buyerName":  "",
				"status":     "active_listed",
			})).
			AssertPartialEvent(overflow.NewTestEvent("A.f8d6e0586b0a20c7.FIND.DirectOffer", map[string]interface{}{
				"name":       name,
				"seller":     otu.accountAddress(name),
				"sellerName": name,
				"amount":     "5.00000000",
				"buyer":      "0xf3fcd2c1a78f5eee",
				"buyerName":  "user2",
				"status":     "rejected",
			}))

	})

}
