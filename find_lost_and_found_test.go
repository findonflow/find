package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
)

func TestFindLostAndFound(t *testing.T) {
	otu := NewOverflowTest(t)

	otu.setupFIND().
		createUser(10000.0, "user1").
		registerUser("user1").
		registerExampleNFTInNFTRegistry()

	ticketID := uint64(0)

	t.Run("Should be able to send thru sendNFT transaction without account initiated", func(t *testing.T) {
		res := otu.O.Tx("sendNFTs",
			WithSigner("account"),
			WithArg("nftIdentifiers", `["A.f8d6e0586b0a20c7.ExampleNFT.NFT"]`),
			WithArg("allReceivers", `["user1"]`),
			WithArg("ids", []uint64{0}),
			WithArg("memos", `["Hello!"]`),
			WithArg("random", false),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"sender":       otu.O.Address("account"),
				"type":         "A.f8d6e0586b0a20c7.ExampleNFT.NFT",
				"id":           0,
				"memo":         "Hello!",
				"name":         "DUCExampleNFT",
				"description":  "For testing listing in DUC",
				"thumbnail":    "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg",
			})

		ticketID, _ = res.GetIdFromEvent("FindLostAndFoundWrapper.TicketDeposited", "ticketID")

	})

	t.Run("Should be able to get Lost And Found Ticket with script", func(t *testing.T) {

		otu.O.Script("getLostAndFoundTickets",
			WithArg("user", "user1"),
			WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.NFT"),
		).
			AssertWithPointerWant(t, "/0", autogold.Want("Should get ticket no", ticketID))

	})

	t.Run("Should be able to get all Lost And Found NFT with script", func(t *testing.T) {

		otu.O.Script("getLostAndFoundNFTs",
			WithArg("user", "user1"),
			WithArg("specificType", nil),
		).
			AssertWant(t, autogold.Want("Should get all NFT Type", map[string]interface{}{
				"ticketInfo": map[string]interface{}{"A.f8d6e0586b0a20c7.ExampleNFT.NFT": []interface{}{map[string]interface{}{
					"description":    "For testing listing in DUC",
					"memo":           "Hello!",
					"name":           "DUCExampleNFT",
					"redeemed":       false,
					"redeemer":       "0x179b6b1cb6755e31",
					"thumbnail":      "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg",
					"ticketID":       ticketID,
					"type":           "A.f8d6e0586b0a20c7.ExampleNFT.NFT",
					"typeIdentifier": "A.f8d6e0586b0a20c7.ExampleNFT.NFT",
				}}},
				"tickets": map[string]interface{}{"A.f8d6e0586b0a20c7.ExampleNFT.NFT": []interface{}{ticketID}},
			}))

	})

	t.Run("Should be able to get specific type Lost And Found NFT with script (ExampleNFT)", func(t *testing.T) {

		cadenceString, err := cadence.NewString("A.f8d6e0586b0a20c7.ExampleNFT.NFT")
		assert.NoError(t, err)
		cadenceValue := cadence.Value(cadenceString)

		otu.O.Script("getLostAndFoundNFTs",
			WithArg("user", "user1"),
			WithArg("specificType", cadence.NewOptional(cadenceValue)),
		).
			AssertWant(t, autogold.Want("Should get all NFT Type", map[string]interface{}{
				"ticketInfo": map[string]interface{}{"A.f8d6e0586b0a20c7.ExampleNFT.NFT": []interface{}{map[string]interface{}{
					"description":    "For testing listing in DUC",
					"memo":           "Hello!",
					"name":           "DUCExampleNFT",
					"redeemed":       false,
					"redeemer":       "0x179b6b1cb6755e31",
					"thumbnail":      "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg",
					"ticketID":       ticketID,
					"type":           "A.f8d6e0586b0a20c7.ExampleNFT.NFT",
					"typeIdentifier": "A.f8d6e0586b0a20c7.ExampleNFT.NFT",
				}}},
				"tickets": map[string]interface{}{"A.f8d6e0586b0a20c7.ExampleNFT.NFT": []interface{}{238}},
			}))

	})

	t.Run("Should be able to get specific type Lost And Found NFT with script (Dandy)", func(t *testing.T) {

		cadenceString, err := cadence.NewString("A.f8d6e0586b0a20c7.Dandy.NFT")
		assert.NoError(t, err)
		cadenceValue := cadence.Value(cadenceString)

		otu.O.Script("getLostAndFoundNFTs",
			WithArg("user", "user1"),
			WithArg("specificType", cadence.NewOptional(cadenceValue)),
		).
			AssertWant(t, autogold.Want("Should get all NFT Type", nil))

	})

	t.Run("Should be able to redeem NFT after initiating", func(t *testing.T) {

		otu.O.Tx("setupExampleNFT",
			WithSigner("user1"),
		).
			AssertSuccess(t)

		otu.O.Tx("redeemLostAndFoundNFT",
			WithSigner("user1"),
			WithArg("ids", `{"A.f8d6e0586b0a20c7.ExampleNFT.NFT" : [`+fmt.Sprint(ticketID)+`]}`),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FindLostAndFoundWrapper.TicketRedeemed")

	})

	t.Run("Should be able to send thru sendNFT transaction with account initiated", func(t *testing.T) {
		otu.O.Tx("sendNFTs",
			WithSigner("account"),
			WithArg("nftIdentifiers", `["A.f8d6e0586b0a20c7.ExampleNFT.NFT"]`),
			WithArg("allReceivers", `["user1"]`),
			WithArg("ids", []uint64{1}),
			WithArg("memos", `["Hello!"]`),
			WithArg("random", false),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.NFTDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"sender":       otu.O.Address("account"),
				"type":         "A.f8d6e0586b0a20c7.ExampleNFT.NFT",
				"id":           1,
				"memo":         "Hello!",
				"name":         "SoulBoundNFT",
				"thumbnail":    "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg",
			})

	})

	t.Run("Should be able to send thru sendNFT transaction and shuffle the receivers", func(t *testing.T) {
		otu.buyForge("user1").
			createUser(100, "user2").
			registerUser("user2").
			createUser(100, "user3")
		ids := otu.mintThreeExampleDandies()

		otu.registerFtInRegistry()

		user3 := fmt.Sprint(otu.O.Address("user3"))
		user5 := fmt.Sprint(otu.O.Address("user5-dapper"))

		otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("nftIdentifiers", `["A.f8d6e0586b0a20c7.Dandy.NFT", "A.f8d6e0586b0a20c7.Dandy.NFT", "A.f8d6e0586b0a20c7.Dandy.NFT"]`),
			WithArg("allReceivers", []string{"user2", user3, user5}),
			WithArg("ids", ids),
			WithArg("memos", `["Msg1" , "Msg2", "Msg3"]`),
			WithArg("random", true),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FindLostAndFoundWrapper.NFTDeposited").
			AssertEmitEventName(t, "FindLostAndFoundWrapper.TicketDeposited")
	})

	t.Run("Should be able to send a lot of NFTs", func(t *testing.T) {
		amount := 70
		ids := mintDandies(otu, amount)

		identifiers := []string{}
		allReceivers := []string{}
		memos := []string{}

		for len(identifiers) < len(ids) {
			identifiers = append(identifiers, "A.f8d6e0586b0a20c7.Dandy.NFT")
			allReceivers = append(allReceivers, "user2")
			memos = append(memos, "Msg")
		}

		otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("nftIdentifiers", identifiers),
			WithArg("allReceivers", allReceivers),
			WithArg("ids", ids),
			WithArg("memos", memos),
			WithArg("random", false),
		).
			AssertSuccess(t)

	})

}

func mintDandies(otu *OverflowTestUtils, number int) []uint64 {

	result := otu.O.Tx("mintDandy",
		user1Signer,
		WithArg("name", "user1"),
		WithArg("maxEdition", uint64(number)),
		WithArg("artist", "Neo"),
		WithArg("nftName", "Neo Motorcycle"),
		WithArg("nftDescription", `Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK`),

		WithArg("nftUrl", "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"),
		WithArg("collectionDescription", "Neo Collectibles FIND"),
		WithArg("collectionExternalURL", "https://neomotorcycles.co.uk/index.html"),
		WithArg("collectionSquareImage", "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"),
		WithArg("collectionBannerImage", "https://neomotorcycles.co.uk/assets/img/neo-logo-web-dark.png?h=5a4d226197291f5f6370e79a1ee656a1"),
	).
		AssertSuccess(otu.T)
	return result.GetIdsFromEvent("Dandy.Deposit", "id")
}
