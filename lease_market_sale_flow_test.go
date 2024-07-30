package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
)

func TestLeaseMarketSaleFlow(t *testing.T) {
	// We need to rework these tests, need to call setup_find_lease_market_2_dapper.cdc
	// we cannot sign using the address that should receive royalty

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(100.0, "user1").registerUser("user1").
		createUser(100.0, "user2").registerUser("user2").
		createUser(100.0, "user3").registerUser("user3").
		registerFtInRegistry().
		setFlowLeaseMarketOption().
		setProfile("user1").
		setProfile("user2")

	price := 10.0

	otu.setUUID(500)

	//	royaltyIdentifier := otu.identifier("FindLeaseMarket", "RoyaltyPaid")

	otu.registerUserWithName("user1", "name1")
	otu.registerUserWithName("user1", "name2")
	otu.registerUserWithName("user1", "name3")

	ftIden, err := otu.O.QualifiedIdentifier("FlowToken", "Vault")
	assert.NoError(otu.T, err)

	t.Run("Should be able to list a lease for sale and buy it", func(t *testing.T) {
		otu.listLeaseForSale("user1", "name1", price)

		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyLeaseForMarketSale("user2", "user1", "name1", price).
			moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should not be able to list with price $0", func(t *testing.T) {
		otu.O.Tx("listLeaseForSale",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", ftIden),
			WithArg("directSellPrice", 0.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Listing price should be greater than 0")
	})

	t.Run("Should not be able to list with invalid time", func(t *testing.T) {
		otu.O.Tx("listLeaseForSale",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("ftAliasOrIdentifier", ftIden),
			WithArg("directSellPrice", price),
			WithArg("validUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")
	})

	t.Run("Should be able to cancel listing if the pointer is no longer valid", func(t *testing.T) {
		otu.listLeaseForSale("user1", "name1", price).
			moveNameTo("user1", "user2", "name1")

		otu.O.Tx("delistLeaseSale",
			WithSigner("user1"),
			WithArg("leases", `["name1"]`),
		).
			AssertSuccess(t)

		otu.moveNameTo("user2", "user1", "name1")
	})

	t.Run("Should be able to change price of lease", func(t *testing.T) {
		otu.listLeaseForSale("user1", "name1", price)

		newPrice := 15.0
		otu.listLeaseForSale("user1", "name1", newPrice)
		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, newPrice, itemsForSale[0].Amount)

		otu.cancelAllLeaseForSale("user1")
	})

	t.Run("Should not be able to buy your own listing", func(t *testing.T) {
		otu.listLeaseForSale("user1", "name1", price)

		otu.O.Tx("buyLeaseForSale",
			WithSigner("user1"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "You cannot buy your own listing")
	})

	t.Run("Should not be able to buy expired listing", func(t *testing.T) {
		otu.tickClock(200.0)

		otu.O.Tx("buyLeaseForSale",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", price),
		).
			AssertFailure(t, "This sale item listing is already expired")

		otu.cancelAllLeaseForSale("user1")
	})

	t.Run("Should be able to cancel sale", func(t *testing.T) {
		otu.listLeaseForSale("user1", "name1", price)

		otu.cancelLeaseForSale("user1", "name1")
		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 0, len(itemsForSale))
	})

	t.Run("Should not be able to buy if too low price", func(t *testing.T) {
		otu.listLeaseForSale("user1", "name1", price)

		otu.O.Tx("buyLeaseForSale",
			WithSigner("user2"),
			WithArg("leaseName", "name1"),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "Incorrect balance sent in vault. Expected 10.00000000 got 5.00000000")

		otu.cancelAllLeaseForSale("user1")
	})

	t.Run("Should be able cancel all listing", func(t *testing.T) {
		otu.listLeaseForSale("user1", "name1", price)
		otu.listLeaseForSale("user1", "name2", price)
		otu.listLeaseForSale("user1", "name3", price)

		itemsForSale := otu.getLeasesForSale("user1")
		assert.Equal(t, 3, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.O.Tx("delistAllLeaseSale",
			WithSigner("user1"),
		).
			AssertSuccess(t).
			AssertEventCount(t, 3)
	})
}
