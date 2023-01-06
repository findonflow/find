package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestNameDetailScript(t *testing.T) {

	t.Run("Should be able to direct offer on name for sale and get by Name Detail Script", func(t *testing.T) {

		otu := NewOverflowTest(t).
			setupFIND().
			createUser(100.0, "user1").
			registerUser("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			listForSale("user1").
			directOffer("user2", "user1", 4.0).
			setProfile("user1").
			setProfile("user2").
			/* place bid on other names */
			listForAuction("user2").
			bid("user1", "user2", 8.0)

		otu.setUUID(400)

		otu.O.Tx("setRelatedAccount",
			WithSigner("user1"),
			WithArg("name", "dapper"),
			WithArg("target", "user2"),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindRelatedAccounts", "RelatedAccount"), map[string]interface{}{
				"walletName": "dapper",
				"user":       otu.O.Address("user1"),
				"address":    otu.O.Address("user2"),
			})

		otu.O.Script("getNameDetails",
			WithArg("user", "user1"),
		).AssertWithPointerWant(t, "/userReport/bids/0",
			autogold.Want("getNameDetailsBids", map[string]interface{}{
				"amount": 8, "lease": map[string]interface{}{
					"address": otu.O.Address("user2"), "auctionEnds": 86401,
					"auctionReservePrice": 20,
					"auctionStartPrice":   5,
					"cost":                5,
					"currentTime":         1,
					"extensionOnLateBid":  300,
					"latestBid":           8,
					"latestBidBy":         otu.O.Address("user1"),
					"lockedUntil":         3.9312001e+07,
					"name":                "user2",
					"status":              "TAKEN",
					"validUntil":          3.1536001e+07,
				},
				"name":      "user2",
				"timestamp": 1,
				"type":      "auction",
			}),
		)
	})

}
