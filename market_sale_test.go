package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestMarketSale(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		setupDandy("user1").
		createUser(100.0, "user2").
		registerUser("user2").
		createUser(100.0, "user3").
		registerUser("user3").
		setFlowDandyMarketOption("Sale").
		setProfile("user1").
		setProfile("user2")
	price := 10.0

	otu.setUUID(600)
	eventIdentifier := otu.identifier("FindMarketSale", "Sale")
	royaltyIdentifier := otu.identifier("FindMarket", "RoyaltyPaid")

	mintFund := otu.O.TxFN(
		WithSigner("account"),
		WithArg("amount", 10000.0),
		WithArg("recipient", "user2"),
	)
	id := otu.mintThreeExampleDandies()[0]

	listingTx := otu.O.TxFN(
		WithSigner("user1"),
		WithArg("marketplace", "find"),
		WithArg("nftAliasOrIdentifier", "Dandy"),
		WithArg("nftAliasOrIdentifier", dandyNFTType(otu)),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("directSellPrice", 0.0),
		WithArg("validUntil", otu.currentTime()+100.0),
	)

	otu.registerFtInRegistry()

	t.Run("Should be able to list a dandy for sale and buy it", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)

		otu.checkRoyalty("user1", id, "find forge", dandyNFTType(otu), 0.025)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyNFTForMarketSale("user2", "user1", id, price).
			sendDandy("user1", "user2", id)

	})

	t.Run("Should be able to list a dandy for sale if seller didn't link provider correctly", func(t *testing.T) {
		otu.unlinkDandyProvider("user1").
			listNFTForSale("user1", id, price).
			cancelAllNFTForSale("user1")

	})

	t.Run("Should be able to list a dandy for sale and buy it if buyer didn't receiver that correctly", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price).
			unlinkDandyReceiver("user2").
			buyNFTForMarketSale("user2", "user1", id, price).
			sendDandy("user1", "user2", id)
	})

	t.Run("Should be able to list a dandy for sale and buy it without the collection", func(t *testing.T) {
		otu.listNFTForSale("user1", id, price).
			destroyDandyCollection("user2").
			buyNFTForMarketSale("user2", "user1", id, price).
			sendDandy("user1", "user2", id)
	})

	t.Run("Should not be able to list with price $0", func(t *testing.T) {

		listingTx("listNFTForSale",
			WithArg("directSellPrice", 0.0),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Listing price should be greater than 0")

	})

	t.Run("Should not be able to list with invalid time", func(t *testing.T) {

		listingTx("listNFTForSale",
			WithArg("directSellPrice", price),
			WithArg("validUntil", 0.0),
		).
			AssertFailure(t, "Valid until is before current time")
	})

	t.Run("Should be ableto cancel listing if the pointer is no longer valid", func(t *testing.T) {

		otu.setUUID(800)

		otu.listNFTForSale("user1", id, price).
			sendDandy("user3", "user1", id)

		otu.O.Tx("delistNFTSale",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", []uint64{id}),
		).
			AssertSuccess(t)

		otu.sendDandy("user1", "user3", id)

	})

	t.Run("Should be able to change price of dandy", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)

		newPrice := 15.0
		otu.listNFTForSale("user1", id, newPrice)
		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, newPrice, itemsForSale[0].Amount)

		otu.cancelAllNFTForSale("user1")

	})

	t.Run("Should not be able to buy your own listing", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "You cannot buy your own listing")
	})

	t.Run("Should not be able to buy expired listing", func(t *testing.T) {

		otu.tickClock(200.0)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "This sale item listing is already expired")

		otu.cancelAllNFTForSale("user1")
	})

	t.Run("Should be able to cancel sale", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)

		otu.cancelNFTForSale("user1", id)
		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 0, len(itemsForSale))
	})

	t.Run("Should not be able to buy if too low price", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", 5.0),
		).
			AssertFailure(t, "Incorrect balance sent in vault. Expected 10.00000000 got 5.00000000")

		otu.cancelAllNFTForSale("user1")
	})

	t.Run("Should be able to list it in Flow but not FUSD.", func(t *testing.T) {

		listingTx("listNFTForSale",
			WithArg("ftAliasOrIdentifier", "FUSD"),
			WithArg("validUntil", otu.currentTime()+100.0),
		).AssertFailure(t, "Nothing matches")
	})

	t.Run("Should be able cancel all listing", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.listNFTForSale("user1", ids[0], price)
		otu.listNFTForSale("user1", ids[1], price)
		otu.listNFTForSale("user1", ids[2], price)

		scriptResult := otu.O.Script("getStatus", WithArg("user", "user1"))
		scriptResult.AssertWithPointerWant(t, "/FINDReport/itemsForSale/FindMarketSale/items/0/saleType", autogold.Want("firstSaleItem", "active_listed"))
		scriptResult.AssertLengthWithPointer(t, "/FINDReport/itemsForSale/FindMarketSale/items", 3)

		otu.O.Tx("delistAllNFTSale",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
		).AssertSuccess(t)
		//TODO: assert on events

		scriptResultAfter := otu.O.Script("getStatus", WithArg("user", "user1"))
		scriptResultAfter.AssertWithPointerError(t, "/FINDReport/itemsForSale", "Object has no key 'itemsForSale'")
	})

	t.Run("Should be able to list it, deprecate it and cannot list another again, but able to buy and delist.", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, price, itemsForSale[0].Amount)

		otu.alterMarketOption("Sale", "deprecate")

		listingTx("listNFTForSale",
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("id", ids[1]),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has deprected mutation options on this item")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("id", ids[0]),
			WithArg("amount", price),
		).
			AssertSuccess(t)

		otu.alterMarketOption("Sale", "enable")

		otu.listNFTForSale("user1", ids[1], price)

		otu.alterMarketOption("Sale", "deprecate")

		otu.O.Tx("delistNFTSale",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", ids[1:1]),
		).
			AssertSuccess(t)

		otu.alterMarketOption("Sale", "enable")

		otu.O.Tx("delistAllNFTSale",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
		).
			AssertSuccess(t)

	})

	t.Run("Should be able to list it, stop it and cannot list another again, buy, nor delist.", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, price, itemsForSale[0].Amount)

		otu.alterMarketOption("Sale", "stop")

		listingTx("listNFTForSale",
			WithArg("id", ids[1]),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("id", ids[0]),
			WithArg("amount", price),
		).
			AssertFailure(t, "Tenant has stopped this item")

		otu.alterMarketOption("Sale", "enable")
		otu.cancelAllNFTForSale("user1")

	})

	t.Run("Should be able to purchase, list and delist items after enabled market option..", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, price, itemsForSale[0].Amount)

		listingTx("listNFTForSale",
			WithArg("id", ids[1]),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("id", ids[0]),
			WithArg("amount", price),
		).
			AssertSuccess(t)

		listingTx("listNFTForSale",
			WithSigner("user2"),
			WithArg("id", ids[0]),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		otu.cancelNFTForSale("user2", ids[0])
		itemsForSale = otu.getItemsForSale("user2")
		assert.Equal(t, 0, len(itemsForSale))
	})

	/* Testing on Royalties */

	// platform 0.15
	// artist 0.05
	// find 0.025
	// tenant nil
	t.Run("Royalties should be sent to correspondence upon buy action", func(t *testing.T) {
		otu.cancelAllNFTForSale("user1")
		ids := otu.mintThreeExampleDandies()
		otu.listNFTForSale("user1", ids[0], price)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("id", ids[0]),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"id":          ids[0],
				"royaltyName": "find",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          ids[0],
				"royaltyName": "creator",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"id":          ids[0],
				"royaltyName": "find forge",
				"tenant":      "find",
			})

	})

	t.Run("Royalties of find platform should be able to change", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.setFindCut(0.035)
		otu.listNFTForSale("user1", ids[0], price)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("id", ids[0]),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.35,
				"id":          ids[0],
				"royaltyName": "find",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("user1"),
				"amount":      0.5,
				"findName":    "user1",
				"id":          ids[0],
				"royaltyName": "creator",
				"tenant":      "find",
			}).
			AssertEvent(t, royaltyIdentifier, map[string]interface{}{
				"address":     otu.O.Address("find"),
				"amount":      0.25,
				"id":          ids[0],
				"royaltyName": "find forge",
				"tenant":      "find",
			})
	})

	/* Honour Banning */
	t.Run("Should be able to ban user, user is only allowed to cancel listing.", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)
		otu.profileBan("user1")

		listingTx("listNFTForSale",
			WithSigner("user1"),
			WithArg("id", id),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Seller banned by Tenant")

		otu.cancelNFTForSale("user1", id).
			removeProfileBan("user1")
	})

	t.Run("Should be able to ban user, user cannot buy NFT.", func(t *testing.T) {

		otu.listNFTForSale("user1", id, price)
		otu.profileBan("user2")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("id", id),
			WithArg("amount", price),
		).
			AssertFailure(t, "Buyer banned by Tenant")

		otu.removeProfileBan("user2").
			cancelNFTForSale("user1", id).
			removeProfileBan("user2")
	})

	t.Run("Royalties should try to borrow vault in standard way if profile wallet is unlinked", func(t *testing.T) {
		otu.setTenantRuleFUSD("FlowDandySale").
			removeTenantRule("FlowDandySale", "Flow")

		ids := otu.mintThreeExampleDandies()
		otu.sendDandy("user3", "user1", ids[0])

		listingTx("listNFTForSale",
			WithSigner("user3"),
			WithArg("id", ids[0]),
			WithArg("ftAliasOrIdentifier", "FUSD"),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		otu.unlinkProfileWallet("user1")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user3"),
			WithArg("id", ids[0]),
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

		otu.cancelAllNFTForSale("user1")
	})

	t.Run("Royalties should try to borrow vault in standard way if profile wallet does not exist", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.sendDandy("user3", "user1", ids[0])

		listingTx("listNFTForSale",
			WithSigner("user3"),
			WithArg("id", ids[0]),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		otu.removeProfileWallet("user1")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user3"),
			WithArg("id", ids[0]),
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

		otu.cancelAllNFTForSale("user1")
	})

	t.Run("Royalties should be sent to residual account if royalty receiver is not working", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.sendDandy("user3", "user1", ids[0])

		listingTx("listNFTForSale",
			WithSigner("user3"),
			WithArg("id", ids[0]),
			WithArg("ftAliasOrIdentifier", "FUSD"),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		otu.destroyFUSDVault("user1")

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user3"),
			WithArg("id", ids[0]),
			WithArg("amount", price),
		).
			AssertSuccess(t).
			AssertEvent(t,
				"FindMarket.RoyaltyCouldNotBePaid",
				map[string]interface{}{
					"address":         otu.O.Address("user1"),
					"amount":          0.5,
					"findName":        "user1",
					"residualAddress": otu.O.Address("find-admin"),
					"royaltyName":     "creator",
				},
			)

		otu.cancelAllNFTForSale("user1")
	})

	t.Run("Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {
		otu.registerDUCInRegistry().
			setDUCExampleNFT().
			sendExampleNFT("user1", "find")

		saleItemID := otu.listNFTForSaleDUC("user1", 0, price)

		otu.checkRoyalty("user1", 0, "creator", exampleNFTType(otu), 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.getNFTForMarketSale("user1", saleItemID[0], price)

		otu.buyNFTForMarketSaleDUC("user2", "user1", saleItemID[0], price).
			sendExampleNFT("user1", "user2")

	})

	t.Run("Should be able to list an NFT for sale and buy it. where id != uuid", func(t *testing.T) {
		saleItem := otu.listExampleNFTForSale("user1", 0, price)

		otu.checkRoyalty("user1", 0, "creator", exampleNFTType(otu), 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.buyNFTForMarketSale("user2", "user1", saleItem[0], price).
			sendExampleNFT("user1", "user2")
		otu.cancelAllNFTForSale("user1")

		otu.cancelAllNFTForSale("user1")

	})

	t.Run("Should be able to list multiple dandies for sale and buy them in one go", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		otu.O.Tx("listMultipleNFTForSale",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("nftAliasOrIdentifiers", []string{dandyNFTType(otu), dandyNFTType(otu), dandyNFTType(otu)}),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", []string{"FUSD", "FUSD", "FUSD"}),
			WithArg("directSellPrices", `[10.0 , 10.0, 10.0]`),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		scriptResult := otu.O.Script("getStatus", WithArg("user", "user1"))

		var itemsForSale []SaleItemInformation
		err := scriptResult.MarshalPointerAs("/FINDReport/itemsForSale/FindMarketSale/items", &itemsForSale)

		assert.NoError(t, err)
		assert.Equal(t, 3, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
		assert.Equal(t, "active_listed", itemsForSale[1].SaleType)
		assert.Equal(t, "active_listed", itemsForSale[2].SaleType)

		seller := "user1"
		name := "user2"

		otu.O.Tx("buyMultipleNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithAddresses("users", "user1", "user1", "user1"),
			WithArg("ids", ids),
			WithArg("amounts", `[10.0 , 10.0, 10.0]`),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount": price,
				"id":     ids[0],
				"seller": otu.O.Address(seller),
				"buyer":  otu.O.Address(name),
				"status": "sold",
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount": price,
				"id":     ids[1],
				"seller": otu.O.Address(seller),
				"buyer":  otu.O.Address(name),
				"status": "sold",
			}).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount": price,
				"id":     ids[2],
				"seller": otu.O.Address(seller),
				"buyer":  otu.O.Address(name),
				"status": "sold",
			})

	})

	t.Run("Should be able to list 15 dandies in one go", func(t *testing.T) {

		number := 15

		mintFund("devMintFusd").AssertSuccess(t)

		ids := otu.mintThreeExampleDandies()
		dandy := []string{dandyNFTType(otu), dandyNFTType(otu), dandyNFTType(otu)}
		fusd := []string{"FUSD", "FUSD", "FUSD"}
		prices := "[ 15.0, 15.0, 15.0 "

		for len(ids) < number {
			id := otu.mintThreeExampleDandies()
			ids = append(ids, id...)
		}

		ids = ids[:number]

		for len(dandy) < number {
			dandy = append(dandy, dandy[0])
			fusd = append(fusd, fusd[0])
			prices = prices + ", 15.0"
		}
		prices = prices + "]"

		// list multiple NFT for sale

		otu.O.Tx("listMultipleNFTForSale",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("nftAliasOrIdentifiers", dandy),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", fusd),
			WithArg("directSellPrices", prices),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		otu.cancelAllNFTForSale("user1")

	})

	t.Run("Should be able to buy at max 5 dandies", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		dandy := []string{dandyNFTType(otu), dandyNFTType(otu), dandyNFTType(otu)}
		fusd := []string{"FUSD", "FUSD", "FUSD"}
		prices := "[ 10.0, 10.0, 10.0 , 10.0, 10.0]"
		buyers := []string{"user1", "user1", "user1"}

		id := otu.mintThreeExampleDandies()
		ids = append(ids, id[0], id[1])
		dandy = append(dandy, []string{dandyNFTType(otu), dandyNFTType(otu)}...)
		fusd = append(fusd, []string{"FUSD", "FUSD"}...)
		buyers = append(buyers, []string{"user1", "user1"}...)

		// list multiple NFT for sale

		otu.O.Tx("listMultipleNFTForSale",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("nftAliasOrIdentifiers", dandy),
			WithArg("ids", ids),
			WithArg("ftAliasOrIdentifiers", fusd),
			WithArg("directSellPrices", prices),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t)

		otu.O.Tx("buyMultipleNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithAddresses("users", buyers...),
			WithArg("ids", ids),
			WithArg("amounts", prices),
		).
			AssertSuccess(t)

		otu.cancelAllNFTForSale("user1")

	})

	t.Run("Should be able to list ExampleNFT for sale and buy it with DUC using MultipleNFT transaction", func(t *testing.T) {

		saleItemID := otu.O.Tx("listMultipleNFTForSaleDUC",
			WithSigner("user1"),
			WithArg("dapperAddress", "find"),
			WithArg("marketplace", "find"),
			WithArg("nftAliasOrIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("ids", []uint64{0}),
			WithArg("directSellPrices", `[10.0]`),
			WithArg("validUntil", otu.currentTime()+100.0),
		).
			AssertSuccess(t).
			GetIdsFromEvent(eventIdentifier, "id")

		otu.checkRoyalty("user1", 0, "creator", exampleNFTType(otu), 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.O.Tx("buyMultipleNFTForSaleDUC",
			WithSigner("user2"),
			WithPayloadSigner("dapper"),
			WithArg("dapperAddress", "find"),
			WithArg("marketplace", "find"),
			WithArg("users", `["user1"]`),
			WithArg("ids", saleItemID[0:1]),
			WithArg("amounts", `[10.0]`),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIdentifier, map[string]interface{}{
				"amount": price,
				"id":     saleItemID[0],
				"seller": otu.O.Address("user1"),
				"buyer":  otu.O.Address("user2"),
				"status": "sold",
			})

		otu.sendExampleNFT("user1", "user2")

	})

	t.Run("Should not be able to list soul bound items", func(t *testing.T) {
		otu.sendSoulBoundNFT("user1", "find")
		// set market rules
		otu.O.Tx("adminSetSellExampleNFTForFlow",
			WithSigner("find"),
			WithArg("tenant", "find"),
		)

		otu.O.Tx("listNFTForSale",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("nftAliasOrIdentifier", exampleNFTType(otu)),
			WithArg("id", 1),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("directSellPrice", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		).AssertFailure(t, "This item is soul bounded and cannot be traded")

		listingTx("listNFTForSale",
			WithSigner("user1"),
			WithArg("nftAliasOrIdentifier", exampleNFTType(otu)),
			WithArg("id", 1),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("directSellPrice", price),
			WithArg("validUntil", otu.currentTime()+100.0),
		)

	})

	t.Run("not be able to buy an NFT with changed royalties, but should be able to cancel listing", func(t *testing.T) {
		saleItem := otu.listExampleNFTForSale("user1", 0, price)

		otu.checkRoyalty("user1", 0, "creator", exampleNFTType(otu), 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.changeRoyaltyExampleNFT("user1", 0)

		otu.checkRoyalty("user1", 0, "cheater", exampleNFTType(otu), 0.99)

		otu.O.Tx("buyNFTForSale",
			WithSigner("user2"),
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
			WithArg("id", saleItem[0]),
			WithArg("amount", price),
		).
			AssertFailure(t, "The total Royalties to be paid is changed after listing.")

		otu.O.Tx("delistNFTSale",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", saleItem[0:1]),
		).
			AssertSuccess(t)

		otu.changeRoyaltyExampleNFT("user1", 0)
	})

	t.Run("should be able to get listings with royalty problems and relist", func(t *testing.T) {
		otu.listExampleNFTForSale("user1", 0, price)

		otu.checkRoyalty("user1", 0, "creator", exampleNFTType(otu), 0.01)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 1, len(itemsForSale))
		assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

		otu.changeRoyaltyExampleNFT("user1", 0)

		otu.checkRoyalty("user1", 0, "cheater", exampleNFTType(otu), 0.99)

		ids, err := otu.O.Script("getRoyaltyChangedIds",
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
		).
			GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.O.Tx("relistMarketListings",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", ids),
		).
			AssertSuccess(t)

	})

	t.Run("should be able to get listings with royalty problems and cancel", func(t *testing.T) {
		otu.changeRoyaltyExampleNFT("user1", 0)

		ids, err := otu.O.Script("getRoyaltyChangedIds",
			WithArg("marketplace", "find"),
			WithArg("user", "user1"),
		).
			GetAsJson()

		if err != nil {
			panic(err)
		}

		otu.O.Tx("cancelMarketListings",
			WithSigner("user1"),
			WithArg("marketplace", "find"),
			WithArg("ids", ids),
		).
			AssertSuccess(t)

	})

}
