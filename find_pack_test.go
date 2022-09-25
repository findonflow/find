package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestFindPack(t *testing.T) {

	packTypeId := uint64(1)
	salt := "find"
	buyer := "user1"

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(10000.0, "user1").
		createUser(10000.0, "user2").
		registerUser("user1").
		buyForge("user1").
		registerExampleNFTInNFTRegistry()

	t.Run("Should be able to mint Example NFTs", func(t *testing.T) {
		otu.mintExampleNFTs()
	})

	t.Run("Should be able to register pack data", func(t *testing.T) {

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")
		packTypeId++
	})

	t.Run("Should be able to mint pack", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account").
			mintPack("user1", packTypeId, []uint64{id1}, salt)
		packTypeId++

	})

	t.Run("Should be able to buy pack", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")
		otu.mintPack("user1", packTypeId, ids, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		packTypeId++

	})

	t.Run("Should be able to buy pack and open pack", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")
		packId := otu.mintPack("user1", packTypeId, ids, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)
		packTypeId++

	})

	t.Run("Should be able to buy and open", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")
		packId := otu.mintPack("user1", packTypeId, ids, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)
		otu.fulfillPack(packId, ids, salt)
		packTypeId++
	})

	t.Run("Should be able to buy and open with no collection setup", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")
		packId := otu.mintPack("user1", packTypeId, ids, salt)

		otu.buyPack("user2", buyer, packTypeId, 1, 4.20)
		otu.openPack("user2", packId)
		otu.fulfillPack(packId, ids, salt)
		packTypeId++
	})

	t.Run("Should get transferred to DLQ if try to open with wrong salt", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")
		packId := otu.mintPack("user1", packTypeId, ids, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)

		mapping := map[string][]uint64{
			"A.f8d6e0586b0a20c7.ExampleNFT.NFT": ids,
		}

		otu.O.Tx("adminFulfillFindPack",
			WithSigner("find"),
			WithArg("packId", packId),
			WithArg("rewardIds", createStringToUInt64Array(mapping)),
			WithArg("salt", "wrong salt"),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindPack.FulfilledError", map[string]interface{}{
				"packId":  packId,
				"address": otu.O.Address(buyer),
				"reason":  "The content of the pack was not verified with the hash provided at mint",
			})
		packTypeId++

	})

	t.Run("Should not be able to buy pack before drop is open", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, 0.0, 2.0, 2.0, false, 0, "find", "account")
		otu.mintPack("user1", packTypeId, ids, salt)

		otu.O.Tx("buyFindPack",
			WithSigner(buyer),
			WithArg("packTypeName", buyer),
			WithArg("packTypeId", packTypeId),
			WithArg("numberOfPacks", 1),
			WithArg("totalAmount", 4.2),
		).
			AssertFailure(t, "Cannot buy the pack now")
		packTypeId++

	})

	t.Run("Should not be able to open the pack before it is available", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 2.0, false, 0, "find", "account")
		packId := otu.mintPack("user1", packTypeId, ids, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)

		otu.O.Tx("openFindPack",
			WithSigner(buyer),
			WithArg("packId", packId),
		).
			AssertFailure(t, "You cannot open the pack yet")
		packTypeId++

	})

	t.Run("Should get transferred to DLQ if storage full", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")
		packId := otu.mintPack("user1", packTypeId, ids, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)

		otu.O.Tx("testFillUpStorage",
			WithSigner(buyer),
		).
			AssertSuccess(t)

		// try to fill that up with Example NFT

		for {
			res := otu.O.Tx("testMintExampleNFT",
				WithSigner("user1"),
				WithArg("name", "user1"),
				WithArg("artist", "Bam"),
				WithArg("nftName", "ExampleNFT"),
				WithArg("nftDescription", "This is an ExampleNFT"),
				WithArg("nftUrl", "This is an exampleNFT url"),
				WithArg("traits", []uint64{1, 2, 3}),
				WithArg("collectionDescription", "Example NFT FIND"),
				WithArg("collectionExternalURL", "Example NFT external url"),
				WithArg("collectionSquareImage", "Example NFT square image"),
				WithArg("collectionBannerImage", "Example NFT banner image"),
			)
			if res.Err != nil {
				break
			}
		}

		mapping := map[string][]uint64{
			"A.f8d6e0586b0a20c7.ExampleNFT.NFT": ids,
		}

		otu.O.Tx("adminFulfillFindPack",
			WithSigner("find"),
			WithArg("packId", packId),
			WithArg("rewardIds", createStringToUInt64Array(mapping)),
			WithArg("salt", "wrong salt"),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindPack.FulfilledError", map[string]interface{}{
				"packId":  packId,
				"address": otu.O.Address(buyer),
				"reason":  "Not enough flow to hold the content of the pack. Please top up your account"})

		otu.O.Tx("testRefillStorage",
			WithSigner(buyer),
		).
			AssertSuccess(t)
		packTypeId++

	})

	// /* Tests on Float implementation */
	t.Run("Should be able to buy nft if the user has the float and with a whitelist.", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("account")

		otu.claimFloat("account", buyer, floatID)

		otu.registerPackType("user1", packTypeId, 0.0, 10.0, 15.0, false, floatID, "find", "account")
		otu.mintPack("user1", packTypeId, ids, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		packTypeId++
	})

	t.Run("Should not be able to buy nft if the user doesnt have the float during the whitelist period, but can buy in public sale.", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("account")

		// in the test, 0.0 whitelist time -> no whitelist
		otu.registerPackType("user1", packTypeId, 0.0, 10.0, 15.0, false, floatID, "find", "account")
		otu.mintPack("user1", packTypeId, ids, salt)

		otu.O.Tx("buyFindPack",
			WithSigner(buyer),
			WithArg("packTypeName", buyer),
			WithArg("packTypeId", packTypeId),
			WithArg("numberOfPacks", 1),
			WithArg("totalAmount", 4.2),
		).
			AssertFailure(t, "Cannot buy the pack now")

		otu.tickClock(10.0)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		packTypeId++
	})

	t.Run("Should be able to buy nft for different price", func(t *testing.T) {
		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		freeMintFloat := otu.createFloatEvent("account")
		whiteListFloat := otu.createFloatEvent("account")

		otu.claimFloat("account", buyer, freeMintFloat)
		otu.claimFloat("account", buyer, whiteListFloat)

		otu.O.Tx("adminRegisterFindPackMetadata",
			WithSigner("find"),
			WithArg("lease", buyer),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find"),
			WithArg("openTime", 1.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "account"),
			WithArg("requiresReservation", false),
			WithArg("startTime", createStringUFix64(map[string]float64{"whiteList": 10.0, "pre-sale": 20.0, "public sale": 30.0})),
			WithArg("endTime", createStringUFix64(map[string]float64{"whiteList": 20.0, "pre-sale": 30.0})),
			WithArg("floatEventId", createStringUInt64(map[string]uint64{"whiteList": freeMintFloat, "pre-sale": whiteListFloat})),
			WithArg("price", createStringUFix64(map[string]float64{"whiteList": 0.0, "pre-sale": 4.2, "public sale": 4.2})),
			WithArg("purchaseLimit", createStringUInt64(map[string]uint64{"whiteList": 1, "pre-sale": 20})),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindPack.MetadataRegistered", map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.mintPack("user1", packTypeId, ids, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 0.0)
		// no need to pump packTypeId here
	})

	t.Run("Should not be able to buy nft for free with free-mint Float more than allowed", func(t *testing.T) {
		otu.O.Tx("buyFindPack",
			WithSigner(buyer),
			WithArg("packTypeName", buyer),
			WithArg("packTypeId", packTypeId),
			WithArg("numberOfPacks", 1),
			WithArg("totalAmount", 0.0),
		).
			AssertFailure(t, "Cannot buy the pack now")
		packTypeId++
	})

	/* Tests on Royalty implementation */
	t.Run("Should have 0.15 cut to find", func(t *testing.T) {

		totalAmount := 4.2

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("account")

		otu.registerPackType("user1", packTypeId, 0.0, 10.0, 15.0, false, floatID, "find", "account")
		otu.mintPack("user1", packTypeId, ids, salt)

		otu.O.Tx("buyFindPack",
			WithSigner(buyer),
			WithArg("packTypeName", buyer),
			WithArg("packTypeId", packTypeId),
			WithArg("numberOfPacks", 1),
			WithArg("totalAmount", 4.2),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
				"amount": totalAmount * 0.15,
				"to":     otu.O.Address("account"),
			}).
			AssertEvent(t, "A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
				"amount": totalAmount * 0.15,
				"to":     otu.O.Address("account"),
			})
		packTypeId++
	})

	t.Run("Should be able to buy only if fulfills all verifiers specified", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("account")

		// buyer should have find name "user1" and float
		otu.O.Tx("testadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "account"),
			WithArg("requiresReservation", false),
			WithArg("startTime", createStringUFix64(map[string]float64{"public sale": 0.0})),
			WithArg("endTime", createStringUFix64(map[string]float64{})),
			WithArg("floatEventId", createStringUInt64(map[string]uint64{"public sale": floatID})),
			WithArg("price", createStringUFix64(map[string]float64{"public sale": 4.20})),
			WithArg("purchaseLimit", createStringUInt64(map[string]uint64{})),
			WithArg("checkAll", true),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindPack.MetadataRegistered", map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.mintPack("user1", packTypeId, ids, salt)

		// should not be able to buy with no float
		otu.O.Tx("buyFindPack",
			WithSigner(buyer),
			WithArg("packTypeName", buyer),
			WithArg("packTypeId", packTypeId),
			WithArg("numberOfPacks", 1),
			WithArg("totalAmount", 4.2),
		).
			AssertFailure(t, "Cannot buy the pack now")

		// should be able to buy with user1 name and float
		otu.claimFloat("account", buyer, floatID)
		otu.buyPack(buyer, buyer, packTypeId, 1, 4.2)

		packTypeId++

	})

	t.Run("Should be able to buy if fulfills either verifiers specified", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("account")

		// buyer should have find name "user1" or float
		otu.O.Tx("testadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "account"),
			WithArg("requiresReservation", false),
			WithArg("startTime", createStringUFix64(map[string]float64{"public sale": 0.0})),
			WithArg("endTime", createStringUFix64(map[string]float64{})),
			WithArg("floatEventId", createStringUInt64(map[string]uint64{"public sale": floatID})),
			WithArg("price", createStringUFix64(map[string]float64{"public sale": 4.20})),
			WithArg("purchaseLimit", createStringUInt64(map[string]uint64{})),
			WithArg("checkAll", false),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindPack.MetadataRegistered", map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.mintPack("user1", packTypeId, ids, salt)

		// should be able to buy with user1 name only
		otu.buyPack(buyer, buyer, packTypeId, 1, 4.2)

		packTypeId++

	})

	t.Run("Should be able to buy if fulfills either verifiers specified 2", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("account")

		// buyer should have find name "user1" or float
		otu.O.Tx("testadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "account"),
			WithArg("requiresReservation", false),
			WithArg("startTime", createStringUFix64(map[string]float64{"public sale": 0.0})),
			WithArg("endTime", createStringUFix64(map[string]float64{})),
			WithArg("floatEventId", createStringUInt64(map[string]uint64{"public sale": floatID})),
			WithArg("price", createStringUFix64(map[string]float64{"public sale": 4.20})),
			WithArg("purchaseLimit", createStringUInt64(map[string]uint64{})),
			WithArg("checkAll", false),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindPack.MetadataRegistered", map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.mintPack("user1", packTypeId, ids, salt)

		// should be able to buy with float only
		otu.claimFloat("account", "user2", floatID)
		otu.buyPack("user2", buyer, packTypeId, 1, 4.2)

		packTypeId++

	})

	t.Run("Should get the lowest price if several options are enabled at the same time", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("account")

		// buyer should have find name "user1" or float
		otu.O.Tx("testadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "account"),
			WithArg("requiresReservation", false),
			WithArg("startTime", createStringUFix64(map[string]float64{"whiteList": 0.0, "pre-sale": 0.0, "public sale": 0.0})),
			WithArg("endTime", createStringUFix64(map[string]float64{})),
			WithArg("floatEventId", createStringUInt64(map[string]uint64{"whiteList": floatID, "pre-sale": floatID, "public sale": floatID})),
			WithArg("price", createStringUFix64(map[string]float64{"whiteList": 3.3, "pre-sale": 2.2, "public sale": 1.1})),
			WithArg("purchaseLimit", createStringUInt64(map[string]uint64{})),
			WithArg("checkAll", false),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindPack.MetadataRegistered", map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.mintPack("user1", packTypeId, ids, salt)

		// should be able to buy with float only
		otu.claimFloat("account", buyer, floatID)
		otu.buyPack(buyer, buyer, packTypeId, 1, 1.1)

		packTypeId++

	})

	// buy with Reservation
	t.Run("Should be able to buy with reservation", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, 0.0, 0.0, 15.0, true, 0, "find", "account")
		packId, signature := otu.mintPackWithSignature("user1", packTypeId, ids, salt)

		otu.O.Tx("buyFindPackWithReservation",
			WithSigner(buyer),
			WithArg("packTypeName", buyer),
			WithArg("packTypeId", packTypeId),
			WithArg("packId", packId),
			WithArg("amount", 4.2),
			WithArg("signature", signature),
		).
			Print().
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindPack.Purchased", map[string]interface{}{
				"packId": packId,
			})

		packTypeId++
	})

	// Scripts - ways to return useful sales
	t.Run("should return sale details for user", func(t *testing.T) {

		floatID := otu.createFloatEvent("account")

		// buyer should have find name "user1" or float
		otu.O.Tx("testadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "account"),
			WithArg("requiresReservation", false),
			WithArg("startTime", createStringUFix64(map[string]float64{"whiteList": 1.0, "pre-sale": 2.0, "public sale": 3.0})),
			WithArg("endTime", createStringUFix64(map[string]float64{"whiteList": 2.0, "pre-sale": 3.0, "public sale": 4.0})),
			WithArg("floatEventId", createStringUInt64(map[string]uint64{"whiteList": floatID, "pre-sale": floatID, "public sale": floatID})),
			WithArg("price", createStringUFix64(map[string]float64{"whiteList": 3.3, "pre-sale": 2.2, "public sale": 1.1})),
			WithArg("purchaseLimit", createStringUInt64(map[string]uint64{})),
			WithArg("checkAll", false),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindPack.MetadataRegistered", map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.O.Script("getFindPackSaleDetails",
			WithArg("packTypeName", "user1"),
			WithArg("packTypeId", packTypeId),
		).
			AssertWant(t, autogold.Want("getFindPackSaleDetails", map[string]interface{}{
				"description": "user1 season #19", "itemTypes": []interface{}{"A.f8d6e0586b0a20c7.ExampleNFT.NFT"},
				"name":                "user1 season #19",
				"openTime":            2,
				"packFields":          map[string]interface{}{"Items": "1"},
				"packsLeft":           0,
				"requiresReservation": false,
				"saleEnded":           true,
				"saleInfos": []interface{}{
					map[string]interface{}{
						"endTime":   3,
						"name":      "pre-sale",
						"price":     2.2,
						"startTime": 2,
						"verifiers": []interface{}{
							"User with one of these FLOATs are verified : 619",
							"Users with one of these find names are verified : user1",
						},
						"verifyAll": false,
					},
					map[string]interface{}{
						"endTime":   2,
						"name":      "whiteList",
						"price":     3.3,
						"startTime": 1,
						"verifiers": []interface{}{
							"User with one of these FLOATs are verified : 619",
							"Users with one of these find names are verified : user1",
						},
						"verifyAll": false,
					},
					map[string]interface{}{
						"endTime":   4,
						"name":      "public sale",
						"price":     1.1,
						"startTime": 3,
						"verifiers": []interface{}{
							"User with one of these FLOATs are verified : 619",
							"Users with one of these find names are verified : user1",
						},
						"verifyAll": false,
					},
				},
				"storageRequirement": 10000,
				"thumbnailHash":      "thumbnailHash",
				"walletType":         "A.0ae53cb6e3f42a79.FlowToken.Vault",
			}))
		packTypeId++
	})

	t.Run("Should get the running sale for user with the lowest price -> 2.2", func(t *testing.T) {

		floatID := otu.createFloatEvent("account")
		otu.claimFloat("account", buyer, floatID)

		// buyer should have find name "user1" or float
		otu.O.Tx("testadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "account"),
			WithArg("requiresReservation", false),
			WithArg("startTime", createStringUFix64(map[string]float64{"whiteList": 1.0, "pre-sale": 2.0, "public sale": 3.0})),
			WithArg("endTime", createStringUFix64(map[string]float64{"whiteList": 2.0})),
			WithArg("floatEventId", createStringUInt64(map[string]uint64{"whiteList": floatID, "pre-sale": floatID})),
			WithArg("price", createStringUFix64(map[string]float64{"whiteList": 1.1, "pre-sale": 2.2, "public sale": 3.3})),
			WithArg("purchaseLimit", createStringUInt64(map[string]uint64{})),
			WithArg("checkAll", false),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindPack.MetadataRegistered", map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.O.Script("getFindPackSaleDetailsWithUser",
			WithArg("packTypeName", "user1"),
			WithArg("packTypeId", packTypeId),
			WithArg("user", buyer),
		).
			AssertWant(t, autogold.Want("getFindPackSaleDetailsWithUser1", map[string]interface{}{
				"description": "user1 season #20", "itemTypes": []interface{}{"A.f8d6e0586b0a20c7.ExampleNFT.NFT"},
				"name":                "user1 season #20",
				"openTime":            2,
				"packFields":          map[string]interface{}{"Items": "1"},
				"packsLeft":           0,
				"requiresReservation": false,
				"storageRequirement":  10000,
				"thumbnailHash":       "thumbnailHash",
				"userQualifiedSale": map[string]interface{}{
					"canBuyNow":          false,
					"name":               "pre-sale",
					"price":              2.2,
					"startTime":          2,
					"userPurchaseRecord": 0,
				},
				"walletType": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			}))
		// no need to bump packTypeId here
	})

	t.Run("Should get the running sale for user with the lowest price -> 3.3", func(t *testing.T) {

		otu.O.Script("getFindPackSaleDetailsWithUser",
			WithArg("packTypeName", "user1"),
			WithArg("packTypeId", packTypeId),
			WithArg("user", "user2"),
		).
			AssertWant(t, autogold.Want("getFindPackSaleDetailsWithUser2", map[string]interface{}{
				"description": "user1 season #20", "itemTypes": []interface{}{"A.f8d6e0586b0a20c7.ExampleNFT.NFT"},
				"name":                "user1 season #20",
				"openTime":            2,
				"packFields":          map[string]interface{}{"Items": "1"},
				"packsLeft":           0,
				"requiresReservation": false,
				"storageRequirement":  10000,
				"thumbnailHash":       "thumbnailHash",
				"userQualifiedSale": map[string]interface{}{
					"canBuyNow":          false,
					"name":               "public sale",
					"price":              3.3,
					"startTime":          3,
					"userPurchaseRecord": 0,
				},
				"walletType": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			}))

	})

	t.Run("Should get all pack sale under a lease name type", func(t *testing.T) {

		otu.O.Script("getAllFindPackSaleDetailsByName",
			WithArg("packTypeName", "user1"),
		).
			AssertWithPointerWant(t, "/"+fmt.Sprint(packTypeId), autogold.Want("getAllFindPackSaleDetailsByName", map[string]interface{}{
				"description": "user1 season #20", "itemTypes": []interface{}{"A.f8d6e0586b0a20c7.ExampleNFT.NFT"},
				"name":                "user1 season #20",
				"openTime":            2,
				"packFields":          map[string]interface{}{"Items": "1"},
				"packsLeft":           0,
				"requiresReservation": false,
				"saleEnded":           true,
				"saleInfos": []interface{}{
					map[string]interface{}{
						"name":      "pre-sale",
						"price":     2.2,
						"startTime": 2,
						"verifiers": []interface{}{
							"User with one of these FLOATs are verified : 623",
							"Users with one of these find names are verified : user1",
						},
						"verifyAll": false,
					},
					map[string]interface{}{
						"endTime":   2,
						"name":      "whiteList",
						"price":     1.1,
						"startTime": 1,
						"verifiers": []interface{}{
							"User with one of these FLOATs are verified : 623",
							"Users with one of these find names are verified : user1",
						},
						"verifyAll": false,
					},
					map[string]interface{}{
						"name":      "public sale",
						"price":     3.3,
						"startTime": 3,
						"verifyAll": false,
					},
				},
				"storageRequirement": 10000,
				"thumbnailHash":      "thumbnailHash",
				"walletType":         "A.0ae53cb6e3f42a79.FlowToken.Vault",
			}))
		packTypeId++
	})

}
