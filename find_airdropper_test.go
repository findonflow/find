package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/onflow/cadence"
	"github.com/sanity-io/litter"
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

	dandyType := fmt.Sprintf("A.%s.%s.%s", otu.O.Account("account").Address().String(), "Dandy", "NFT")
	fusd := fmt.Sprintf("A.%s.%s.%s", otu.O.Account("account").Address().String(), "FUSD", "Vault")
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
				},
				"nftInfo": mockField,
			})
		}
	})

	packType := "user1"
	packTypeId := uint64(1)
	salt := "find"
	singleType := []string{exampleNFTType}

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
			WithSigner("find"),
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
				field["type"] = "A.f8d6e0586b0a20c7.FindPack.NFT"
				mockField = field
			}
		}

		res.AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
			"from":   otu.O.Address("account"),
			"toName": "user2",
			"to":     otu.O.Address("user2"),
			"context": map[string]interface{}{
				"message": "I can use struct here",
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

			events := res.GetEventsWithName("FindAirdropper.AirdropFailed")
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

			res.AssertEvent(t, "FindAirdropper.AirdropFailed", map[string]interface{}{
				"fromName": "user1",
				"from":     otu.O.Address("user1"),
				"to":       otu.O.Address("user3"),
				"uuid":     id,
				"context": map[string]interface{}{
					"message": fmt.Sprintf("Message %d", i),
				},
				"reason":  "Invalid Receiver Capability",
				"nftInfo": mockField,
			})

		}
	})

	t.Run("Should be able to get Airdrop details with a script", func(t *testing.T) {

		ids := otu.mintThreeExampleDandies()
		user3 := otu.O.Address("user3")

		makeResult := func(account, cplinked bool, id, index uint64, nftInplace, ok bool, receiver string, receiverlinked bool, t string, hasProfile bool) map[string]interface{} {
			res := map[string]interface{}{
				"accountInitialized":     account,
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
								fmt.Sprintf("A.%s.%s.Vault", "0ae53cb6e3f42a79", "FlowToken"),
								fmt.Sprintf("A.%s.%s.Vault", otu.O.Account("account").Address().String(), "FUSD"),
								fmt.Sprintf("A.%s.%s.Vault", otu.O.Account("account").Address().String(), "FiatToken"),
							},
							"address":     otu.O.Address("user1"),
							"cut":         0.05,
							"description": "creator",
							"name":        "user1",
						},
						map[string]interface{}{
							"acceptTypes": []interface{}{
								fmt.Sprintf("A.%s.%s.Vault", "0ae53cb6e3f42a79", "FlowToken"),
								fmt.Sprintf("A.%s.%s.Vault", otu.O.Account("account").Address().String(), "FUSD"),
								fmt.Sprintf("A.%s.%s.Vault", otu.O.Account("account").Address().String(), "FiatToken"),
							},
							"address":     otu.O.Address("account"),
							"cut":         0.025,
							"description": "find forge",
							"name":        "find",
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

		user1Res := makeResult(true, true, ids[0], 0, true, true, "user1", true, dandyType, true)
		user2Res := makeResult(true, true, ids[1], 1, true, true, "user2", false, dandyType, true)
		user3Res := makeResult(false, false, ids[2], 2, true, false, otu.O.Address("user3"), false, dandyType, false)

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
					"to":     otu.O.Address("account"),
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
					},
					"nftInfo": mockField,
				})

			}

			res.AssertEvent(t, "FIND.FungibleTokenSent", map[string]interface{}{
				"from":      otu.O.Address("user1"),
				"fromName":  "user1",
				"toAddress": otu.O.Address("account"),
				"message":   "donation to .find",
				"tag":       "donation",
				"amount":    10.0,
				"ftType":    fusd,
			})

			res.AssertEvent(t, "FUSD.TokensDeposited", map[string]interface{}{
				"to":     otu.O.Address("account"),
				"amount": 10.0,
			})
		})
	}

}
