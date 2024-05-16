package test_main

import (
	"testing"

	. "github.com/bjartek/overflow/v2"
	"github.com/findonflow/find/findGo"
	"github.com/hexops/autogold"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/require"
)

func TestFindAirdropper(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	id := dandyIds[0]
	dandyType := dandyNFTType(otu)
	fusd := otu.identifier("FUSD", "Vault")

	ot.Run(t, "Should be able to send Airdrop", func(t *testing.T) {
		otu.O.Tx("sendNFTsSafe",
			WithSigner("user1"),
			WithArg("allReceivers", []string{"user2", "user2", "user2"}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", dandyIds),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
			WithArg("donationTypes", `[nil, nil, nil]`),
			WithArg("donationAmounts", `[nil, nil, nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
				"from":     otu.O.Address("user1"),
				"fromName": "user1",
				"to":       otu.O.Address("user2"),
				"toName":   "user2",
			})
	})

	ot.Run(t, "Should be able to send packs thru airdropper with struct", func(t *testing.T) {
		otu.O.Tx("sendFindPacks",
			WithSigner("find-admin"),
			WithArg("packInfo", findGo.FindPack_AirdropInfo{
				PackTypeName: "user1",
				PackTypeId:   1,
				Users:        []string{"user2"},
				Message:      "I can use struct here",
			}),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
				"from":   otu.O.Address("find"),
				"toName": "user2",
				"to":     otu.O.Address("user2"),
				"context": map[string]interface{}{
					"message": "I can use struct here",
					"tenant":  "find",
				},
			})
	})

	ot.Run(t, "Should not be able to send Airdrop without collection, good events will be emitted", func(t *testing.T) {
		user4 := otu.O.Address("user4")

		otu.O.Tx("sendNFTsSafe",
			WithSigner("user1"),
			WithArg("allReceivers", []string{user4}),
			WithArg("nftIdentifiers", []string{dandyType}),
			WithArg("ids", []uint64{id}),
			WithArg("memos", []string{"Message 0"}),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).AssertSuccess(t).AssertEvent(t, "FindAirdropper.AirdropFailed", map[string]interface{}{
			"fromName": "user1",
			"from":     otu.O.Address("user1"),
			"to":       user4,
			"id":       id,
			"uuid":     id,
			"type":     dandyType,
			"context": map[string]interface{}{
				"message": "Message 0",
				"tenant":  "find",
			},
			"reason": "Invalid Receiver Capability",
		})
	})

	ot.Run(t, "Should be able to get Airdrop details with a script", func(t *testing.T) {
		user3 := otu.O.Address("user3")

		details := []SendNFTScript{}
		err := otu.O.Script("sendNFTs",
			WithArg("sender", "user1"),
			WithArg("allReceivers", []string{"user1", "user2", user3}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", dandyIds),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
		).MarshalAs(&details)

		require.NoError(t, err)
		autogold.Equal(t, details)
	})

	ot.Run(t, "Should be able to send Airdrop with sending funds to royalty holders", func(t *testing.T) {
		res := otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("allReceivers", []string{"user2"}),
			WithArg("nftIdentifiers", []string{dandyType}),
			WithArg("ids", []uint64{id}),
			WithArg("memos", []string{"Message 0"}),
			WithArg("donationTypes", []string{fusd}),
			WithArg("donationAmounts", []float64{10.0}),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
				"from":     otu.O.Address("user1"),
				"fromName": "user1",
				"to":       otu.O.Address("user2"),
				"toName":   "user2",
			})
		wants := []map[string]interface{}{
			{
				"amount": 6.6666666,
				"to":     otu.O.Address("user1"),
			},
			{
				"amount": 3.3333333,
				"to":     otu.O.Address("find"),
			},
		}

		for _, want := range wants {
			res.AssertEvent(t, "FungibleToken.Deposited", want)
		}
	})

	ot.Run(t, "Should be able to send Airdrop and donate funds to FIND!", func(t *testing.T) {
		optional := cadence.NewOptional(cadence.String(fusd))

		res := otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("allReceivers", []string{"user2"}),
			WithArg("nftIdentifiers", []string{dandyType}),
			WithArg("ids", []uint64{id}),
			WithArg("memos", []string{"Message 0"}),
			WithArg("donationTypes", `[nil]`),
			WithArg("donationAmounts", `[nil]`),
			WithArg("findDonationType", optional),
			WithArg("findDonationAmount", "10.0"),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
				"from":     otu.O.Address("user1"),
				"fromName": "user1",
				"to":       otu.O.Address("user2"),
				"toName":   "user2",
			})

		res.AssertEvent(t, "FIND.FungibleTokenSent", map[string]interface{}{
			"from":      otu.O.Address("user1"),
			"fromName":  "user1",
			"toAddress": otu.O.Address("find"),
			"message":   "donation to .find",
			"tag":       "donation",
			"amount":    10.0,
			"ftType":    fusd,
		})

		res.AssertEvent(t, "FungibleToken.Deposited", map[string]interface{}{
			"to":     otu.O.Address("find"),
			"amount": 10.0,
		})
	})
}

type SendNFTScript struct {
	Address   string `json:"address"`
	Avatar    string `json:"avatar"`
	Message   string `json:"message"`
	Receiver  string `json:"receiver"`
	Type      string `json:"type"`
	Royalties struct {
		Royalties []struct {
			Address     string   `json:"address"`
			Description string   `json:"description"`
			Name        string   `json:"name,omitempty"`
			AcceptTypes []string `json:"acceptTypes"`
			Cut         float64  `json:"cut"`
		} `json:"royalties"`
		TotalRoyalty float64 `json:"totalRoyalty"`
	} `json:"royalties"`
	AccountInitialized     bool `json:"accountInitialized"`
	CollectionPublicLinked bool `json:"collectionPublicLinked"`
	IsDapper               bool `json:"isDapper"`
	NftInPlace             bool `json:"nftInPlace"`
	Ok                     bool `json:"ok"`
	ReceiverLinked         bool `json:"receiverLinked"`
}
