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

	/*
						t.Run("Should be able to list an NFT for sale and buy it with DUC", func(t *testing.T) {

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

						t.Run("Should be able to list an NFT for sale and buy it with DUC, royalties should be paid to merch account", func(t *testing.T) {

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

						t.Run("Should be able to list an NFT for sale and buy it with DUC, royalties should be paid to merch account if royalty is higher than 0.44", func(t *testing.T) {

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

						t.Run("Royalties should be sent to dapper residual account if royalty receiver is not working", func(t *testing.T) {

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

					//TODO: We do not support multiple buy in the FT regardless
					ot.Run(t, "Should be able to list multiple dandies for sale and buy them in one go", func(t *testing.T) {
						otu.O.Tx("listMultipleNFTForSale",
							WithSigner("user1"),
							WithArg("nftAliasOrIdentifiers", []string{dandyIdentifier, dandyIdentifier, dandyIdentifier}),
							WithArg("ids", dandyIds),
							WithArg("ftAliasOrIdentifiers", []string{"Flow", "Flow", "Flow"}),
							WithArg("directSellPrices", `[10.0 , 10.0, 10.0]`),
							WithArg("validUntil", otu.currentTime()+100.0),
						).AssertSuccess(t)

						scriptResult := otu.O.Script("getFindMarket", WithArg("user", "user1"))

						var itemsForSale []SaleItemInformation
						err := scriptResult.MarshalPointerAs("/itemsForSale/FindMarketSale/items", &itemsForSale)

						assert.NoError(t, err)
						assert.Equal(t, 3, len(itemsForSale))
						assert.Equal(t, "active_listed", itemsForSale[0].SaleType)
						assert.Equal(t, "active_listed", itemsForSale[1].SaleType)
						assert.Equal(t, "active_listed", itemsForSale[2].SaleType)

						seller := "user1"
						name := "user2"

						otu.O.Tx("buyMultipleNFTForSale",
							WithSigner("user2"),
							WithAddresses("users", "user1", "user1", "user1"),
							WithArg("ids", dandyIds),
							WithArg("amounts", `[10.0 , 10.0, 10.0]`),
						).
							AssertSuccess(t).
							AssertEvent(t, eventIdentifier, map[string]interface{}{
								"amount": price,
								"id":     dandyIds[0],
								"seller": otu.O.Address(seller),
								"buyer":  otu.O.Address(name),
								"status": "sold",
							}).
							AssertEvent(t, eventIdentifier, map[string]interface{}{
								"amount": price,
								"id":     dandyIds[1],
								"seller": otu.O.Address(seller),
								"buyer":  otu.O.Address(name),
								"status": "sold",
							}).
							AssertEvent(t, eventIdentifier, map[string]interface{}{
								"amount": price,
								"id":     dandyIds[2],
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
								WithArg("nftAliasOrIdentifiers", dandy),
								WithArg("ids", ids),
								WithArg("ftAliasOrIdentifiers", fusd),
								WithArg("directSellPrices", prices),
								WithArg("validUntil", otu.currentTime()+100.0),
							).
								AssertSuccess(t)

							otu.O.Tx("buyMultipleNFTForSale",
								WithSigner("user2"),
								WithAddresses("users", buyers...),
								WithArg("ids", ids),
								WithArg("amounts", prices),
							).
								AssertSuccess(t)

							otu.cancelAllNFTForSale("user1")

						})

						t.Run("Should be able to list ExampleNFT for sale and buy it with DUC using MultipleNFT transaction", func(t *testing.T) {

							ftIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
							assert.NoError(t, err)

							saleItemID := otu.O.Tx("listMultipleNFTForSaleDapper",
								WithSigner("user1"),
								WithArg("nftAliasOrIdentifiers", []string{exampleNFTType(otu)}),
								WithArg("ids", []uint64{0}),
								WithArg("ftAliasOrIdentifiers", []string{ftIden}),
								WithArg("directSellPrices", `[10.0]`),
								WithArg("validUntil", otu.currentTime()+100.0),
							).
								AssertSuccess(t).
								GetIdsFromEvent(eventIdentifier, "id")

							otu.checkRoyalty("user1", 0, "creator", exampleNFTType(otu), 0.01)

							itemsForSale := otu.getItemsForSale("user1")
							assert.Equal(t, 1, len(itemsForSale))
							assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

							otu.O.Tx("buyMultipleNFTForSaleDapper",
								WithSigner("user2"),
								WithPayloadSigner("dapper"),
								WithAddresses("users", "user1"),
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

							otu.sendExampleNFT("user1", "user2", 0)

						})


			  //TODO: do not have test data with soul bound
				t.Run("Should not be able to list soul bound items", func(t *testing.T) {
					otu.sendSoulBoundNFT("user1", "find")
					// set market rules
					otu.O.Tx("adminSetSellExampleNFTForFlow",
						WithSigner("find"),
						WithArg("tenant", "find"),
					)

					otu.O.Tx("listNFTForSale",
						WithSigner("user1"),
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

			otu.changeRoyaltyExampleNFT("user1", 0, true)

			otu.checkRoyalty("user1", 0, "cheater", exampleNFTType(otu), 0.99)

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

		t.Run("should be able to get listings with royalty problems and relist", func(t *testing.T) {
			otu.listExampleNFTForSale("user1", 0, price)

			otu.checkRoyalty("user1", 0, "creator", exampleNFTType(otu), 0.01)

			itemsForSale := otu.getItemsForSale("user1")
			assert.Equal(t, 1, len(itemsForSale))
			assert.Equal(t, "active_listed", itemsForSale[0].SaleType)

			otu.changeRoyaltyExampleNFT("user1", 0, true)

			otu.checkRoyalty("user1", 0, "cheater", exampleNFTType(otu), 0.99)

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
			).
				AssertSuccess(t)
		})

		t.Run("should be able to get listings with royalty problems and cancel", func(t *testing.T) {
			otu.changeRoyaltyExampleNFT("user1", 0, false)

			ids, err := otu.O.Script("getRoyaltyChangedIds",
				WithArg("user", "user1"),
			).
				GetAsJson()
			if err != nil {
				panic(err)
			}

			otu.O.Tx("cancelMarketListings",
				WithSigner("user1"),
				WithArg("ids", ids),
			).
				AssertSuccess(t)
		})
	*/
}
