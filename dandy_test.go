package test_main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestDandy(t *testing.T) {

	t.Run("Should be able to mint 3 dandy nfts and display them", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1")

		dandyIds := otu.mintThreeExampleDandies()

		id := dandyIds[0]
		res := otu.O.ScriptFromFile("dandyViews").Args(otu.O.Arguments().String("user1").UInt64(id)).RunReturnsJsonString()
		assert.JSONEq(t, `[
			        	            	    "A.f8d6e0586b0a20c7.Dandy.MinterPlatform",
        	            	          "A.f8d6e0586b0a20c7.FindViews.Nounce",
			        	            	    "String",
			        	            	    "A.f8d6e0586b0a20c7.MetadataViews.Display",
			        	            	    "A.f8d6e0586b0a20c7.MetadataViews.Royalties",
																	"A.f8d6e0586b0a20c7.FindViews.SerialNumber",
																	"A.f8d6e0586b0a20c7.MetadataViews.HTTPFile",
																	"A.f8d6e0586b0a20c7.FindViews.CreativeWork"
			        	            	]`, res)
		display := `
	{
     "description": "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK",
     "name": "Neo Motorcycle 1 of 3",
     "thumbnail": {
         "url": "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"
     }
 }
`
		result := otu.O.ScriptFromFile("dandy").Args(otu.O.Arguments().String("user1").UInt64(id).String("A.f8d6e0586b0a20c7.MetadataViews.Display")).RunReturnsJsonString()
		assert.JSONEq(t, display, result)
	})

	t.Run("Should be able to list a dandy for sale and buy it", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2")

		price := 10.0
		id := otu.mintThreeExampleDandies()[0]
		otu.listDandyForSale("user1", id, price)

		otu.checkRoyalty("user1", id, "platform", 0.15)
		otu.buyDandyForSale("user2", "user1", id, price)
		otu.checkRoyalty("user2", id, "platform", 0.0)
	})

	t.Run("Should be able to add direct offer and then sell", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2")

		price := 10.0
		id := otu.mintThreeExampleDandies()[0]

		otu.directOfferMarket("user2", "user1", id, price)

		otu.acceptDirectOfferMarket("user1", id, "user2", price)

	})

	t.Run("Should be able to sell at auction", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2")

		price := 10.0
		id := otu.mintThreeExampleDandies()[0]

		otu.listDandyForAuction("user1", id, price)

		/*
			res := otu.O.ScriptFromFile("listSaleItems").Args(otu.O.Arguments().Account("user1")).RunReturnsJsonString()
			fmt.Println(res)
		*/

		otu.auctionBidMarket("user2", "user1", id, price+5.0)

		otu.tickClock(400.0)

		/*
			res = otu.O.ScriptFromFile("listSaleItems").Args(otu.O.Arguments().Account("user1")).RunReturnsJsonString()
			fmt.Println(res)
		*/
		otu.fulfillMarketAuction("user1", id, "user2", price+5.0)

	})

	t.Run("Should be able to return nft when item not sold at auction", func(t *testing.T) {
		otu := NewOverflowTest(t).
			setupFIND().
			setupDandy("user1").
			createUser(100.0, "user2").
			registerUser("user2")

		price := 10.0
		id := otu.mintThreeExampleDandies()[0]

		otu.listDandyForAuction("user1", id, price)

		/*
			res := otu.O.ScriptFromFile("listSaleItems").Args(otu.O.Arguments().Account("user1")).RunReturnsJsonString()
			fmt.Println(res)
		*/
		otu.auctionBidMarket("user2", "user1", id, price)

		otu.tickClock(400.0)

		/*
			res = otu.O.ScriptFromFile("listSaleItems").Args(otu.O.Arguments().Account("user1")).RunReturnsJsonString()
			fmt.Println(res)
		*/
		//TODO: test better events here
		otu.fulfillMarketAuctionCancelled("user1", id, "user2", price)

	})
}

//Test auction that does not reach price
