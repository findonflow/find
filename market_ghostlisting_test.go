package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestMarketGhostlistingTest(t *testing.T) {

	price := 10.0
	bidPrice := 15.0

	// /* MarketSale */
	// t.Run("Should not be able to fullfill sale if item was already sold on direct offer", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("Sale").
	// 		listNFTForSale("user1", id, price)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 1, len(itemsForSale))
	// 	assert.Equal(t, "directSale", itemsForSale[0].SaleType)

	// 	otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

	// 	itemsForSale = otu.getItemsForSale("user1")
	// 	assert.Equal(t, 2, len(itemsForSale))
	// 	assert.Equal(t, "directSale", itemsForSale[0].SaleType)
	// 	assert.Equal(t, "directoffer", itemsForSale[1].SaleType)

	// 	otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

	// 	otu.O.TransactionFromFile("buyItemForSale").
	// 		SignProposeAndPayAs("user2").
	// 		Args(otu.O.Arguments().
	// 			Account("user1").
	// 			UInt64(id).
	// 			UFix64(price)).
	// 		Test(otu.T).AssertFailure("This listing is a ghost listing")

	// })

	// /* MarketAuction Escrowed */
	// t.Run("Should not be able to bid Auction if item was already sold on direct offer", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("AuctionEscrow").
	// 		listNFTForEscrowedAuction("user1", id, price)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 1, len(itemsForSale))
	// 	assert.Equal(t, "ondemand_auction", itemsForSale[0].SaleType)

	// 	otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

	// 	itemsForSale = otu.getItemsForSale("user1")
	// 	assert.Equal(t, 2, len(itemsForSale))
	// 	assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
	// 	assert.Equal(t, "ondemand_auction", itemsForSale[1].SaleType)

	// 	otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

	// 	otu.O.TransactionFromFile("bidMarketAuctionEscrowed").
	// 		SignProposeAndPayAs("user2").
	// 		Args(otu.O.Arguments().
	// 			Account("user1").
	// 			UInt64(id).
	// 			UFix64(bidPrice)).
	// 		Test(otu.T).AssertFailure("This listing is a ghost listing")

	// })

	// t.Run("Should not be able to increase bid in Auction if item was already sold on direct offer", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("AuctionEscrow").
	// 		listNFTForEscrowedAuction("user1", id, price).
	// 		auctionBidMarketEscrow("user2", "user1", id, bidPrice)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 1, len(itemsForSale))
	// 	assert.Equal(t, "ongoing_auction", itemsForSale[0].SaleType)

	// 	otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

	// 	itemsForSale = otu.getItemsForSale("user1")
	// 	assert.Equal(t, 2, len(itemsForSale))
	// 	assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
	// 	assert.Equal(t, "ongoing_auction", itemsForSale[1].SaleType)

	// 	otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

	// 	otu.O.TransactionFromFile("increaseBidMarketAuctionEscrowed").
	// 		SignProposeAndPayAs("user2").
	// 		Args(otu.O.Arguments().
	// 			UInt64(id).
	// 			UFix64(bidPrice + 1.0)).
	// 		Test(otu.T).AssertFailure("This bid is on a ghostlisting, so you should cancel the original bid and get your funds back")

	// })

	// t.Run("Should not be able to fulfill bid in Auction if item was already sold on direct offer", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("AuctionEscrow").
	// 		listNFTForEscrowedAuction("user1", id, price).
	// 		auctionBidMarketEscrow("user2", "user1", id, bidPrice).
	// 		tickClock(700)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 1, len(itemsForSale))
	// 	assert.Equal(t, "ongoing_auction", itemsForSale[0].SaleType)

	// 	otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

	// 	itemsForSale = otu.getItemsForSale("user1")
	// 	assert.Equal(t, 2, len(itemsForSale))
	// 	assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
	// 	assert.Equal(t, "ongoing_auction", itemsForSale[1].SaleType)

	// 	otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

	// 	otu.O.TransactionFromFile("fulfillMarketAuctionEscrowed").
	// 		SignProposeAndPayAs("user2").
	// 		Args(otu.O.Arguments().
	// 			Address("user1").
	// 			UInt64(id)).
	// 		Test(otu.T).AssertFailure("NFT does not exist")

	// })

	// /* MarketAuction Soft */
	// t.Run("Should not be able to bid Auction soft if item was already sold on direct offer", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("AuctionSoft").
	// 		listNFTForSoftAuction("user1", id, price)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 1, len(itemsForSale))
	// 	assert.Equal(t, "ondemand_auction", itemsForSale[0].SaleType)

	// 	otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

	// 	itemsForSale = otu.getItemsForSale("user1")
	// 	assert.Equal(t, 2, len(itemsForSale))
	// 	assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
	// 	assert.Equal(t, "ondemand_auction", itemsForSale[1].SaleType)

	// 	otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

	// 	otu.O.TransactionFromFile("bidMarketAuctionSoft").
	// 		SignProposeAndPayAs("user2").
	// 		Args(otu.O.Arguments().
	// 			Account("user1").
	// 			UInt64(id).
	// 			UFix64(bidPrice)).
	// 		Test(otu.T).AssertFailure("This listing is a ghost listing")

	// })

	// t.Run("Should not be able to increase bid in Auction Soft if item was already sold on direct offer", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("AuctionSoft").
	// 		listNFTForSoftAuction("user1", id, price).
	// 		auctionBidMarketSoft("user2", "user1", id, bidPrice)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 1, len(itemsForSale))
	// 	assert.Equal(t, "ongoing_auction", itemsForSale[0].SaleType)

	// 	otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

	// 	itemsForSale = otu.getItemsForSale("user1")
	// 	assert.Equal(t, 2, len(itemsForSale))
	// 	assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
	// 	assert.Equal(t, "ongoing_auction", itemsForSale[1].SaleType)

	// 	otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

	// 	otu.O.TransactionFromFile("increaseBidMarketAuctionSoft").
	// 		SignProposeAndPayAs("user2").
	// 		Args(otu.O.Arguments().
	// 			UInt64(id).
	// 			UFix64(bidPrice + 1.0)).
	// 		Test(otu.T).AssertFailure("This bid is on a ghostlisting, so you should cancel the original bid and get your funds back")

	// })

	// t.Run("Should not be able to fulfill bid in Auction if item was already sold on direct offer", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("AuctionSoft").
	// 		listNFTForSoftAuction("user1", id, price).
	// 		auctionBidMarketSoft("user2", "user1", id, bidPrice).
	// 		tickClock(700)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 1, len(itemsForSale))
	// 	assert.Equal(t, "ongoing_auction", itemsForSale[0].SaleType)

	// 	otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

	// 	itemsForSale = otu.getItemsForSale("user1")
	// 	assert.Equal(t, 2, len(itemsForSale))
	// 	assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
	// 	assert.Equal(t, "ongoing_auction", itemsForSale[1].SaleType)

	// 	otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

	// 	otu.O.TransactionFromFile("fulfillMarketAuctionSoft").
	// 		SignProposeAndPayAs("user2").
	// 		Args(otu.O.Arguments().
	// 			UInt64(id)).
	// 		Test(otu.T).AssertFailure("Cannot fulfill market auction on ghost listing")

	// })

	// /* Direct Offer Escrowed */ // This is not likely to happen
	// t.Run("Should not be able to make Direct Offer if item was already sold on direct offer", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("AuctionSoft")

	// 	otu.directOfferMarketEscrowed("user2", "user1", id, 15.0)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 1, len(itemsForSale))
	// 	assert.Equal(t, "directoffer", itemsForSale[0].SaleType)

	// 	otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", 15.0)

	// 	otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
	// 		SignProposeAndPayAs("user2").
	// 		Args(otu.O.Arguments().
	// 			Account("user1").
	// 			String("Dandy").
	// 			UInt64(id).
	// 			String("Flow").
	// 			UFix64(price)).
	// 		Test(otu.T).AssertFailure("NFT does not exist")

	// })

	// t.Run("Should not be able to fulfill Direct Offer if item was already sold in other form", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("DirectOfferSoft").
	// 		directOfferMarketEscrowed("user2", "user1", id, price)

	// 	otu.directOfferMarketSoft("user2", "user1", id, price)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 2, len(itemsForSale))
	// 	assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
	// 	assert.Equal(t, "directoffer_soft", itemsForSale[1].SaleType)

	// 	otu.acceptDirectOfferMarketSoft("user1", id, "user2", price).
	// 		fulfillMarketDirectOfferSoft("user2", id, price)

	// 	otu.O.TransactionFromFile("fulfillMarketDirectOfferEscrowed").
	// 		SignProposeAndPayAs("user1").
	// 		Args(otu.O.Arguments().
	// 			UInt64(id)).
	// 		Test(otu.T).AssertFailure("NFT does not exist")

	// })

	// t.Run("Should not be able to make Direct Offer Soft if item was already sold in other form", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("DirectOfferSoft")

	// 	otu.directOfferMarketEscrowed("user2", "user1", id, price)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 1, len(itemsForSale))
	// 	assert.Equal(t, "directoffer", itemsForSale[0].SaleType)

	// 	otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

	// 	otu.O.TransactionFromFile("bidMarketDirectOfferEscrowed").
	// 		SignProposeAndPayAs("user2").
	// 		Args(otu.O.Arguments().
	// 			Account("user1").
	// 			String("Dandy").
	// 			UInt64(id).
	// 			String("Flow").
	// 			UFix64(price)).
	// 		Test(otu.T).AssertFailure("NFT does not exist")

	// })

	// t.Run("Should not be able to accept Direct Offer Soft if item was already sold in other form", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("DirectOfferSoft").
	// 		directOfferMarketSoft("user2", "user1", id, price)

	// 	otu.directOfferMarketEscrowed("user2", "user1", id, price)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 2, len(itemsForSale))
	// 	assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
	// 	assert.Equal(t, "directoffer_soft", itemsForSale[1].SaleType)

	// 	otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

	// 	otu.O.TransactionFromFile("acceptDirectOfferSoft").
	// 		SignProposeAndPayAs("user1").
	// 		Args(otu.O.Arguments().
	// 			UInt64(id)).
	// 		Test(otu.T).AssertFailure("This offer is made on a ghost listing")

	// })

	// t.Run("Should not be able to fulfill Direct Offer Soft if item was already sold in other form", func(t *testing.T) {
	// 	otu := NewOverflowTest(t)

	// 	id := otu.setupMarketAndDandy()
	// 	otu.registerFlowFUSDDandyInRegistry().
	// 		setFlowDandyMarketOption("DirectOfferEscrow").
	// 		setFlowDandyMarketOption("DirectOfferSoft").
	// 		directOfferMarketSoft("user2", "user1", id, price).
	// 		acceptDirectOfferMarketSoft("user1", id, "user2", price)

	// 	otu.directOfferMarketEscrowed("user2", "user1", id, price)

	// 	itemsForSale := otu.getItemsForSale("user1")
	// 	assert.Equal(t, 2, len(itemsForSale))
	// 	assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
	// 	assert.Equal(t, "directoffer_soft_accepted", itemsForSale[1].SaleType)

	// 	otu.acceptDirectOfferMarketEscrowed("user1", id, "user2", price)

	// 	otu.O.TransactionFromFile("fulfillMarketDirectOfferSoft").
	// 		SignProposeAndPayAs("user2").
	// 		Args(otu.O.Arguments().
	// 			UInt64(id)).
	// 		Test(otu.T).AssertFailure("Cannot fulfill market offer on ghost listing")

	// })

	t.Run("Should be able to return ghost listings with script address_status and name_status", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			directOfferMarketSoft("user2", "user1", ids[0], price).
			acceptDirectOfferMarketSoft("user1", ids[0], "user2", price).
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", ids[1], price)

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 3, len(itemsForSale))
		assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
		assert.Equal(t, "ondemand_auction", itemsForSale[1].SaleType)
		assert.Equal(t, "directoffer_soft_accepted", itemsForSale[2].SaleType)

		otu.acceptDirectOfferMarketEscrowed("user1", ids[0], "user2", price)

		expectedGhost := []interface{}([]interface{}{
			map[string]interface{}{
				"id":                    "124",
				"listingType":           "Type<A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.SaleItem>()",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.SaleItem"}})

		expectedListings := []interface{}([]interface{}{
			map[string]interface{}{
				"amount": "10.00000000",
				"auction": map[string]interface{}{
					"extentionOnLateBid":  "60.00000000",
					"minimumBidIncrement": "1.00000000",
					"reservePrice":        "15.00000000",
					"startPrice":          "10.00000000"},
				"bidder":                "",
				"bidderName":            "",
				"ftAlias":               "Flow",
				"ftTypeIdentifier":      "A.0ae53cb6e3f42a79.FlowToken.Vault",
				"listingId":             "125",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem",
				"listingValidUntil":     "",
				"nft": map[string]interface{}{
					"description": "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK",
					"id":          "125",
					"name":        "Neo Motorcycle 2 of 3",
					"thumbnail":   "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"type":        "A.f8d6e0586b0a20c7.Dandy.NFT"},
				"nftId":         "125",
				"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
				"saleType":      "ondemand_auction",
				"seller":        "0x179b6b1cb6755e31",
				"sellerName":    "user1"}})

		result := otu.O.ScriptFromFile("address_status").
			Args(otu.O.Arguments().
				Address("user1")).
			RunReturnsInterface()

		ghost := result.(map[string]interface{})["itemsForSale"].(map[string]interface{})["A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.SaleItem"].(map[string]interface{})["ghosts"]
		listings := result.(map[string]interface{})["itemsForSale"].(map[string]interface{})["A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem"].(map[string]interface{})["items"]

		assert.Equal(otu.T, expectedGhost, ghost)
		assert.Equal(otu.T, expectedListings, listings)

		result = otu.O.ScriptFromFile("name_status").
			Args(otu.O.Arguments().
				String("user1")).
			RunReturnsInterface()

		ghost = result.(map[string]interface{})["itemsForSale"].(map[string]interface{})["A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.SaleItem"].(map[string]interface{})["ghosts"]
		listings = result.(map[string]interface{})["itemsForSale"].(map[string]interface{})["A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem"].(map[string]interface{})["items"]

		assert.Equal(otu.T, expectedGhost, ghost)
		assert.Equal(otu.T, expectedListings, listings)
	})

	t.Run("Should be able to return ghost bids with script address_status and name_status", func(t *testing.T) {
		otu := NewOverflowTest(t)

		ids := otu.setupMarketAndMintDandys()
		otu.registerFlowFUSDDandyInRegistry().
			setFlowDandyMarketOption("DirectOfferEscrow").
			setFlowDandyMarketOption("DirectOfferSoft").
			directOfferMarketSoft("user2", "user1", ids[0], price).
			acceptDirectOfferMarketSoft("user1", ids[0], "user2", price).
			setFlowDandyMarketOption("AuctionEscrow").
			listNFTForEscrowedAuction("user1", ids[0], price).
			listNFTForEscrowedAuction("user1", ids[1], price).
			auctionBidMarketEscrow("user2", "user1", ids[0], bidPrice).
			auctionBidMarketEscrow("user2", "user1", ids[1], bidPrice)

		otu.directOfferMarketEscrowed("user2", "user1", ids[0], price)

		itemsForSale := otu.getItemsForSale("user1")
		assert.Equal(t, 4, len(itemsForSale))
		assert.Equal(t, "directoffer", itemsForSale[0].SaleType)
		assert.Equal(t, "ongoing_auction", itemsForSale[1].SaleType)
		assert.Equal(t, "ongoing_auction", itemsForSale[2].SaleType)
		assert.Equal(t, "directoffer_soft_accepted", itemsForSale[3].SaleType)

		otu.acceptDirectOfferMarketEscrowed("user1", ids[0], "user2", price)

		expectedGhostDirectOffer := []interface{}([]interface{}{
			map[string]interface{}{
				"id":                    "124",
				"listingType":           "Type<A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.Bid>()",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.Bid"}})

		expectedGhostAuctionEscrow := []interface{}([]interface{}{
			map[string]interface{}{
				"id":                    "124",
				"listingType":           "Type<A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid>()",
				"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid"}})

		expectedBids := []interface{}([]interface{}{
			map[string]interface{}{
				"id": "125",
				"item": map[string]interface{}{
					"amount": "15.00000000",
					"auction": map[string]interface{}{
						"extentionOnLateBid":  "60.00000000",
						"minimumBidIncrement": "1.00000000",
						"reservePrice":        "15.00000000",
						"startPrice":          "10.00000000"},
					"bidder":                "0xf3fcd2c1a78f5eee",
					"bidderName":            "user2",
					"ftAlias":               "Flow",
					"ftTypeIdentifier":      "A.0ae53cb6e3f42a79.FlowToken.Vault",
					"listingId":             "125",
					"listingTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.SaleItem",
					"listingValidUntil":     "301.00000000",
					"nft": map[string]interface{}{
						"description": "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK",
						"id":          "125",
						"name":        "Neo Motorcycle 2 of 3",
						"thumbnail":   "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
						"type":        "A.f8d6e0586b0a20c7.Dandy.NFT"},
					"nftId":         "125",
					"nftIdentifier": "A.f8d6e0586b0a20c7.Dandy.NFT",
					"saleType":      "ongoing_auction",
					"seller":        "0x179b6b1cb6755e31",
					"sellerName":    "user1"},
				"timestamp":         "1.00000000",
				"bidTypeIdentifier": "A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid"}})

		result := otu.O.ScriptFromFile("address_status").
			Args(otu.O.Arguments().
				Address("user2")).
			RunReturnsInterface()

		ghostDirectOffer := result.(map[string]interface{})["marketBids"].(map[string]interface{})["A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.Bid"].(map[string]interface{})["ghosts"]
		ghostAuctionEscrowed := result.(map[string]interface{})["marketBids"].(map[string]interface{})["A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid"].(map[string]interface{})["ghosts"]
		bids := result.(map[string]interface{})["marketBids"].(map[string]interface{})["A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid"].(map[string]interface{})["items"]

		assert.Equal(otu.T, expectedGhostDirectOffer, ghostDirectOffer)
		assert.Equal(otu.T, expectedGhostAuctionEscrow, ghostAuctionEscrowed)
		assert.Equal(otu.T, expectedBids, bids)

		result = otu.O.ScriptFromFile("name_status").
			Args(otu.O.Arguments().
				String("user2")).
			RunReturnsInterface()

		ghostDirectOffer = result.(map[string]interface{})["marketBids"].(map[string]interface{})["A.f8d6e0586b0a20c7.FindMarketDirectOfferSoft.Bid"].(map[string]interface{})["ghosts"]
		ghostAuctionEscrowed = result.(map[string]interface{})["marketBids"].(map[string]interface{})["A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid"].(map[string]interface{})["ghosts"]
		bids = result.(map[string]interface{})["marketBids"].(map[string]interface{})["A.f8d6e0586b0a20c7.FindMarketAuctionEscrow.Bid"].(map[string]interface{})["items"]

		assert.Equal(otu.T, expectedGhostDirectOffer, ghostDirectOffer)
		assert.Equal(otu.T, expectedGhostAuctionEscrow, ghostAuctionEscrowed)
		assert.Equal(otu.T, expectedBids, bids)

	})
}
