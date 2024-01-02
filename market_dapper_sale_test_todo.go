package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
)

func TestDapperMarketSale(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	/*
		royaltyIdentifier := otu.identifier("FindMarket", "RoyaltyPaid")
		dandyIdentifier := dandyNFTType(otu)
		exampleIdentifier := exampleNFTType(otu)

		id := dandyIds[0]
	*/
	price := 10.0

	ot.Run(t, "Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {
		otu.createDapperUser("user1").
			createDapperUser("user2").
			createDapperUser("find").
			createDapperUser("find-admin")

		otu.registerDUCInRegistry().
			setExampleNFT().
			sendExampleNFT("user1", "find", 0).
			setFlowExampleMarketOption("find")

		saleItemID := otu.listNFTForSaleDUC("user1", 0, price)

		otu.checkRoyalty("user1", 0, "creator", exampleNFTType(otu), 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.getNFTForMarketSale("user1", saleItemID[0], price)

		otu.buyNFTForMarketSaleDUC("user2", "user1", saleItemID[0], price).
			sendExampleNFT("user1", "user2", 0)
	})

	ot.Run(t, "Should be able to list an NFT for sale and buy it with DUC, royalties should be paid to merch account", func(t *testing.T) {
		saleItemID := otu.listNFTForSaleDUC("user1", 0, price)

		otu.checkRoyalty("user1", 0, "creator", exampleNFTType(otu), 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.getNFTForMarketSale("user1", saleItemID[0], price)

		name := "user2"
		seller := "user1"
		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner(name),
			WithPayloadSigner("dapper"),
			WithArg("address", seller),
			WithArg("id", saleItemID[0]),
			WithArg("amount", price),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address": otu.O.Address("find"),
					"amount":  0.35,
				})

		otu.sendExampleNFT("user1", "user2", 0)
	})

	ot.Run(t, "Should be able to list an NFT for sale and buy it with DUC, royalties should be paid to merch account if royalty is higher than 0.44", func(t *testing.T) {
		saleItemID := otu.listNFTForSaleDUC("user1", 0, 100.0)

		otu.checkRoyalty("user1", 0, "creator", exampleNFTType(otu), 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.getNFTForMarketSale("user1", saleItemID[0], 100.0)

		name := "user2"
		seller := "user1"
		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner(name),
			WithPayloadSigner("dapper"),
			WithArg("address", seller),
			WithArg("id", saleItemID[0]),
			WithArg("amount", 100.0),
		).
			AssertSuccess(otu.T).
			AssertEvent(otu.T, "FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address": otu.O.Address("find"),
					"amount":  3.5,
				})

		otu.sendExampleNFT("user1", "user2", 0)
	})

	ot.Run(t, "Royalties should be sent to dapper residual account if royalty receiver is not working", func(t *testing.T) {
		saleItemID := otu.listNFTForSaleDUC("user1", 0, price)

		otu.checkRoyalty("user1", 0, "creator", exampleNFTType(otu), 0.01)

		otu.unlinkDUCVaultReceiver("find")
		otu.O.Tx("buyNFTForSaleDapper",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("address", "user1"),
			WithArg("id", saleItemID[0]),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t,
				"FindMarket.RoyaltyCouldNotBePaid",
				map[string]interface{}{
					"address":         otu.O.Address("find"),
					"amount":          0.1,
					"findName":        "find",
					"residualAddress": otu.O.Address("residual"),
					"royaltyName":     "creator",
				},
			)

		otu.linkDUCVaultReceiver("find")
		otu.sendExampleNFT("user1", "user2", 0)
	})
}
