package test_main

import (
	"testing"

	//. "github.com/bjartek/overflow/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestLeaseMarketSaleFlow(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}
	price := 10.0

	ot.Run(t, "Should be able to list a lease for sale and buy it", func(t *testing.T) {
		otu.listLeaseForSale("user1", "user1", price)

		itemsForSale := otu.getLeasesForSale("user1")
		require.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyLeaseForMarketSale("user2", "user1", "user1", price)
	})
 
}
