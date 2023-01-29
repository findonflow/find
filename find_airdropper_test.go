package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/onflow/cadence"
	"github.com/sanity-io/litter"
	"github.com/stretchr/testify/require"
)

func TestFindAirdropper(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(1000.0, "user1").
		registerUser("user1").
		buyForge("user1").
		createUser(100.0, "user2").
		registerUser("user2").
		registerExampleNFTInNFTRegistry().
		registerFtInRegistry().
		setProfile("user1").
		setProfile("user2").
		registerFIND()

	dandyType := dandyNFTType(otu)
	fusd := otu.identifier("FUSD", "Vault")
	otu.mintThreeExampleDandies()
	otu.registerDandyInNFTRegistry()

	t.Run("Should be able to send Airdrop", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()

		res := otu.O.Tx("sendNFTsSafe",
			WithSigner("user1"),
			WithArg("allReceivers", []string{"user2", "user2", "user2"}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
			WithArg("donationTypes", `[nil, nil, nil]`),
			WithArg("donationAmounts", `[nil, nil, nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t)

		for i, id := range ids {

			events := res.GetEventsWithName("FindAirdropper.Airdropped")
			mockField := map[string]interface{}{}
			for _, e := range events {
				field, exist := e.Fields["nftInfo"].(map[string]interface{})
				if exist {
					mockId := field["id"].(uint64)
					if id == mockId {
						field["id"] = id
						field["type"] = dandyType
						mockField = field
					}
				}
			}

			res.AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
				"from":     otu.O.Address("user1"),
				"fromName": "user1",
				"to":       otu.O.Address("user2"),
				"toName":   "user2",
				"uuid":     id,
				"context": map[string]interface{}{
					"message": fmt.Sprintf("Message %d", i),
					"tenant":  "find",
				},
				"nftInfo": mockField,
			})
		}
	})

	packType := "user1"
	packTypeId := uint64(1)
	salt := "find"
	singleType := []string{exampleNFTType(otu)}

	t.Run("Should be able to send packs thru airdropper with struct", func(t *testing.T) {

		type FindPack_AirdropInfo struct {
			PackTypeName string `cadence:"packTypeName"`
			PackTypeId   uint64 `cadence:"packTypeId"`
			Users        []string
			Message      string
		}

		id1 := otu.mintExampleNFTs()

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 1.0, 1.0, false, 0, "find", "account").
			mintPack("user1", packTypeId, []uint64{id1}, singleType, salt)

		res := otu.O.Tx("sendFindPacks",
			WithSigner("find-admin"),
			WithArg("packInfo", FindPack_AirdropInfo{
				PackTypeName: packType,
				PackTypeId:   packTypeId,
				Users:        []string{"user2"},
				Message:      "I can use struct here",
			}),
		).
			AssertSuccess(t)

		events := res.GetEventsWithName("FindAirdropper.Airdropped")
		mockField := map[string]interface{}{}
		for _, e := range events {
			field, exist := e.Fields["nftInfo"].(map[string]interface{})
			if exist {
				field["type"] = otu.identifier("FindPack", "NFT")
				mockField = field
			}
		}

		res.AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
			"from":   otu.O.Address("find"),
			"toName": "user2",
			"to":     otu.O.Address("user2"),
			"context": map[string]interface{}{
				"message": "I can use struct here",
				"tenant":  "find",
			},
			"nftInfo": mockField,
		})

	})

	t.Run("Should be able to send Airdrop with only collection public linked", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		otu.O.Tx("devUnlinkDandyReceiver",
			WithSigner("user2"),
		).
			AssertSuccess(t)

		res := otu.O.Tx("sendNFTsSafe",
			WithSigner("user1"),
			WithArg("allReceivers", []string{"user2", "user2", "user2"}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
			WithArg("donationTypes", `[nil, nil, nil]`),
			WithArg("donationAmounts", `[nil, nil, nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t)

		for i, id := range ids {

			events := res.GetEventsWithName("FindAirdropper.Airdropped")
			mockField := map[string]interface{}{}
			for _, e := range events {
				field, exist := e.Fields["nftInfo"].(map[string]interface{})
				if exist {
					mockId := field["id"].(uint64)
					if id == mockId {
						field["id"] = id
						field["type"] = dandyType
						mockField = field
					}
				}
			}

			res.AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
				"fromName": "user1",
				"from":     otu.O.Address("user1"),
				"toName":   "user2",
				"to":       otu.O.Address("user2"),
				"uuid":     id,
				"context": map[string]interface{}{
					"message": fmt.Sprintf("Message %d", i),
					"tenant":  "find",
				},
				"remark":  "Receiver Not Linked",
				"nftInfo": mockField,
			})
		}
	})

	t.Run("Should not be able to send Airdrop without collection, good events will be emitted", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		user3 := otu.O.Address("user3")

		res := otu.O.Tx("sendNFTsSafe",
			WithSigner("user1"),
			WithArg("allReceivers", []string{user3, user3, user3}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
			WithArg("donationTypes", `[nil, nil, nil]`),
			WithArg("donationAmounts", `[nil, nil, nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).
			AssertSuccess(t)

		for i, id := range ids {

			res.AssertEvent(t, "FindAirdropper.AirdropFailed", map[string]interface{}{
				"fromName": "user1",
				"from":     otu.O.Address("user1"),
				"to":       otu.O.Address("user3"),
				"id":       id,
				"uuid":     id,
				"type":     dandyType,
				"context": map[string]interface{}{
					"message": fmt.Sprintf("Message %d", i),
					"tenant":  "find",
				},
				"reason": "Invalid Receiver Capability",
			})

		}
	})

	t.Run("Should be able to get Airdrop details with a script", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		user3 := otu.O.Address("user3")

		makeResult := func(account, cplinked bool, id, index uint64, nftInplace, ok bool, receiver, receiverAddress string, receiverlinked bool, t string, hasProfile bool) map[string]interface{} {
			res := map[string]interface{}{
				"accountInitialized":     account,
				"address":                receiverAddress,
				"collectionPublicLinked": cplinked,
				"id":                     id,
				"isDapper":               false,
				"message":                fmt.Sprintf("Message %d", index),
				"nftInPlace":             nftInplace,
				"ok":                     ok,
				"receiver":               receiver,
				"receiverLinked":         receiverlinked,
				"royalties": map[string]interface{}{
					"royalties": []interface{}{
						map[string]interface{}{
							"acceptTypes": []interface{}{
								otu.identifier("FlowToken", "Vault"),
								otu.identifier("FUSD", "Vault"),
								otu.identifier("FiatToken", "Vault"),
							},
							"address":     otu.O.Address("user1"),
							"cut":         0.05,
							"description": "creator",
							"name":        "user1",
						},
						map[string]interface{}{
							"acceptTypes": []interface{}{
								otu.identifier("FlowToken", "Vault"),
								otu.identifier("FUSD", "Vault"),
								otu.identifier("FiatToken", "Vault"),
							},
							"address":     otu.O.Address("find"),
							"cut":         0.025,
							"description": "find forge",
						},
					},
					"totalRoyalty": 0.075,
				},

				"type": t,
			}

			if hasProfile {
				res["inputName"] = receiver
				res["findName"] = receiver
				res["avatar"] = "https://find.xyz/assets/img/avatars/avatar14.png"
			}

			return res
		}

		res := otu.O.Script("sendNFTs",
			WithArg("sender", "user1"),
			WithArg("allReceivers", []string{"user1", "user2", user3}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
		)

		user1Res := makeResult(true, true, ids[0], 0, true, true, "user1", otu.O.Address("user1"), true, dandyType, true)
		user2Res := makeResult(true, true, ids[1], 1, true, true, "user2", otu.O.Address("user2"), false, dandyType, true)
		user3Res := makeResult(false, false, ids[2], 2, true, false, otu.O.Address("user3"), otu.O.Address("user3"), false, dandyType, false)

		res.AssertWant(t, autogold.Want("sendNFTs", litter.Sdump([]interface{}{user1Res, user2Res, user3Res})))

	})

	trxns := []string{
		"sendNFTsSafe",
		"sendNFTs",
		"sendNFTsSubsidize",
	}

	for _, trxn := range trxns {
		t.Run(fmt.Sprintf("Should be able to send Airdrop with sending funds to royalty holders %s", trxn), func(t *testing.T) {

			ids := otu.mintThreeExampleDandies()

			res := otu.O.Tx(trxn,
				WithSigner("user1"),
				WithArg("allReceivers", []string{"user2", "user2", "user2"}),
				WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
				WithArg("ids", ids),
				WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
				WithArg("donationTypes", fmt.Sprintf(`["%s" , nil, nil]`, fusd)),
				WithArg("donationAmounts", fmt.Sprintf(`[%2f , nil, nil]`, 10.0)),
				WithArg("findDonationType", nil),
				WithArg("findDonationAmount", nil),
			).
				AssertSuccess(t)

			for i, id := range ids {

				events := res.GetEventsWithName("FindAirdropper.Airdropped")
				mockField := map[string]interface{}{}
				for _, e := range events {
					field, exist := e.Fields["nftInfo"].(map[string]interface{})
					if exist {
						mockId := field["id"].(uint64)
						if id == mockId {
							field["id"] = id
							field["type"] = dandyType
							mockField = field
						}
					}
				}

				res.AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
					"fromName": "user1",
					"from":     otu.O.Address("user1"),
					"toName":   "user2",
					"to":       otu.O.Address("user2"),
					"uuid":     id,
					"context": map[string]interface{}{
						"message": fmt.Sprintf("Message %d", i),
						"tenant":  "find",
					},
					"nftInfo": mockField,
				})

			}

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
				res.AssertEvent(t, "FUSD.TokensDeposited", want)
			}
		})

		t.Run(fmt.Sprintf("Should be able to send Airdrop and donate funds to FIND! %s", trxn), func(t *testing.T) {

			ids := otu.mintThreeExampleDandies()
			optional := cadence.NewOptional(cadence.String(fusd))

			res := otu.O.Tx(trxn,
				WithSigner("user1"),
				WithArg("allReceivers", []string{"user2", "user2", "user2"}),
				WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
				WithArg("ids", ids),
				WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
				WithArg("donationTypes", `[nil, nil, nil]`),
				WithArg("donationAmounts", `[nil, nil, nil]`),
				WithArg("findDonationType", optional),
				WithArg("findDonationAmount", "10.0"),
			).
				AssertSuccess(t)

			for i, id := range ids {

				events := res.GetEventsWithName("FindAirdropper.Airdropped")
				mockField := map[string]interface{}{}
				for _, e := range events {
					field, exist := e.Fields["nftInfo"].(map[string]interface{})
					if exist {
						mockId := field["id"].(uint64)
						if id == mockId {
							field["id"] = id
							field["type"] = dandyType
							mockField = field
						}
					}
				}

				res.AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
					"from":     otu.O.Address("user1"),
					"fromName": "user1",
					"to":       otu.O.Address("user2"),
					"toName":   "user2",
					"uuid":     id,
					"context": map[string]interface{}{
						"message": fmt.Sprintf("Message %d", i),
						"tenant":  "find",
					},
					"nftInfo": mockField,
				})

			}

			res.AssertEvent(t, "FIND.FungibleTokenSent", map[string]interface{}{
				"from":      otu.O.Address("user1"),
				"fromName":  "user1",
				"toAddress": otu.O.Address("find-admin"),
				"message":   "donation to .find",
				"tag":       "donation",
				"amount":    10.0,
				"ftType":    fusd,
			})

			res.AssertEvent(t, "FUSD.TokensDeposited", map[string]interface{}{
				"to":     otu.O.Address("find-admin"),
				"amount": 10.0,
			})
		})
	}

	t.Run("Should be able to send Airdrop if royalty is not there, donate to find", func(t *testing.T) {

		id, err := otu.mintRoyaltylessNFT("user1")
		require.NoError(t, err)
		optional := cadence.NewOptional(cadence.String(fusd))
		fusdAmount := 11.0

		res := otu.O.Tx("sendNFTs",
			WithSigner("user1"),
			WithArg("allReceivers", []string{"user2"}),
			WithArg("nftIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("ids", []uint64{id}),
			WithArg("memos", []string{"Message 0"}),
			WithArg("donationTypes", []*string{&fusd}),
			WithArg("donationAmounts", []*float64{&fusdAmount}),
			WithArg("findDonationType", optional),
			WithArg("findDonationAmount", "10.0"),
		).
			AssertSuccess(t)

		res.AssertEvent(t, "FIND.FungibleTokenSent", map[string]interface{}{
			"from":      otu.O.Address("user1"),
			"fromName":  "user1",
			"toAddress": otu.O.Address("find-admin"),
			"message":   "donation to .find",
			"tag":       "donation",
			"amount":    21.0,
			"ftType":    fusd,
		})

		res.AssertEvent(t, "FUSD.TokensDeposited", map[string]interface{}{
			"to":     otu.O.Address("find-admin"),
			"amount": 21.0,
		})
	})
}
