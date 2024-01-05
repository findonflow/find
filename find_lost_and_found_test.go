package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestFindLostAndFound(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	ot.Run(t, "Should be able to send thru sendNFT transaction without initialized collection", func(t *testing.T) {
		otu.SendNFTsLostAndFound(dandyIdentifier, dandyIds[0], "user4")
	})

	ot.Run(t, "Should be able to get all Lost And Found NFT with script", func(t *testing.T) {
		ticket := otu.SendNFTsLostAndFound(dandyIdentifier, dandyIds[0], "user4")

		otu.O.Script("getLostAndFoundNFTs",
			WithArg("user", otu.O.Address("user4")),
		).
			AssertWant(t, autogold.Want("Should get all NFT Type", map[string]interface{}{
				"nftCatalogTicketInfo": map[string]interface{}{"A.179b6b1cb6755e31.Dandy.NFT": []interface{}{map[string]interface{}{
					"description":    "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK",
					"memo":           "Hello!",
					"name":           "Neo Motorcycle 1 of 3",
					"redeemed":       false,
					"redeemer":       "0xeb179c27144f783c",
					"thumbnail":      "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
					"ticketID":       ticket,
					"type":           "A.179b6b1cb6755e31.Dandy.NFT",
					"typeIdentifier": "A.179b6b1cb6755e31.Dandy.NFT",
				}}},
				"ticketIds": map[string]interface{}{"A.179b6b1cb6755e31.Dandy.NFT": []interface{}{ticket}},
			}))
	})

	ot.Run(t, "Should not be able to redeem NFT on behalf of without suitable collection. But tx will still run thru and events will be emitted", func(t *testing.T) {
		ticket := otu.SendNFTsLostAndFound(dandyIdentifier, dandyIds[0], "user4")

		// note that it is somebody else that is redeeming
		otu.O.Tx("redeemLostAndFoundNFTsOnBehalf",
			WithSigner("find"),
			WithArg("receiverAddress", otu.O.Address("user4")),
			WithArg("ids", map[string][]uint64{dandyIdentifier: {ticket}}),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.TicketRedeemFailed", map[string]interface{}{
				"receiver": otu.O.Address("user4"),
				"ticketID": ticket,
				"type":     dandyIdentifier,
				"remark":   "invalid capability",
			})
	})

	ot.Run(t, "Should be able to send thru sendNFT transaction with account initiated", func(t *testing.T) {
		otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("nftIdentifiers", []string{dandyIdentifier}),
			WithArg("allReceivers", `["user2"]`),
			WithArg("ids", []uint64{dandyIds[0]}),
			WithArg("memos", `["Hello!"]`),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindLostAndFoundWrapper.NFTDeposited", map[string]interface{}{
				"receiver":     otu.O.Address("user2"),
				"receiverName": "user2",
				"sender":       otu.O.Address("user1"),
				"type":         dandyIdentifier,
				"memo":         "Hello!",
			})
	})
}
