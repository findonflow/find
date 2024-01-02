package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestMarketSale(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	royaltyIdentifier := otu.identifier("FindMarket", "RoyaltyPaid")
	dandyIdentifier := dandyNFTType(otu)
	exampleIdentifier := exampleNFTType(otu)

	id := dandyIds[0]
	price := 10.0
	listingTx := otu.O.TxFN(
		WithSigner("user1"),
		WithArg("nftAliasOrIdentifier", "Dandy"),
		WithArg("nftAliasOrIdentifier", dandyIdentifier),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("directSellPrice", 10.0),
		WithArg("validUntil", otu.currentTime()+100.0),
	)

	ot.Run(t, "Should be able to list a dandy for sale and buy it", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)
		otu.checkRoyalty("user1", id, "find forge", dandyIdentifier, 0.025)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyNFTForMarketSale("user2", "user1", id, price)
	})

	ot.Run(t, "Should be able to list a dandy for sale and buy it if buyer didn't receiver that correctly", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)
		otu.unlinkDandyReceiver("user2")
		otu.buyNFTForMarketSale("user2", "user1", id, price)
	})

	ot.Run(t, "Should be able to list a dandy for sale and buy it without the collection", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price).
			destroyDandyCollection("user2").
			buyNFTForMarketSale("user2", "user1", id, price)
	})

	ot.Run(t, "Should not be able to list with price $0", func(t *testing.T) {
		listingTx("listNFTForSale",
			WithArg("directSellPrice", 0.0),
		).
			AssertFailure(t, "Listing price should be greater than 0")
	})

	ot.Run(t, "Should not be able to list with invalid time", func(t *testing.T) {
		listingTx("listNFTForSale",
			WithArg("validUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")
	})

	ot.Run(t, "Should be able to cancel listing if the pointer is no longer valid", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price).
			sendDandy("user2", "user1", id)

		otu.O.Tx("delistNFTSale",
			WithSigner("user1"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should be able to change price of dandy", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)

		newPrice := 15.0
		otu.listNFTForSale("user1", id, newPrice)
		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, newPrice, itemsForSale[0].Amount)
	})

	ot.Run(t, "Should not be able to buy your own listing", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user1"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "You cannot buy your own listing")
	})

	ot.Run(t, "Should not be able to buy expired listing", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)
		otu.tickClock(200.0)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "This sale item listing is already expired")
	})

	ot.Run(t, "Should be able to cancel sale", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)

		otu.cancelNFTForSale("user1", id)
		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 0, len(itemsForSale))
	})

	ot.Run(t, "Should not be able to buy if too low price", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "Incorrect balance sent in vault. Expected 10.00000000 got 5.00000000")
	})

	ot.Run(t, "Should be able to list it in Flow but not FUSD.", func(t *testing.T) {
		listingTx("listNFTForSale",
			WithArg("ftAliasOrIdentifier", "FUSD"),
		).AssertFailure(t, "Nothing matches")
	})

	ot.Run(t, "Should be able cancel all listing", func(t *testing.T) {
		otu.listNFTForSale("user1", dandyIds[0], price)
		otu.listNFTForSale("user1", dandyIds[1], price)
		otu.listNFTForSale("user1", dandyIds[2], price)

		scriptResult := otu.O.Script("getFindMarket", WithArg("user", "user1"))
		scriptResult.AssertWithPointerWant(t, "/itemsForSale/FindMarketSale/items/0/saleType", autogold.Want("firstSaleItem", "active_listed"))
		scriptResult.AssertLengthWithPointer(t, "/itemsForSale/FindMarketSale/items", 3)

		otu.O.Tx("delistAllNFTSale",
			WithSigner("user1"),
		).AssertSuccess(t)

		scriptResultAfter := otu.O.Script("getFindMarket", WithArg("user", "user1"))
		scriptResultAfter.AssertWithPointerError(t, "/itemsForSale", "Object has no key 'itemsForSale'")
	})

	ot.Run(t, "Should be able to list it, deprecate it and cannot list another again, but able to buy and delist.", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, price, itemsForSale[0].Amount)

		otu.alterMarketOption("deprecate")

		listingTx("listNFTForSale",
			WithArg("id", dandyIds[1]),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.buyNFTForMarketSale("user2", "user1", id, price)
		otu.alterMarketOption("enable")
		otu.listNFTForSale("user1", dandyIds[1], price)

		otu.alterMarketOption("deprecate")

		otu.O.Tx("delistNFTSale",
			WithSigner("user1"),
			WithArg("ids", dandyIds[1:1]),
		).
			AssertSuccess(t)

		otu.alterMarketOption("enable")
	})

	ot.Run(t, "Should be able to list it, stop it and cannot list another again, buy, nor delist.", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, price, itemsForSale[0].Amount)

		otu.alterMarketOption("stop")

		listingTx("listNFTForSale",
			WithArg("id", dandyIds[1]),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")
	})

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	ot.Run(t, "Royalties should be sent to correspondence upon buy action", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "find",
			})
	})

	ot.Run(t, "Royalties of find platform should be able to change", func(t *testing.T) {
		otu.setFindCut(0.035)
		otu.listNFTForSale("user1", id, price)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.35,
				"id":          id,
				"royaltyName": "find",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          id,
				"royaltyName": "creator",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"id":          id,
				"royaltyName": "find forge",
				"tenant":      "find",
			})
	})

	ot.Run(t, "Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)
		otu.profileBan("user1")

		listingTx("listNFTForSale").
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.cancelNFTForSale("user1", id)
	})

	ot.Run(t, "Should be able to ban user, user cannot buy NFT.", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price)
		otu.profileBan("user2")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Buyer banned by Tenant")
	})

	/*
		* TODOthis test case does not work under 1.0 with how royalties are structured in Forge
			t.Run("Royalties should try to borrow vault in standard way if profile wallet is unlinked", func(t *testing.T) {
				otu.registerUser("user3")
				otu.sendDandy("user3", "user1", id)

				listingTx("listNFTForSale",
					WithSigner("user3"),
					WithArg("id", id),
				).AssertSuccess(t)

				otu.unlinkProfileWallet("user1")

				otu.O.Tx("buyNFTForSale",
					WithSigner("user2"),
					WithArg("user", "user3"),
					WithArg("id", id),
					WithArg("amount", price),
				).
					AssertSuccess(t).
					AssertEvent(t,
						"FindMarket.RoyaltyPaid",
						map[string]interface{}{
							"address":     otu.O.Address("user1"),
							"amount":      0.5,
							"findName":    "user1",
							"royaltyName": "creator",
						},
					)
			})
	*/

	ot.Run(t, "Royalties should try to borrow vault in standard way if profile wallet does not exist", func(t *testing.T) {
		otu.registerUser("user3")
		otu.sendDandy("user3", "user1", id)

		listingTx("listNFTForSale",
			WithSigner("user3"),
			WithArg("id", id),
		).AssertSuccess(t)

		otu.removeProfileWallet("user1")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("user", "user3"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t,
				"FindMarket.RoyaltyPaid",
				map[string]interface{}{
					"address":     otu.O.Address("user1"),
					"amount":      0.5,
					"findName":    "user1",
					"royaltyName": "creator",
				},
			)
	})

	ot.Run(t, "Royalties should be sent to residual account if royalty receiver is not working", func(t *testing.T) {
		otu.registerUser("user3")
		otu.sendDandy("user3", "user1", id)

		otu.O.Tx("devtenantsetMarketOptionAll",
			WithSigner("find"),
			WithArg("nftName", "Dandy"),
			WithArg("nftType", dandyIdentifier),
			WithArg("cut", 0.0),
		).
			AssertSuccess(otu.T)

		listingTx("listNFTForSale",
			WithSigner("user3"),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "FUSD"),
		).AssertSuccess(t)

		otu.destroyFUSDVault("user1")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("user", "user3"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t,
				"FindMarket.RoyaltyCouldNotBePaid",
				map[string]interface{}{
					"address":         otu.O.Address("user1"),
					"amount":          0.5,
					"findName":        "user1",
					"residualAddress": otu.O.Address("residual"),
					"royaltyName":     "creator",
				},
			)
	})

	ot.Run(t, "Should not be able to list soul bound items", func(t *testing.T) {
		otu.O.Tx("mintExampleNFT",
			findSigner,
			WithArg("address", "user1"),
			WithArg("name", "Example2"),
			WithArg("description", "An example NFT"),
			WithArg("thumbnail", "http://foo.bar"),
			WithArg("soulBound", true),
		).AssertSuccess(t)

		otu.O.Tx("listNFTForSale",
			WithSigner("user1"),
			WithArg("nftAliasOrIdentifier", exampleIdentifier),
			WithArg("id", 1),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("directSellPrice", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).AssertFailure(t, "This item is soul bounded and cannot be traded")
	})

	ot.Run(t, "not be able to buy an NFT with changed royalties, but should be able to cancel listing", func(t *testing.T) {
		saleItem := otu.listExampleNFTForSale("user1", exampleIds[0], price)

		otu.checkRoyalty("user1", 0, "creator", exampleIdentifier, 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.changeRoyaltyExampleNFT("user1", 0, true)

		otu.checkRoyalty("user1", 0, "cheater", exampleIdentifier, 0.99)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("user", "user1"),
			WithArg("id", saleItem[0]),
			WithArg("amount", price),
		).
			AssertFailure(t, "The total Royalties to be paid is changed after listing.")

		otu.O.Tx("delistNFTSale",
			WithSigner("user1"),
			WithArg("ids", saleItem[0:1]),
		).
			AssertSuccess(t)

		otu.changeRoyaltyExampleNFT("user1", 0, false)
	})

	ot.Run(t, "should be able to get listings with royalty problems and relist", func(t *testing.T) {
		otu.listExampleNFTForSale("user1", 0, price)

		otu.checkRoyalty("user1", 0, "creator", exampleIdentifier, 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.changeRoyaltyExampleNFT("user1", 0, true)

		otu.checkRoyalty("user1", 0, "cheater", exampleIdentifier, 0.99)

		ids, err := otu.O.Script("getRoyaltyChangedIds",
			WithArg("user", "user1"),
		).
			GetAsJson()
		if err != nil {
			panic(err)
		}

		otu.O.Tx("relistMarketListings",
			WithSigner("user1"),
			WithArg("ids", ids),
		).AssertSuccess(t)
	})
}
