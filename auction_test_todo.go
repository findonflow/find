package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestAuction(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(100.0, "user1").
		registerUser("user1")

	otu.setUUID(400)

	findSaleEvent, err := otu.O.QualifiedIdentifier("FIND", "Sale")
	assert.NoError(t, err)

	findAuctionEvent, err := otu.O.QualifiedIdentifier("FIND", "EnglishAuction")
	assert.NoError(t, err)

	findDOEvent, err := otu.O.QualifiedIdentifier("FIND", "DirectOffer")
	assert.NoError(t, err)

	FUSDDepositEvent, err := otu.O.QualifiedIdentifier("FUSD", "TokensDeposited")
	assert.NoError(t, err)

	t.Run("Should list a name for sale", func(t *testing.T) {

		otu.listForSale("user1")

	})

	t.Run("Should be able list names for sale and delist some", func(t *testing.T) {

		otu.registerUserWithName("user1", "name1").
			registerUserWithName("user1", "name2").
			listForSale("user1").
			listNameForSale("user1", "user1").
			listNameForSale("user1", "name1").
			setProfile("user1")

		otu.O.Tx("delistNameSale",
			WithSigner("user1"),
			WithArg("names", `["user1","name1"]`),
		).
			AssertSuccess(t).
			AssertEvent(t, findSaleEvent, map[string]interface{}{
				"amount":     10.0,
				"name":       "name1",
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"status":     "cancel",
			}).
			AssertEvent(t, findSaleEvent, map[string]interface{}{
				"amount":     10.0,
				"name":       "user1",
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"status":     "cancel",
			})
	})

	t.Run("Should be able list names for sale and delist them ALL", func(t *testing.T) {

		otu.listForSale("user1").
			listNameForSale("user1", "name1").
			listNameForSale("user1", "name2")

		otu.O.Tx("delistAllNameSale",
			WithSigner("user1"),
		).
			AssertSuccess(t).
			AssertEvent(t, findSaleEvent, map[string]interface{}{
				"amount":     10.0,
				"name":       "user1",
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"status":     "cancel",
			}).
			AssertEvent(t, findSaleEvent, map[string]interface{}{
				"amount":     10.0,
				"name":       "name1",
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"status":     "cancel",
			}).
			AssertEvent(t, findSaleEvent, map[string]interface{}{
				"amount":     10.0,
				"name":       "name2",
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"status":     "cancel",
			})
	})

	t.Run("Should be able to direct offer on name for sale", func(t *testing.T) {

		otu.createUser(100.0, "user2").
			registerUser("user2").
			listForSale("user1").
			directOffer("user2", "user1", 4.0)
	})

	t.Run("Should be able to direct offer on name for sale and fulfill it", func(t *testing.T) {

		otu.setProfile("user2")

		otu.O.Tx("fulfillName",
			WithSigner("user1"),
			WithArg("name", "user1"),
		).
			AssertSuccess(t).
			AssertEvent(t, findDOEvent, map[string]interface{}{
				"name":        "user1",
				"seller":      otu.O.Address("user1"),
				"sellerName":  "name1",
				"buyerAvatar": "https://find.xyz/assets/img/avatars/avatar14.png",
				"buyerName":   "user2",
				"status":      "sold",
			}).
			AssertEvent(t, FUSDDepositEvent, map[string]interface{}{
				"amount": 3.8,
				"to":     otu.O.Address("user1"),
			}).
			AssertEvent(t, FUSDDepositEvent, map[string]interface{}{
				"amount": 0.2,
				"to":     otu.O.Address("find-admin"),
			})

	})

	t.Run("Should be able to sell lease from auction buyer can fulfill auction", func(t *testing.T) {

		otu.moveNameTo("user2", "user1", "user1").
			createUser(100.0, "user3").
			registerUser("user3").
			listForAuction("user1").
			bid("user2", "user1", 8.0).
			bid("user3", "user1", 20.0).
			expireAuction().
			setProfile("user3")

		otu.O.Tx("fulfillNameAuction",
			WithSigner("user3"),
			WithArg("owner", "user1"),
			WithArg("name", "user1"),
		).
			AssertSuccess(t).
			AssertEvent(t, findAuctionEvent, map[string]interface{}{
				"name":        "user1",
				"seller":      otu.O.Address("user1"),
				"sellerName":  "name1",
				"amount":      20.0,
				"status":      "sold",
				"buyer":       otu.O.Address("user3"),
				"buyerAvatar": "https://find.xyz/assets/img/avatars/avatar14.png",
				"buyerName":   "user3",
			}).
			AssertEvent(t, FUSDDepositEvent, map[string]interface{}{
				"amount": 19.0,
				"to":     otu.O.Address("user1"),
			}).
			AssertEvent(t, FUSDDepositEvent, map[string]interface{}{
				"amount": 1.0,
				"to":     otu.O.Address("find-admin"),
			})

	})

	t.Run("Should not allow auction bid lower then the current one", func(t *testing.T) {

		otu.moveNameTo("user3", "user1", "user1").
			listForAuction("user1").
			bid("user2", "user1", 8.0).
			auctionBid("user3", "user1", 20.0)

		otu.O.Tx("bidName",
			WithSigner("user2"),
			WithArg("name", "user1"),
			WithArg("amount", 10.0),
		).
			AssertFailure(t, "bid must be larger then current bid. Current bid is : 20.00000000. New bid is at : 10.00000000")

	})

	t.Run("Should be able to sell lease from offer directly", func(t *testing.T) {

		otu.cancelNameAuction("user1", "user1").
			listForSale("user1").
			setProfile("user2")

		buyer := "user2"
		name := "user1"
		amount := 11.0

		otu.O.Tx("bidName",
			WithSigner(buyer),
			WithArg("name", name),
			WithArg("amount", amount),
		).
			AssertSuccess(t).
			AssertEvent(t, findDOEvent, map[string]interface{}{
				"name":        "user1",
				"seller":      otu.O.Address("user1"),
				"sellerName":  "name1",
				"amount":      11.0,
				"status":      "sold",
				"buyer":       otu.O.Address(buyer),
				"buyerAvatar": "https://find.xyz/assets/img/avatars/avatar14.png",
				"buyerName":   buyer,
			}).
			AssertEvent(t, FUSDDepositEvent, map[string]interface{}{
				"amount": 10.45,
				"to":     otu.O.Address("user1"),
			}).
			AssertEvent(t, FUSDDepositEvent, map[string]interface{}{
				"amount": 0.55,
				"to":     otu.O.Address("find-admin"),
			})

		otu.moveNameTo(buyer, name, name)

	})

	t.Run("Should not start auction if bid lower then sale price", func(t *testing.T) {

		otu.listForAuction("user1").
			directOffer("user2", "user1", 4.0)

		otu.O.Tx("cancelNameBid",
			WithSigner("user2"),
			WithArg("names", []string{"user1"}),
		).AssertSuccess(t)

		otu.O.Tx("cancelNameAuction",
			WithSigner("user1"),
			WithArg("names", []string{"user1"}),
		).AssertSuccess(t)

	})

	t.Run("Should not accept direct offer bid less then current one", func(t *testing.T) {

		otu.directOffer("user2", "user1", 10.0)

		otu.O.Tx("bidName",
			WithSigner("user3"),
			WithArg("name", "user1"),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "There is already a higher bid on this lease. Current bid is : 10.00000000 New bid is at : 5.00000000")

		otu.O.Tx("cancelNameBid",
			WithSigner("user2"),
			WithArg("names", []string{"user1"}),
		).AssertSuccess(t)

	})

	t.Run("Should not be able to increase direct offer price less than increment", func(t *testing.T) {

		otu.directOffer("user2", "user1", 10.0)

		otu.O.Tx("increaseNameBid",
			WithSigner("user2"),
			WithArg("name", "user1"),
			WithArg("amount", 0.0),
		).
			AssertFailure(t, "Increment should be greater than 10.00000000")

		otu.O.Tx("cancelNameBid",
			WithSigner("user2"),
			WithArg("names", []string{"user1"}),
		).AssertSuccess(t)

	})

	t.Run("Should start auction if we start out with smaller bid and then increase it with locked user", func(t *testing.T) {

		otu.expireLease().
			listForAuction("user1").
			directOffer("user2", "user1", 4.0)

		otu.O.Tx("increaseNameBid",
			WithSigner("user2"),
			WithArg("name", "user1"),
			WithArg("amount", 10.0),
		).
			AssertSuccess(t).
			AssertEvent(t, findAuctionEvent, map[string]interface{}{
				"name":      "user1",
				"seller":    otu.O.Address("user1"),
				"amount":    14.0,
				"status":    "active_ongoing",
				"buyerName": "user2",
			})

		otu.O.Tx("cancelNameAuction",
			WithSigner("user1"),
			WithArg("names", []string{"user1"}),
		).AssertSuccess(t)

	})

	t.Run("Should be able to sell locked name at auction", func(t *testing.T) {

		otu.listForAuction("user1").
			auctionBid("user2", "user1", 20.0).
			expireAuction().
			setProfile("user2")

		otu.O.Tx("fulfillNameAuction",
			WithSigner("user2"),
			WithArg("owner", "user1"),
			WithArg("name", "user1"),
		).AssertSuccess(t).
			AssertEvent(t, findAuctionEvent,
				map[string]interface{}{
					"amount":              20.0,
					"auctionReservePrice": 20.0,
					"buyer":               otu.O.Address("user2"),
					"seller":              otu.O.Address("user1"),
				},
			)

	})

	t.Run("Should not allow double bid from same author", func(t *testing.T) {

		otu.moveNameTo("user2", "user1", "user1").
			renewUserWithName("user1", "user1").
			renewUserWithName("user2", "user2").
			renewUserWithName("user3", "user3").
			renewUserWithName("user1", "name1").
			renewUserWithName("user1", "name2").
			listForAuction("user1").
			bid("user2", "user1", 10.0)

		otu.O.Tx("bidName",
			WithSigner("user2"),
			WithArg("name", "user1"),
			WithArg("amount", 15.0),
		).
			AssertFailure(t, "You already have the latest bid on this item, use the incraseBid transaction")

		otu.O.Tx("cancelNameAuction",
			WithSigner("user1"),
			WithArg("names", []string{"user1"}),
		).AssertSuccess(t)

	})

	t.Run("Should start auction if we start out with smaller bid and then increase it", func(t *testing.T) {

		otu.listForAuction("user1").
			directOffer("user2", "user1", 4.0)

		otu.O.Tx("increaseNameBid",
			WithSigner("user2"),
			WithArg("name", "user1"),
			WithArg("amount", 10.0),
		).
			AssertSuccess(t).
			AssertEvent(t, findAuctionEvent, map[string]interface{}{
				"name":      "user1",
				"seller":    otu.O.Address("user1"),
				"amount":    14.0,
				"status":    "active_ongoing",
				"buyerName": "user2",
			})

	})

	t.Run("Should not be able to increase bid less than increment", func(t *testing.T) {

		otu.O.Tx("increaseNameBid",
			WithSigner("user2"),
			WithArg("name", "user1"),
			WithArg("amount", 0.0),
		).
			AssertFailure(t, "Increment should be greater than 10.00000000")

	})

	t.Run("Should be able to increase auction bid", func(t *testing.T) {

		otu.O.Tx("increaseNameBid",
			WithSigner("user2"),
			WithArg("name", "user1"),
			WithArg("amount", 10.0),
		).
			AssertSuccess(t).
			AssertEvent(t, findAuctionEvent, map[string]interface{}{
				"name":       "user1",
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"status":     "active_ongoing",
				"buyerName":  "user2",
			})

	})

	t.Run("Should be able to manually start auction with lower bid", func(t *testing.T) {

		otu.cancelNameAuction("user1", "user1").
			listForAuction("user1").
			directOffer("user2", "user1", 4.0)

		otu.O.Tx("startNameAuction",
			WithSigner("user1"),
			WithArg("name", "user1"),
		).
			AssertSuccess(t).
			AssertEvent(t, findAuctionEvent, map[string]interface{}{
				"name":      "user1",
				"seller":    otu.O.Address("user1"),
				"amount":    4.0,
				"status":    "active_ongoing",
				"buyerName": "user2",
			})

	})

	//todo test when user is locked
	t.Run("Should be able to cancel blind bid", func(t *testing.T) {

		otu.cancelNameAuction("user1", "user1").
			listForSale("user1").
			directOffer("user2", "user1", 4.0)

		otu.O.Tx("cancelNameBid",
			WithSigner("user2"),
			WithArg("names", `["user1"]`),
		).
			AssertSuccess(t).
			AssertEvent(t, findDOEvent, map[string]interface{}{
				"name":       "user1",
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"amount":     4.0,
				"status":     "cancel_rejected",
				"buyerName":  "user2",
			})

	})

	t.Run("Should be able to cancel blind bid when user locked", func(t *testing.T) {

		otu.listForSale("user1").
			directOffer("user2", "user1", 4.0).
			expireLease()

		otu.assertLookupAddress("user2", nil)

		otu.O.Tx("cancelNameBid",
			WithSigner("user2"),
			WithArg("names", `["user1"]`),
		).
			AssertSuccess(t).
			AssertEvent(t, findDOEvent, map[string]interface{}{
				"name":       "user1",
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"amount":     4.0,
				"status":     "cancel_rejected",
				"buyerName":  "user2",
			})

	})

	t.Run("Should not be able to cancel bid when auction has started", func(t *testing.T) {

		otu.listForAuction("user1").
			bid("user2", "user1", 5.0)

		otu.O.Tx("cancelNameBid",
			WithSigner("user2"),
			WithArg("names", `["user1"]`),
		).
			AssertFailure(t, "Cannot cancel a bid that is in an auction")

		otu.O.Tx("cancelNameAuction",
			WithSigner("user1"),
			WithArg("names", []string{"user1"}),
		).AssertSuccess(t)

	})

	t.Run("Should return money if outbid", func(t *testing.T) {

		otu.listForAuction("user1").
			bid("user2", "user1", 5.0)

		otu.O.Tx("bidName",
			WithSigner("user3"),
			WithArg("name", "user1"),
			WithArg("amount", 15.0),
		).
			AssertSuccess(t).
			AssertEvent(t, FUSDDepositEvent, map[string]interface{}{
				"amount": 5.0,
				"to":     otu.O.Address("user2"),
			}).
			AssertEvent(t, findAuctionEvent, map[string]interface{}{
				"name":          "user1",
				"seller":        otu.O.Address("user1"),
				"sellerName":    "user1",
				"amount":        15.0,
				"status":        "active_ongoing",
				"buyerName":     "user3",
				"previousBuyer": otu.O.Address("user2"),
			})

	})

	t.Run("Should extend auction on late bid", func(t *testing.T) {

		otu.cancelNameAuction("user1", "user1").
			listForAuction("user1").
			bid("user2", "user1", 5.0)

		otu.tickClock(86380.0)

		otu.O.Tx("bidName",
			WithSigner("user3"),
			WithArg("name", "user1"),
			WithArg("amount", 15.0),
		).
			AssertSuccess(t).
			AssertEvent(t, FUSDDepositEvent, map[string]interface{}{
				"amount": 5.0,
				"to":     otu.O.Address("user2"),
			}).
			AssertEvent(t, findAuctionEvent, map[string]interface{}{
				"name":       "user1",
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"amount":     15.0,
				"status":     "active_ongoing",
				"buyerName":  "user3",
			})

		otu.cancelNameAuction("user1", "user1")

	})

	t.Run("Should be able to cancel unfinished auction", func(t *testing.T) {

		otu.listForAuction("user1").
			bid("user2", "user1", 5.0)

		otu.O.Tx("cancelNameAuction",
			WithSigner("user1"),
			WithArg("names", `["user1"]`),
		).
			AssertSuccess(t).
			AssertEvent(t, FUSDDepositEvent, map[string]interface{}{
				"amount": 5.0,
				"to":     otu.O.Address("user2"),
			}).
			AssertEvent(t, findAuctionEvent, map[string]interface{}{
				"name":       "user1",
				"seller":     otu.O.Address("user1"),
				"sellerName": "user1",
				"amount":     5.0,
				"status":     "cancel_listing",
				"buyerName":  "user2",
			})

	})

	t.Run("Should not be able to bid on lease that is free, and not cleaned up", func(t *testing.T) {

		otu.listForSale("user1")

		otu.expireLease().tickClock(2.0)
		otu.expireLock().tickClock(2.0)

		otu.O.Tx("bidName",
			WithSigner("user2"),
			WithArg("name", "user1"),
			WithArg("amount", 10.0),
		).
			AssertFailure(t, "cannot bid on name that is free")

	})

	t.Run("Should be able to cancel finished auction that did not meet reserve price", func(t *testing.T) {

		otu.registerUser("user1").
			listForAuction("user1").
			bid("user2", "user1", 15.0).
			expireAuction().tickClock(2.0).
			setProfile("user2")

		otu.O.Tx("cancelNameAuction",
			WithSigner("user1"),
			WithArg("names", `["user1"]`),
		).AssertSuccess(t).
			AssertEvent(t, findAuctionEvent,
				map[string]interface{}{
					"amount":              15.0,
					"auctionReservePrice": 20.0,
					"buyer":               otu.O.Address("user2"),
					"seller":              otu.O.Address("user1"),
				},
			)

	})

	t.Run("Should not be able to cancel finished auction", func(t *testing.T) {

		otu.listForAuction("user1").
			bid("user2", "user1", 25.0).
			expireAuction().tickClock(2.0)

		otu.O.Tx("cancelNameAuction",
			WithSigner("user1"),
			WithArg("names", `["user1"]`),
		).
			AssertFailure(t, "Cannot cancel finished auction")

		otu.O.Tx("fulfillNameAuction",
			WithSigner("user2"),
			WithArg("owner", "user1"),
			WithArg("name", "user1"),
		).AssertSuccess(t)

		otu.moveNameTo("user2", "user1", "user1")

	})

	t.Run("Should not be able to direct offer on your own name", func(t *testing.T) {

		otu.O.Tx("bidName",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "cannot bid on your own name")

	})

	t.Run("Should cancel previous bid if put for auction", func(t *testing.T) {

		otu.directOffer("user2", "user1", 5.0)

		name := "user1"

		otu.O.Tx("listNameForAuction",
			WithSigner(name),
			WithArg("name", name),
			WithArg("auctionStartPrice", 5.0),
			WithArg("auctionReservePrice", 20.0),
			WithArg("auctionDuration", auctionDurationFloat),
			WithArg("auctionExtensionOnLateBid", 300.0),
		).AssertSuccess(t).
			AssertEvent(t, findAuctionEvent, map[string]interface{}{
				"name":       name,
				"seller":     otu.O.Address(name),
				"sellerName": name,
				"amount":     5.0,
				"status":     "active_listed",
			}).
			AssertEvent(t, findDOEvent, map[string]interface{}{
				"name":       name,
				"seller":     otu.O.Address(name),
				"sellerName": name,
				"amount":     5.0,
				"buyer":      otu.O.Address("user2"),
				"buyerName":  "user2",
				"status":     "rejected",
			})

		otu.cancelNameAuction("user1", "user1")

	})

	t.Run("Should register previousBuyer if direct offer outbid", func(t *testing.T) {

		otu.directOffer("user2", "user1", 4.0).
			setProfile("user3")

		otu.O.Tx("bidName",
			WithSigner("user3"),
			WithArg("name", "user1"),
			WithArg("amount", 10.0),
		).AssertSuccess(t).
			AssertEvent(t, findDOEvent,
				map[string]interface{}{
					"amount": 10.0,
					"buyer":  otu.O.Address("user3"),
					"seller": otu.O.Address("user1"),
				},
			)

		otu.O.Tx("cancelNameBid",
			WithSigner("user3"),
			WithArg("names", []string{"user1"}),
		).AssertSuccess(t)

	})
}
