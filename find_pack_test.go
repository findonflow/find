package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
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
			WithArg("startTime", createIntUFix64(map[int]float64{1: 10.0, 2: 20.0, 3: 30.0})),
			WithArg("endTime", createIntUFix64(map[int]float64{1: 20.0, 2: 30.0})),
			WithArg("floatEventId", createIntUInt64(map[int]uint64{1: freeMintFloat, 2: whiteListFloat})),
			WithArg("price", createIntUFix64(map[int]float64{1: 0.0, 2: 4.2, 3: 4.2})),
			WithArg("purchaseLimit", createIntUInt64(map[int]uint64{1: 1, 2: 20})),
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
			WithArg("startTime", createIntUFix64(map[int]float64{1: 0.0})),
			WithArg("endTime", createIntUFix64(map[int]float64{})),
			WithArg("floatEventId", createIntUInt64(map[int]uint64{1: floatID})),
			WithArg("price", createIntUFix64(map[int]float64{1: 4.20})),
			WithArg("purchaseLimit", createIntUInt64(map[int]uint64{})),
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
			WithArg("startTime", createIntUFix64(map[int]float64{1: 0.0})),
			WithArg("endTime", createIntUFix64(map[int]float64{})),
			WithArg("floatEventId", createIntUInt64(map[int]uint64{1: floatID})),
			WithArg("price", createIntUFix64(map[int]float64{1: 4.20})),
			WithArg("purchaseLimit", createIntUInt64(map[int]uint64{})),
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
			WithArg("startTime", createIntUFix64(map[int]float64{1: 0.0})),
			WithArg("endTime", createIntUFix64(map[int]float64{})),
			WithArg("floatEventId", createIntUInt64(map[int]uint64{1: floatID})),
			WithArg("price", createIntUFix64(map[int]float64{1: 4.20})),
			WithArg("purchaseLimit", createIntUInt64(map[int]uint64{})),
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

	t.Run("Shouldg get the lowest price if several options are enabled at the same time", func(t *testing.T) {

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
			WithArg("startTime", createIntUFix64(map[int]float64{1: 0.0, 2: 0.0, 3: 0.0})),
			WithArg("endTime", createIntUFix64(map[int]float64{})),
			WithArg("floatEventId", createIntUInt64(map[int]uint64{1: floatID, 2: floatID, 3: floatID})),
			WithArg("price", createIntUFix64(map[int]float64{1: 3.3, 2: 2.2, 3: 1.1})),
			WithArg("purchaseLimit", createIntUInt64(map[int]uint64{})),
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
}
