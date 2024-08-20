package test_main

import (
	"testing"

	. "github.com/bjartek/overflow/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestLeaseMarketSale(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}
	price := 10.0

	royaltyIdentifier := otu.identifier("FindLeaseMarket", "RoyaltyPaid")

	ftIden, err := ot.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(t, err)

	ot.Run(t, "Should be able to list a lease for sale and buy it", func(t *testing.T) {
		otu.listLeaseForSaleDUC("user5", "user5", price)

		itemsForSale := otu.getLeasesForSale("user5")
		require.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyLeaseForMarketSaleDUC("user6", "user5", "user5", price)
	})

	ot.Run(t, "Should not be able to list with price $0", func(t *testing.T) {
		otu.O.Tx("listLeaseForSaleDapper",
			WithSigner("user5"),
			WithArg("leaseName", "user5"),
			WithArg("ftAliasOrIdentifier", ftIden),
			WithArg("directSellPrice", 0.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).AssertFailure(t, "Listing price should be greater than 0")
	})

	ot.Run(t, "Should not be able to list with invalid time", func(t *testing.T) {
		otu.O.Tx("listLeaseForSaleDapper",
			WithSigner("user5"),
			WithArg("leaseName", "user5"),
			WithArg("ftAliasOrIdentifier", ftIden),
			WithArg("directSellPrice", price),
			WithArg("validUntil", 0.0),
		).AssertFailure(t, "Valid until is before current time")
	})

	ot.Run(t, "Should be able to cancel listing if the pointer is no longer valid", func(t *testing.T) {
		otu.listLeaseForSaleDUC("user5", "user5", price).
			moveNameTo("user5", "user6", "user5")

		otu.O.Tx("delistLeaseSale",
			WithSigner("user5"),
			WithArg("leases", `["user5"]`),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should be able to change price of lease", func(t *testing.T) {
		otu.listLeaseForSaleDUC("user5", "user5", price)

		newPrice := 15.0
		otu.listLeaseForSaleDUC("user5", "user5", newPrice)
		itemsForSale := otu.getLeasesForSale("user5")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, newPrice, itemsForSale[0].Amount)
	})

	ot.Run(t, "Should not be able to buy your own listing", func(t *testing.T) {
		otu.listLeaseForSaleDUC("user5", "user5", price)

		otu.O.Tx("buyLeaseForSaleDapper",
			WithSigner("user5"),
			WithPayloadSigner("dapper"),
			WithArg("sellerAccount", "user5"),
			WithArg("leaseName", "user5"),
			WithArg("amount", price),
		).
			AssertFailure(t, "You cannot buy your own listing")
	})

	ot.Run(t, "Should not be able to buy expired listing", func(t *testing.T) {
		otu.listLeaseForSaleDUC("user5", "user5", price)
		otu.tickClock(200.0)

		otu.O.Tx("buyLeaseForSaleDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("sellerAccount", "user5"),
			WithArg("leaseName", "user5"),
			WithArg("amount", price),
		).
			AssertFailure(t, "This sale item listing is already expired")
	})

	ot.Run(t, "Should be able to cancel sale", func(t *testing.T) {
		otu.listLeaseForSaleDUC("user5", "user5", price)

		otu.cancelLeaseForSale("user5", "user5")
		itemsForSale := otu.getLeasesForSale("user5")
		assert.Equal(t, 0, len(itemsForSale))
	})

	ot.Run(t, "Should not be able to buy if too low price", func(t *testing.T) {
		otu.listLeaseForSaleDUC("user5", "user5", price)

		otu.O.Tx("buyLeaseForSaleDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("sellerAccount", "user5"),
			WithArg("leaseName", "user5"),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "Incorrect balance sent in vault. Expected 10.00000000 got 5.00000000")
	})

	// Testing on Royalties

	// network 0.05
	// find 0.025
	// tenant nil
	ot.Run(t, "Royalties should be sent to correspondence upon buy action", func(t *testing.T) {
		otu.listLeaseForSaleDUC("user5", "user5", price)

		otu.O.Tx("buyLeaseForSaleDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("sellerAccount", "user5"),
			WithArg("leaseName", "user5"),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"leaseName":   "user5",
				"royaltyName": "find",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("dapper"),
				"amount":      0.44,
				"leaseName":   "user5",
				"royaltyName": "dapper",
				"tenant":      "find",
			})
	})

	ot.Run(t, "Royalties should be sent to correspondence upon buy action, if royalty is higher than 0.44", func(t *testing.T) {
		otu.listLeaseForSaleDUC("user5", "user5", 100.0)

		otu.O.Tx("buyLeaseForSaleDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("sellerAccount", "user5"),
			WithArg("leaseName", "user5"),
			WithArg("amount", 100.0),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      2.5,
				"leaseName":   "user5",
				"royaltyName": "find",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("dapper"),
				"amount":      1.0,
				"leaseName":   "user5",
				"royaltyName": "dapper",
				"tenant":      "find",
			})
	})

	ot.Run(t, "Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {
		otu.listLeaseForSaleDUC("user5", "user5", price)
		otu.leaseProfileBan("user5")

		otu.O.Tx("listLeaseForSaleDapper",
			WithSigner("user5"),
			WithArg("leaseName", "user5"),
			WithArg("ftAliasOrIdentifier", ftIden),
			WithArg("directSellPrice", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("buyLeaseForSaleDapper",
			WithSigner("user6"),
			WithPayloadSigner("dapper"),
			WithArg("sellerAccount", "user5"),
			WithArg("leaseName", "user5"),
			WithArg("amount", price),
		).
			AssertFailure(t, "Seller banned by Tenant")
	})


	ot.Run(t, "Should be able to list two leases for sale", func(t *testing.T) {

	otu.O.Tx("devRegisterDapper",
		WithSigner("user5"),
		WithPayloadSigner("dapper"),
		WithArg("merchAccount", "dapper"),
		WithArg("name", "name5"),
		WithArg("amount", 5.0),
	).AssertSuccess(otu.T)

		otu.listLeaseForSaleDUC("user5", "user5", price)
		otu.listLeaseForSaleDUC("user5", "name5", price)

		itemsForSale := otu.getLeasesForSale("user5")
		require.Equal(t, 2 , len(itemsForSale))

	})
}
