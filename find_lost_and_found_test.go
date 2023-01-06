package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestFindLostAndFound(t *testing.T) {
	otu := NewOverflowTest(t)

	otu.setupFIND().
		createUser(10000.0, "user1").
		registerUser("user1").
		registerExampleNFTInNFTRegistry()

	t.Run("Should be able to send thru sendNFT transaction without account initiated", func(t *testing.T) {
		otu.O.Tx("sendNFTs",
			WithSigner("find"),
			WithArg("nftIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("allReceivers", `["user1"]`),
			WithArg("ids", []uint64{0}),
			WithArg("memos", `["Hello!"]`),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"sender":       otu.O.Address("find"),
				"type":         exampleNFTType(otu),
				"id":           0,
				"memo":         "Hello!",
				"name":         "DUCExampleNFT",
				"description":  "For testing listing in DUC",
				"thumbnail":    "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg",
			})

		resetState(otu, "user1", true)

	})

	t.Run("Should be able to get all Lost And Found NFT with script", func(t *testing.T) {
		ticketID := otu.createExampleNFTTicket()

		otu.O.Script("getLostAndFoundNFTs",
			WithArg("user", "user1"),
		).
			AssertWant(t, autogold.Want("Should get all NFT Type", map[string]interface{}{
				"nftCatalogTicketInfo": map[string]interface{}{exampleNFTType(otu): []interface{}{map[string]interface{}{
					"description":    "For testing listing in DUC",
					"memo":           "Hello!",
					"name":           "DUCExampleNFT",
					"redeemed":       false,
					"redeemer":       otu.O.Address("user1"),
					"thumbnail":      "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg",
					"ticketID":       ticketID,
					"type":           exampleNFTType(otu),
					"typeIdentifier": exampleNFTType(otu),
				}}},
				"ticketIds": map[string]interface{}{exampleNFTType(otu): []interface{}{ticketID}},
			}))

		resetState(otu, "user1", true)

	})

	t.Run("Should not be able to redeem NFT without suitable collection. But tx will still run thru and events will be emitted", func(t *testing.T) {
		ticketID := otu.createExampleNFTTicket()

		otu.O.Tx("redeemLostAndFoundNFTs",
			WithSigner("user1"),
			WithArg("ids", map[string][]uint64{exampleNFTType(otu): {ticketID}}),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.TicketRedeemFailed", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"ticketID":     ticketID,
				"type":         exampleNFTType(otu),
				"remark":       "invalid capability",
			})

		resetState(otu, "user1", true)

	})

	t.Run("Should be able to redeem NFT after initiating", func(t *testing.T) {
		ticketID := otu.createExampleNFTTicket()

		otu.O.Tx("setupExampleNFTCollection",
			WithSigner("user1"),
		).
			AssertSuccess(t)

		otu.O.Tx("redeemLostAndFoundNFTs",
			WithSigner("user1"),
			WithArg("ids", map[string][]uint64{exampleNFTType(otu): {ticketID}}),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FindLostAndFoundWrapper.TicketRedeemed")

		resetState(otu, "user1", true)

	})

	t.Run("Should be able to send thru sendNFT transaction with account initiated", func(t *testing.T) {
		otu.O.Tx("setupExampleNFTCollection",
			WithSigner("user1"),
		).
			AssertSuccess(t)

		otu.O.Tx("sendNFTs",
			WithSigner("find"),
			WithArg("nftIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("allReceivers", `["user1"]`),
			WithArg("ids", []uint64{0}),
			WithArg("memos", `["Hello!"]`),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.NFTDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"sender":       otu.O.Address("find"),
				"type":         exampleNFTType(otu),
				"id":           0,
				"memo":         "Hello!",
				"name":         "DUCExampleNFT",
				"thumbnail":    "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg",
			})
		resetState(otu, "user1", true)

	})

	t.Run("Should be able to send thru sendNFT transaction with account initiated and display receiverName in event", func(t *testing.T) {
		otu.O.Tx("setupExampleNFTCollection",
			WithSigner("user1"),
		).
			AssertSuccess(t)

		receiverAddress := otu.O.Address("user1")

		otu.O.Tx("sendNFTs",
			WithSigner("find"),
			WithArg("nftIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("allReceivers", `["`+receiverAddress+`"]`),
			WithArg("ids", []uint64{0}),
			WithArg("memos", `["Hello!"]`),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.NFTDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"sender":       otu.O.Address("find"),
				"type":         exampleNFTType(otu),
				"id":           0,
				"memo":         "Hello!",
				"name":         "DUCExampleNFT",
				"thumbnail":    "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg",
			})
		resetState(otu, "user1", true)

	})

	t.Run("Should be able to redeem with Collection Public and MetadataViews linked", func(t *testing.T) {

		ticketID, err := otu.O.Tx("sendNFTs",
			WithSigner("find"),
			WithArg("nftIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("allReceivers", `["user1"]`),
			WithArg("ids", []uint64{0}),
			WithArg("memos", `["Hello!"]`),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"sender":       otu.O.Address("find"),
				"type":         exampleNFTType(otu),
				"id":           0,
				"memo":         "Hello!",
				"name":         "DUCExampleNFT",
				"thumbnail":    "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg",
			}).
			GetIdFromEvent("FindLostAndFoundWrapper.TicketDeposited", "ticketID")

		assert.NoError(t, err)

		otu.O.Tx("devsetupExampleNFTCollectionCPMV",
			WithSigner("user1"),
		).
			AssertSuccess(t)

		otu.O.Tx("redeemLostAndFoundNFTs",
			WithSigner("user1"),
			WithArg("ids", map[string][]uint64{exampleNFTType(otu): {ticketID}}),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FindLostAndFoundWrapper.TicketRedeemed")

		resetState(otu, "user1", true)

	})

	t.Run("Should be able to redeem with Receiver and MetadataViews linked", func(t *testing.T) {

		ticketID, err := otu.O.Tx("sendNFTs",
			WithSigner("find"),
			WithArg("nftIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("allReceivers", `["user1"]`),
			WithArg("ids", []uint64{0}),
			WithArg("memos", `["Hello!"]`),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"sender":       otu.O.Address("find"),
				"type":         exampleNFTType(otu),
				"id":           0,
				"memo":         "Hello!",
				"name":         "DUCExampleNFT",
				"thumbnail":    "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg",
			}).
			GetIdFromEvent("FindLostAndFoundWrapper.TicketDeposited", "ticketID")

		assert.NoError(t, err)

		otu.O.Tx("devsetupExampleNFTCollectionRMV",
			WithSigner("user1"),
		).
			AssertSuccess(t)

		otu.O.Tx("redeemLostAndFoundNFTs",
			WithSigner("user1"),
			WithArg("ids", map[string][]uint64{exampleNFTType(otu): {ticketID}}),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FindLostAndFoundWrapper.TicketRedeemed")

		resetState(otu, "user1", true)

	})

	t.Run("Should be able to redeem with only Collection Public linked", func(t *testing.T) {

		ticketID, err := otu.O.Tx("sendNFTs",
			WithSigner("find"),
			WithArg("nftIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("allReceivers", `["user1"]`),
			WithArg("ids", []uint64{0}),
			WithArg("memos", `["Hello!"]`),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"sender":       otu.O.Address("find"),
				"type":         exampleNFTType(otu),
				"id":           0,
				"memo":         "Hello!",
			}).
			GetIdFromEvent("FindLostAndFoundWrapper.TicketDeposited", "ticketID")

		assert.NoError(t, err)

		otu.O.Tx("devsetupExampleNFTCollectionCP",
			WithSigner("user1"),
		).
			AssertSuccess(t)

		otu.O.Tx("redeemLostAndFoundNFTs",
			WithSigner("user1"),
			WithArg("ids", map[string][]uint64{exampleNFTType(otu): {ticketID}}),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FindLostAndFoundWrapper.TicketRedeemed")

		resetState(otu, "user1", true)

	})

	t.Run("Should be able to redeem with Receiver and MetadataViews linked", func(t *testing.T) {

		ticketID, err := otu.O.Tx("sendNFTs",
			WithSigner("find"),
			WithArg("nftIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("allReceivers", `["user1"]`),
			WithArg("ids", []uint64{0}),
			WithArg("memos", `["Hello!"]`),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"sender":       otu.O.Address("find"),
				"type":         exampleNFTType(otu),
				"id":           0,
				"memo":         "Hello!",
			}).
			GetIdFromEvent("FindLostAndFoundWrapper.TicketDeposited", "ticketID")

		assert.NoError(t, err)

		otu.O.Tx("devsetupExampleNFTCollectionR",
			WithSigner("user1"),
		).
			AssertSuccess(t)

		otu.O.Tx("redeemLostAndFoundNFTs",
			WithSigner("user1"),
			WithArg("ids", map[string][]uint64{exampleNFTType(otu): {ticketID}}),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FindLostAndFoundWrapper.TicketRedeemed")

		resetState(otu, "user1", true)

	})

	t.Run("Should be able to redeem on behalf of other account", func(t *testing.T) {

		ticketID, err := otu.O.Tx("sendNFTs",
			WithSigner("find"),
			WithArg("nftIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("allReceivers", `["user1"]`),
			WithArg("ids", []uint64{0}),
			WithArg("memos", `["Hello!"]`),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"sender":       otu.O.Address("find"),
				"type":         exampleNFTType(otu),
				"id":           0,
				"memo":         "Hello!",
			}).
			GetIdFromEvent("FindLostAndFoundWrapper.TicketDeposited", "ticketID")

		assert.NoError(t, err)

		otu.O.Tx("devsetupExampleNFTCollectionR",
			WithSigner("user1"),
		).
			AssertSuccess(t)

		otu.O.Tx("redeemLostAndFoundNFTsOnBehalf",
			WithSigner("user2"),
			WithArg("receiverAddress", "user1"),
			WithArg("ids", map[string][]uint64{exampleNFTType(otu): {ticketID}}),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FindLostAndFoundWrapper.TicketRedeemed")

		resetState(otu, "user1", true)

	})

	t.Run("Should be able to redeem on behalf of other account", func(t *testing.T) {

		otu.O.Tx("sendNFTs",
			WithSigner("find"),
			WithArg("nftIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("allReceivers", `["user1"]`),
			WithArg("ids", []uint64{0}),
			WithArg("memos", `["Hello!"]`),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user1"),
				"receiverName": "user1",
				"sender":       otu.O.Address("find"),
				"type":         exampleNFTType(otu),
				"id":           0,
				"memo":         "Hello!",
			})

		otu.O.Tx("devsetupExampleNFTCollectionCP",
			WithSigner("user1"),
		).
			AssertSuccess(t)

		otu.O.Tx("redeemAllLostAndFoundNFTsOnBehalf",
			WithSigner("user2"),
			WithArg("receiverAddress", "user1"),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FindLostAndFoundWrapper.TicketRedeemed")

		resetState(otu, "user1", true)

	})

	t.Run("Should be able to send a lot of NFTs", func(t *testing.T) {
		amount := 40

		otu.buyForge("user1").
			createUser(100, "user2").
			registerUser("user2").
			createUser(100, "user3")

		ids := mintDandies(otu, amount)

		otu.registerFtInRegistry()

		identifiers := []string{}
		allReceivers := []string{}
		memos := []string{}
		nils := `[nil`

		for len(identifiers) < len(ids) {
			identifiers = append(identifiers, dandyNFTType(otu))
			allReceivers = append(allReceivers, "user2")
			memos = append(memos, "Msg")
			nils = nils + `, nil`
		}

		nils = nils + `]`

		otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("nftIdentifiers", identifiers),
			WithArg("allReceivers", allReceivers),
			WithArg("ids", ids),
			WithArg("memos", memos),
			WithArg("donationTypes", nils),
			WithArg("donationAmounts", nils),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t)

		resetState(otu, "user1", false)
	})

	t.Run("Should send to Lost And Found if the receiver account is full", func(t *testing.T) {

		otu.O.Tx("setupDandyCollection",
			WithSigner("user2"),
		).
			AssertSuccess(t)

		otu.O.Tx("devFillUpStorage",
			WithSigner("user2"),
		).
			AssertSuccess(t)

		otu.O.FillUpStorage("user2")

		amount := 20

		ids := mintDandies(otu, amount)

		identifiers := []string{}
		allReceivers := []string{}
		memos := []string{}
		nils := `[nil`

		for len(identifiers) < len(ids) {
			identifiers = append(identifiers, dandyNFTType(otu))
			allReceivers = append(allReceivers, "user2")
			memos = append(memos, "Msg")
			nils = nils + `, nil`
		}
		nils = nils + `]`

		otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("nftIdentifiers", identifiers),
			WithArg("allReceivers", allReceivers),
			WithArg("ids", ids),
			WithArg("memos", memos),
			WithArg("donationTypes", nils),
			WithArg("donationAmounts", nils),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
				"receiver": otu.O.Address("user2"),
				"sender":   otu.O.Address("user1"),
				"type":     dandyNFTType(otu),
			})

		otu.O.Tx("devRefillStorage",
			WithSigner("user2"),
		).
			AssertSuccess(t)

	})

	/*
		t.Run("Should refill user storage if the receiver account is full by subsidizing", func(t *testing.T) {

			otu.O.Tx("setupDandyCollection",
				WithSigner("user2"),
			).
				AssertSuccess(t)

			otu.O.Tx("devFillUpStorage",
				WithSigner("user2"),
			).
				AssertSuccess(t)

			otu.O.FillUpStorage("user2")

			amount := 20

			ids := mintDandies(otu, amount)

			identifiers := []string{}
			allReceivers := []string{}
			memos := []string{}
			nils := `[nil`

			for len(identifiers) < len(ids) {
				identifiers = append(identifiers, "A.f8d6e0586b0a20c7.Dandy.NFT")
				allReceivers = append(allReceivers, "user2")
				memos = append(memos, "Msg")
				nils = nils + `, nil`
			}
			nils = nils + `]`

			otu.O.Tx("sendNFTsSubsidize",
				WithSigner("user1"),
				WithArg("nftIdentifiers", identifiers),
				WithArg("allReceivers", allReceivers),
				WithArg("ids", ids),
				WithArg("memos", memos),
				WithArg("donationTypes", nils),
				WithArg("donationAmounts", nils),
				WithArg("findDonationType", nil),
				WithArg("findDonationAmount", nil),
			).
				AssertSuccess(t).
				AssertEvent(t, "FindLostAndFoundWrapper.NFTDeposited", map[string]interface{}{
					"receiver":     otu.O.Address("user2"),
					"receiverName": "user2",
					"sender":       otu.O.Address("user1"),
					"type":         "A.f8d6e0586b0a20c7.Dandy.NFT",
					"memo":         "Msg",
				}).
				AssertEvent(t, "FindLostAndFoundWrapper.UserStorageSubsidized", map[string]interface{}{
					"receiver":     otu.O.Address("user2"),
					"receiverName": "user2",
					"sender":       otu.O.Address("user1"),
				})

			otu.O.Tx("devRefillStorage",
				WithSigner("user2"),
			).
				AssertSuccess(t)

		})
	*/

	t.Run("Should be able to get required storage type by script so that they can redeem NFTs", func(t *testing.T) {

		resetState(otu, "user2", false)

		// mint one Dandy to "user2"
		amount := 1
		ids := mintDandies(otu, amount)

		identifiers := []string{}
		allReceivers := []string{}
		memos := []string{}
		nils := `[nil`

		for len(identifiers) < len(ids) {
			identifiers = append(identifiers, dandyNFTType(otu))
			allReceivers = append(allReceivers, "user2")
			memos = append(memos, "Msg")
			nils = nils + `, nil`
		}
		nils = nils + `]`

		otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("nftIdentifiers", identifiers),
			WithArg("allReceivers", allReceivers),
			WithArg("ids", ids),
			WithArg("memos", memos),
			WithArg("donationTypes", nils),
			WithArg("donationAmounts", nils),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t)

		// Scripts should be able to get initiable type
		otu.O.Script("getLostAndFoundRequiredStorageType",
			WithArg("user", "user2"),
		).
			Print().
			AssertWithPointerWant(t, "/initiableStorage/0", autogold.Want("Should get Dandy Type in initiable", dandyNFTType(otu)))

		otu.O.Tx("setupDandyCollection",
			WithSigner("user2"),
		).
			AssertSuccess(t)

		// Scripts should get initiated type
		otu.O.Script("getLostAndFoundRequiredStorageType",
			WithArg("user", "user2"),
		).
			Print().
			AssertWithPointerWant(t, "/initiatedStorage/0", autogold.Want("Should get Dandy Type in initiated", dandyNFTType(otu)))

		resetState(otu, "user2", false)
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

func resetState(otu *OverflowTestUtils, user string, resetExampleNFT bool) *OverflowTestUtils {

	signWithUser := otu.O.TxFN(
		WithSigner(user),
	)

	signWithUser("setupDandyCollection").
		AssertSuccess(otu.T)

	signWithUser("setupExampleNFTCollection").
		AssertSuccess(otu.T)

	signWithUser("redeemAllLostAndFoundNFTs").
		AssertSuccess(otu.T)

	if resetExampleNFT {
		otu.sendExampleNFT("find", user)
	}

	signWithUser("devDestroyExampleNFTCollection").
		AssertSuccess(otu.T)

	signWithUser("devDestroyDandyCollection").
		AssertSuccess(otu.T)

	return otu

}
