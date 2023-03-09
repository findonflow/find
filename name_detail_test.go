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
			setFlowLeaseMarketOption().
			registerFtInRegistry().
			createUser(100.0, "user1").
			registerUser("user1").
			createUser(100.0, "user2").
			registerUser("user2").
			listLeaseForSale("user1", "user1", 10.0).
			directOfferLeaseMarketEscrow("user1", "user2", 4.0).
			setProfile("user1").
			setProfile("user2").
			/* place bid on other names */
			listLeaseForEscrowAuction("user2", "user2", 4.0).
			auctionBidLeaseMarketEscrow("user1", "user2", 8.0)

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
		).
			Print().
			AssertWithPointerWant(t, "/userReport/bids/0",
				autogold.Want("getNameDetailsBids", map[string]interface{}{
					"amount": 8, "bidStatus": "auction", "bidTypeIdentifier": "A.179b6b1cb6755e31.FindLeaseMarketAuctionEscrow.Bid",
					"lease": map[string]interface{}{
						"address":     "0x192440c99cb17282",
						"cost":        5,
						"currentTime": 1,
						"lockedUntil": 3.9312001e+07,
						"name":        "user2",
						"status":      "TAKEN",
						"validUntil":  3.1536001e+07,
					},
					"market":    "FindLeaseMarket",
					"name":      "user2",
					"timestamp": 1,
				}),
			)

		otu.O.Script("getNameDetails",
			WithArg("user", "user2"),
		).
			Print().
			AssertWithPointerWant(t, "/leaseStatus",
				autogold.Want("getNameDetailsLeaseStatus", map[string]interface{}{
					"address": "0x192440c99cb17282", "auctions": []interface{}{map[string]interface{}{
						"amount":             8,
						"bidder":             "0xf669cb8d41ce0c74",
						"bidderName":         "user1",
						"endsAt":             301,
						"extensionOnLateBid": 60,
						"ftAlias":            "Flow",
						"ftIdentifier":       "A.0ae53cb6e3f42a79.FlowToken.Vault",
						"market":             "FindLeaseMarket",
						"reservePrice":       9,
						"saleStatus":         "active_ongoing",
						"saleTypeIdentifier": "A.179b6b1cb6755e31.FindLeaseMarketAuctionEscrow.SaleItem",
						"startPrice":         4,
						"validUntil":         301,
					}},
					"cost":        5,
					"currentTime": 1,
					"lockedUntil": 3.9312001e+07,
					"name":        "user2",
					"offers": []interface{}{map[string]interface{}{
						"amount":             4,
						"bidder":             "0xf669cb8d41ce0c74",
						"bidderName":         "user1",
						"ftAlias":            "Flow",
						"ftIdentifier":       "A.0ae53cb6e3f42a79.FlowToken.Vault",
						"market":             "FindLeaseMarket",
						"saleStatus":         "active_ongoing",
						"saleTypeIdentifier": "A.179b6b1cb6755e31.FindLeaseMarketDirectOfferEscrow.SaleItem",
						"validUntil":         101,
					}},
					"status":     "TAKEN",
					"validUntil": 3.1536001e+07,
				}),
			)
	})

}
