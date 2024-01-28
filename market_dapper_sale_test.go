package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
)

func TestDapperMarketSale(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	price := 10.0

	ot.Run(t, "Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {
		saleItemID := otu.listNFTForSaleDUC("user5", dapperDandyId, price)

		otu.checkRoyalty("user5", dapperDandyId, "creator", dandyIdentifier, 0.05)

		itemsForSale := otu.getItemsForSale("user5")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)



		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("address", "user5"),
			WithArg("id", saleItemID[0]),
			WithArg("amount", price),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindMarketSale.Sale", map[string]interface{}{
				"amount": price,
				"id":     saleItemID[0],
				"seller": otu.O.Address("user5"),
				"buyer":  otu.O.Address("user6"),
				"status": "sold",
			}).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address": otu.O.Address("find"),
					"amount":  0.25,
				}).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address": otu.O.Address("dapper"),
					"amount":  0.44,
				})
	})

	ot.Run(t, "Should be able to list an NFT for sale and buy it with DUC, royalties should be paid to merch account if royalty is higher than 0.44", func(t *testing.T) {
		saleItemID := otu.listNFTForSaleDUC("user5", dapperDandyId, 100.0)

		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("address", "user5"),
			WithArg("id", saleItemID[0]),
			WithArg("amount", 100.0),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindMarketSale.Sale", map[string]interface{}{
				"amount": 100.0,
				"id":     saleItemID[0],
				"seller": otu.O.Address("user5"),
				"buyer":  otu.O.Address("user6"),
				"status": "sold",
			}).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address": otu.O.Address("find"),
					"amount":  2.50,
				}).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address": otu.O.Address("dapper"),
					"amount":  1.00,
				})
	})
}
