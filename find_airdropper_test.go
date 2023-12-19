package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/findonflow/find/findGo"
	"github.com/hexops/autogold"
)

// TODO: This test should send 1 in most tests and use multiple only in one test
func TestFindAirdropper(t *testing.T) {

	otu := &OverflowTestUtils{T: t, O: ot.O}

	dandyType := dandyNFTType(otu)
	ids := otu.getDandies()
	id := ids[0]

	ot.Run(t, "Should be able to send Airdrop", func(t *testing.T) {

		otu.O.Tx("sendNFTsSafe",
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
			AssertSuccess(t).
			AssertEvent(t, "FindAirdropper.Airdropped", map[string]interface{}{
				"from":     otu.O.Address("user1"),
				"fromName": "user1",
				"to":       otu.O.Address("user2"),
				"toName":   "user2",
			})
		//TODO: look at a better way of asserting these events
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

	ot.Run(t, "Should be able to send Airdrop with only collection public linked", func(t *testing.T) {

		otu.O.Tx("devUnlinkDandyReceiver",
			WithSigner("user2"),
		).AssertSuccess(t)

		otu.O.Tx("sendNFTsSafe",
			WithSigner("user1"),
			WithArg("allReceivers", []string{"user2", "user2", "user2"}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
			WithArg("donationTypes", `[nil, nil, nil]`),
			WithArg("donationAmounts", `[nil, nil, nil]`),
			WithArg("findDonationType", nil),
			WithArg("findDonationAmount", nil),
		).AssertSuccess(t)
		//TODO: test events better

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
				"message": fmt.Sprintf("Message 0"),
				"tenant":  "find",
			},
			"reason": "Invalid Receiver Capability",
		})

	})

	ot.Run(t, "Should be able to get Airdrop details with a script", func(t *testing.T) {

		user3 := otu.O.Address("user3")

		res := otu.O.Script("sendNFTs",
			WithArg("sender", "user1"),
			WithArg("allReceivers", []string{"user1", "user2", user3}),
			WithArg("nftIdentifiers", []string{dandyType, dandyType, dandyType}),
			WithArg("ids", ids),
			WithArg("memos", []string{"Message 0", "Message 1", "Message 2"}),
		)

		//we cant have this big thing here...
		res.AssertWant(t, autogold.Want("sendNFTs", `[]interface {}{
  map[string]interface {}{
    "accountInitialized": true,
    "address": "0xf669cb8d41ce0c74",
    "avatar": "https://find.xyz/assets/img/avatars/avatar14.png",
    "collectionPublicLinked": true,
    "findName": "user1",
    "id": 371,
    "inputName": "user1",
    "isDapper": false,
    "message": "Message 0",
    "nftInPlace": true,
    "ok": true,
    "receiver": "user1",
    "receiverLinked": true,
    "royalties": map[string]interface {}{
      "royalties": []interface {}{
        map[string]interface {}{
          "acceptTypes": []interface {}{
            "A.0ae53cb6e3f42a79.FlowToken.Vault",
            "A.f8d6e0586b0a20c7.FUSD.Vault",
            "A.f8d6e0586b0a20c7.FiatToken.Vault",
          },
          "address": "0xf669cb8d41ce0c74",
          "cut": 0.05,
          "description": "creator",
          "name": "user1",
        },
        map[string]interface {}{
          "acceptTypes": []interface {}{
            "A.0ae53cb6e3f42a79.FlowToken.Vault",
            "A.f8d6e0586b0a20c7.FUSD.Vault",
            "A.f8d6e0586b0a20c7.FiatToken.Vault",
          },
          "address": "0x179b6b1cb6755e31",
          "cut": 0.025,
          "description": "find forge",
        },
      },
      "totalRoyalty": 0.075,
    },
    "type": "A.179b6b1cb6755e31.Dandy.NFT",
  },
  map[string]interface {}{
    "accountInitialized": true,
    "address": "0x192440c99cb17282",
    "avatar": "https://find.xyz/assets/img/avatars/avatar14.png",
    "collectionPublicLinked": true,
    "findName": "user2",
    "id": 373,
    "inputName": "user2",
    "isDapper": false,
    "message": "Message 1",
    "nftInPlace": true,
    "ok": true,
    "receiver": "user2",
    "receiverLinked": true,
    "royalties": map[string]interface {}{
      "royalties": []interface {}{
        map[string]interface {}{
          "acceptTypes": []interface {}{
            "A.0ae53cb6e3f42a79.FlowToken.Vault",
            "A.f8d6e0586b0a20c7.FUSD.Vault",
            "A.f8d6e0586b0a20c7.FiatToken.Vault",
          },
          "address": "0xf669cb8d41ce0c74",
          "cut": 0.05,
          "description": "creator",
          "name": "user1",
        },
        map[string]interface {}{
          "acceptTypes": []interface {}{
            "A.0ae53cb6e3f42a79.FlowToken.Vault",
            "A.f8d6e0586b0a20c7.FUSD.Vault",
            "A.f8d6e0586b0a20c7.FiatToken.Vault",
          },
          "address": "0x179b6b1cb6755e31",
          "cut": 0.025,
          "description": "find forge",
        },
      },
      "totalRoyalty": 0.075,
    },
    "type": "A.179b6b1cb6755e31.Dandy.NFT",
  },
  map[string]interface {}{
    "accountInitialized": true,
    "address": "0xfd43f9148d4b725d",
    "avatar": "https://find.xyz/assets/img/avatars/avatar14.png",
    "collectionPublicLinked": true,
    "id": 372,
    "isDapper": false,
    "message": "Message 2",
    "nftInPlace": true,
    "ok": true,
    "receiver": "0xfd43f9148d4b725d",
    "receiverLinked": true,
    "royalties": map[string]interface {}{
      "royalties": []interface {}{
        map[string]interface {}{
          "acceptTypes": []interface {}{
            "A.0ae53cb6e3f42a79.FlowToken.Vault",
            "A.f8d6e0586b0a20c7.FUSD.Vault",
            "A.f8d6e0586b0a20c7.FiatToken.Vault",
          },
          "address": "0xf669cb8d41ce0c74",
          "cut": 0.05,
          "description": "creator",
          "name": "user1",
        },
        map[string]interface {}{
          "acceptTypes": []interface {}{
            "A.0ae53cb6e3f42a79.FlowToken.Vault",
            "A.f8d6e0586b0a20c7.FUSD.Vault",
            "A.f8d6e0586b0a20c7.FiatToken.Vault",
          },
          "address": "0x179b6b1cb6755e31",
          "cut": 0.025,
          "description": "find forge",
        },
      },
      "totalRoyalty": 0.075,
    },
    "type": "A.179b6b1cb6755e31.Dandy.NFT",
  },
}`))

	})

	/*
		  * TODO: fix these later
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
	*/
}
