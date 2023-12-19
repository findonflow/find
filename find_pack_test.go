package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestFindPack(t *testing.T) {

	packTypeId := uint64(1)
	salt := "find-admin"
	buyer := "user1"

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(10000.0, "user1").
		createUser(10000.0, "user2").
		registerUser("user1").
		buyForge("user1").
		registerExampleNFTInNFTRegistry()

	otu.setUUID(5000)

	singleType := []string{exampleNFTType(otu)}

	flow, err := otu.O.QualifiedIdentifier("FlowToken", "Vault")
	assert.NoError(otu.T, err)
	t.Run("Should be able to mint Example NFTs", func(t *testing.T) {
		otu.mintExampleNFTs()
	})

	t.Run("Should be able to register pack data", func(t *testing.T) {

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")
		packTypeId++
	})

	t.Run("Should be able to register pack as a User with struct", func(t *testing.T) {

		otu.O.Tx("registerFindPackMetadata",
			WithSigner("user1"),
			WithArg("forge", buyer),
			WithArg("name", buyer),
			WithArg("description", "test"),
			WithArg("typeId", packTypeId),
			WithArg("externalURL", "url"),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("bannerHash", "bannerHash"),
			WithArg("social", map[string]string{"twitter": "twitterLink"}),
			WithArg("wallet", "find-admin"),
			WithArg("walletType", flow),
			WithArg("openTime", 1.0),
			WithAddresses("primaryRoyaltyRecipients", "find", "find-admin"),
			WithArg("primaryRoyaltyCuts", []float64{0.1, 0.3}),
			WithArg("primaryRoyaltyDescriptions", []string{"", ""}),
			WithAddresses("secondaryRoyaltyRecipients", "find", "find-admin"),
			WithArg("secondaryRoyaltyCuts", []float64{0.1, 0.3}),
			WithArg("secondaryRoyaltyDescriptions", []string{"", ""}),
			WithArg("requiresReservation", false),
			WithArg("startTime", map[string]float64{}),
			WithArg("endTime", map[string]float64{}),
			WithArg("floatEventId", map[string]uint64{}),
			WithArg("price", map[string]float64{}),
			WithArg("purchaseLimit", map[string]uint64{}),
			WithArg("packFields", map[string]string{
				"Items": "1",
			}),
			WithArg("nftTypes", []string{exampleNFTType(otu)}),
			WithArg("storageRequirement", 50000),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "MetadataRegistered"), map[string]interface{}{
				"packTypeId": packTypeId,
			})
		packTypeId++
	})

	t.Run("Should be able to register pack as a User with struct", func(t *testing.T) {

		eventIden, err := otu.O.QualifiedIdentifier("FindPack", "MetadataRegistered")
		assert.NoError(otu.T, err)

		info := generatePackStruct(otu.O, "user1", packTypeId, singleType, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")

		otu.O.Tx("registerFindPackMetadataStruct",
			WithSigner("user1"),
			WithArg("info", info),
		).
			AssertSuccess(t).
			AssertEvent(t, eventIden, map[string]interface{}{
				"packTypeId": packTypeId,
			})

		packTypeId++
	})

	t.Run("Should be able to mint pack", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 1.0, 1.0, false, 0, "find-admin", "find").
			mintPack("user1", packTypeId, []uint64{id1}, singleType, salt)
		packTypeId++

	})

	t.Run("Should be able to buy pack", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")
		otu.mintPack("user1", packTypeId, ids, singleType, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		packTypeId++

	})

	t.Run("Should be able to buy pack and open pack", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")
		packId := otu.mintPack("user1", packTypeId, ids, singleType, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)
		packTypeId++

	})

	t.Run("Should be able to buy and open", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")
		packId := otu.mintPack("user1", packTypeId, ids, singleType, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)
		otu.fulfillPack(packId, ids, salt)
		packTypeId++
	})

	t.Run("Should be able to buy and open with no collection setup", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")
		packId := otu.mintPack("user1", packTypeId, ids, singleType, salt)

		otu.buyPack("user2", buyer, packTypeId, 1, 4.20)
		otu.openPack("user2", packId)
		otu.fulfillPack(packId, ids, salt)
		packTypeId++
	})

	t.Run("Should get transferred to DLQ if try to open with wrong salt", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")
		packId := otu.mintPack("user1", packTypeId, ids, singleType, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)

		otu.O.Tx("adminFulfillFindPack",
			WithSigner("find-admin"),
			WithArg("packId", packId),
			WithArg("typeIdentifiers", []string{exampleNFTType(otu)}),
			WithArg("rewardIds", ids),
			WithArg("salt", "wrong salt"),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "FulfilledError"), map[string]interface{}{
				"packId":  packId,
				"address": otu.O.Address(buyer),
				"reason":  "The content of the pack was not verified with the hash provided at mint",
			})
		packTypeId++

	})

	t.Run("Should not be able to buy pack before drop is open", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 2.0, 2.0, false, 0, "find-admin", "find")
		otu.mintPack("user1", packTypeId, ids, singleType, salt)

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

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 1.0, 2.0, false, 0, "find-admin", "find")
		packId := otu.mintPack("user1", packTypeId, ids, singleType, salt)

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

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")
		packId := otu.mintPack("user1", packTypeId, ids, singleType, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)

		otu.O.Tx("devFillUpStorage",
			WithSigner(buyer),
		).
			AssertSuccess(t)

		// try to fill that up with Example NFT

		res := otu.O.FillUpStorage(buyer)
		require.NoError(t, res.Error)

		fmt.Println(otu.O.GetFreeCapacity(buyer))

		pid := map[uint64][]uint64{packId: ids}
		types := map[uint64][]string{packId: {exampleNFTType(otu)}}

		otu.O.Tx("adminFulfillPacks",
			WithSigner("find-admin"),
			WithArg("types", types),
			WithArg("rewards", pid),
			WithArg("salts", map[uint64]string{packId: "wrong salt"}),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "FulfilledError"), map[string]interface{}{
				"packId":  packId,
				"address": otu.O.Address(buyer),
				"reason":  "Not enough flow to hold the content of the pack. Please top up your account"})

		otu.O.Tx("devRefillStorage",
			WithSigner(buyer),
		).
			AssertSuccess(t)
		packTypeId++

	})

	//  Tests on Float implementation
	t.Run("Should be able to buy nft if the user has the float and with a whitelist.", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("find")

		otu.claimFloat("find", buyer, floatID)

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 10.0, 15.0, false, floatID, "find-admin", "find")
		otu.mintPack("user1", packTypeId, ids, singleType, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		packTypeId++
	})

	t.Run("Should not be able to buy nft if the user doesnt have the float during the whitelist period, but can buy in access(all)lic sale.", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("find")

		// in the test, 0.0 whitelist time -> no whitelist
		otu.registerPackType("user1", packTypeId, singleType, 0.0, 10.0, 15.0, false, floatID, "find-admin", "find")
		otu.mintPack("user1", packTypeId, ids, singleType, salt)

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

	t.Run("Should be able to register with adminRegisterFindPackMetadata transaction", func(t *testing.T) {
		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		freeMintFloat := otu.createFloatEvent("find")
		whiteListFloat := otu.createFloatEvent("find")

		otu.claimFloat("find", buyer, freeMintFloat)
		otu.claimFloat("find", buyer, whiteListFloat)

		otu.O.Tx("adminRegisterFindPackMetadata",
			WithSigner("find-admin"),
			WithArg("forge", buyer),
			WithArg("name", buyer),
			WithArg("description", "test"),
			WithArg("typeId", packTypeId),
			WithArg("externalURL", "url"),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("bannerHash", "bannerHash"),
			WithArg("social", map[string]string{"twitter": "twitterLink"}),
			WithArg("wallet", "find-admin"),
			WithArg("walletType", flow),
			WithArg("openTime", 1.0),
			WithAddresses("primaryRoyaltyRecipients", "find", "find-admin"),
			WithArg("primaryRoyaltyCuts", []float64{0.1, 0.3}),
			WithArg("primaryRoyaltyDescriptions", []string{"", ""}),
			WithAddresses("secondaryRoyaltyRecipients", "find", "find-admin"),
			WithArg("secondaryRoyaltyCuts", []float64{0.1, 0.3}),
			WithArg("secondaryRoyaltyDescriptions", []string{"", ""}),
			WithArg("requiresReservation", false),
			WithArg("startTime", map[string]float64{"whiteList": 10.0, "pre-sale": 20.0, "public sale": 30.0}),
			WithArg("endTime", map[string]float64{"whiteList": 20.0, "pre-sale": 30.0}),
			WithArg("floatEventId", map[string]uint64{"whiteList": freeMintFloat, "pre-sale": whiteListFloat}),
			WithArg("price", map[string]float64{"whiteList": 0.0, "pre-sale": 4.2, "public sale": 4.2}),
			WithArg("purchaseLimit", map[string]uint64{"whiteList": 1, "pre-sale": 20}),
			WithArg("packFields", map[string]string{
				"Items": "1",
			}),
			WithArg("nftTypes", []string{exampleNFTType(otu)}),
			WithArg("storageRequirement", 50000),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "MetadataRegistered"), map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.mintPack("user1", packTypeId, ids, singleType, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 0.0)
		// no need to pump packTypeId here
	})

	t.Run("Should be able to buy nft for different price", func(t *testing.T) {
		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		freeMintFloat := otu.createFloatEvent("find")
		whiteListFloat := otu.createFloatEvent("find")

		otu.claimFloat("find", buyer, freeMintFloat)
		otu.claimFloat("find", buyer, whiteListFloat)

		otu.O.Tx("adminRegisterFindPackMetadata",
			WithSigner("find-admin"),
			WithArg("forge", buyer),
			WithArg("name", buyer),
			WithArg("description", "test"),
			WithArg("typeId", packTypeId),
			WithArg("externalURL", "url"),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("bannerHash", "bannerHash"),
			WithArg("social", map[string]string{"twitter": "twitterLink"}),
			WithArg("wallet", "find-admin"),
			WithArg("walletType", flow),
			WithArg("openTime", 1.0),
			WithAddresses("primaryRoyaltyRecipients", "find", "find-admin"),
			WithArg("primaryRoyaltyCuts", []float64{0.1, 0.3}),
			WithArg("primaryRoyaltyDescriptions", []string{"", ""}),
			WithAddresses("secondaryRoyaltyRecipients", "find", "find-admin"),
			WithArg("secondaryRoyaltyCuts", []float64{0.1, 0.3}),
			WithArg("secondaryRoyaltyDescriptions", []string{"", ""}),
			WithArg("requiresReservation", false),
			WithArg("startTime", map[string]float64{"whiteList": 10.0, "pre-sale": 20.0, "public sale": 30.0}),
			WithArg("endTime", map[string]float64{"whiteList": 20.0, "pre-sale": 30.0}),
			WithArg("floatEventId", map[string]uint64{"whiteList": freeMintFloat, "pre-sale": whiteListFloat}),
			WithArg("price", map[string]float64{"whiteList": 0.0, "pre-sale": 4.2, "public sale": 4.2}),
			WithArg("purchaseLimit", map[string]uint64{"whiteList": 1, "pre-sale": 20}),
			WithArg("packFields", map[string]string{
				"Items": "1",
			}),
			WithArg("nftTypes", []string{exampleNFTType(otu)}),
			WithArg("storageRequirement", 50000),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "MetadataRegistered"), map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.mintPack("user1", packTypeId, ids, singleType, salt)

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

	// Tests on Royalty implementation
	t.Run("Should have 0.15 cut to find", func(t *testing.T) {

		totalAmount := 4.2

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("find")

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 10.0, 15.0, false, floatID, "find-admin", "find")
		otu.mintPack("user1", packTypeId, ids, singleType, salt)

		otu.O.Tx("buyFindPack",
			WithSigner(buyer),
			WithArg("packTypeName", buyer),
			WithArg("packTypeId", packTypeId),
			WithArg("numberOfPacks", 1),
			WithArg("totalAmount", 4.2),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FlowToken", "TokensDeposited"), map[string]interface{}{
				"amount": totalAmount * 0.15,
				"to":     otu.O.Address("find"),
			})
		packTypeId++
	})

	t.Run("Should be able to buy only if fulfills all verifiers specified", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("find")

		// buyer should have find name "user1" and float
		otu.O.Tx("devadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find-admin"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find-admin"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "find"),
			WithArg("requiresReservation", false),
			WithArg("startTime", map[string]float64{"public sale": 0.0}),
			WithArg("endTime", map[string]float64{}),
			WithArg("floatEventId", map[string]uint64{"public sale": floatID}),
			WithArg("price", map[string]float64{"public sale": 4.20}),
			WithArg("purchaseLimit", map[string]uint64{}),
			WithArg("checkAll", true),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "MetadataRegistered"), map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.mintPack("user1", packTypeId, ids, singleType, salt)

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
		otu.claimFloat("find", buyer, floatID)
		otu.buyPack(buyer, buyer, packTypeId, 1, 4.2)

		packTypeId++

	})

	t.Run("Should be able to buy if fulfills either verifiers specified", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("find")

		// buyer should have find name "user1" or float
		otu.O.Tx("devadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find-admin"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find-admin"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "find"),
			WithArg("requiresReservation", false),
			WithArg("startTime", map[string]float64{"public sale": 0.0}),
			WithArg("endTime", map[string]float64{}),
			WithArg("floatEventId", map[string]uint64{"public sale": floatID}),
			WithArg("price", map[string]float64{"public sale": 4.20}),
			WithArg("purchaseLimit", map[string]uint64{}),
			WithArg("checkAll", false),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "MetadataRegistered"), map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.mintPack("user1", packTypeId, ids, singleType, salt)

		// should be able to buy with user1 name only
		otu.buyPack(buyer, buyer, packTypeId, 1, 4.2)

		packTypeId++

	})

	t.Run("Should be able to buy if fulfills either verifiers specified 2", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("find")

		// buyer should have find name "user1" or float
		otu.O.Tx("devadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find-admin"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find-admin"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "find"),
			WithArg("requiresReservation", false),
			WithArg("startTime", map[string]float64{"public sale": 0.0}),
			WithArg("endTime", map[string]float64{}),
			WithArg("floatEventId", map[string]uint64{"public sale": floatID}),
			WithArg("price", map[string]float64{"public sale": 4.20}),
			WithArg("purchaseLimit", map[string]uint64{}),
			WithArg("checkAll", false),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "MetadataRegistered"), map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.mintPack("user1", packTypeId, ids, singleType, salt)

		// should be able to buy with float only
		otu.claimFloat("find", "user2", floatID)
		otu.buyPack("user2", buyer, packTypeId, 1, 4.2)

		packTypeId++

	})

	t.Run("Should get the lowest price if several options are enabled at the same time", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		floatID := otu.createFloatEvent("find")

		// buyer should have find name "user1" or float
		otu.O.Tx("devadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find-admin"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find-admin"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "find"),
			WithArg("requiresReservation", false),
			WithArg("startTime", map[string]float64{"whiteList": 0.0, "pre-sale": 0.0, "public sale": 0.0}),
			WithArg("endTime", map[string]float64{}),
			WithArg("floatEventId", map[string]uint64{"whiteList": floatID, "pre-sale": floatID, "public sale": floatID}),
			WithArg("price", map[string]float64{"whiteList": 3.3, "pre-sale": 2.2, "public sale": 1.1}),
			WithArg("purchaseLimit", map[string]uint64{}),
			WithArg("checkAll", false),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "MetadataRegistered"), map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.mintPack("user1", packTypeId, ids, singleType, salt)

		// should be able to buy with float only
		otu.claimFloat("find", buyer, floatID)
		otu.buyPack(buyer, buyer, packTypeId, 1, 1.1)

		packTypeId++

	})

	// buy with Reservation
	t.Run("Should be able to buy with reservation", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, singleType, 0.0, 0.0, 15.0, true, 0, "find-admin", "find")
		packId, signature := otu.mintPackWithSignature("user1", packTypeId, ids, singleType, salt)

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
			AssertEvent(t, otu.identifier("FindPack", "Purchased"), map[string]interface{}{
				"packId": packId,
			})

		packTypeId++
	})

	// Scripts - ways to return useful sales
	t.Run("should return sale details for user", func(t *testing.T) {

		floatID := otu.createFloatEvent("find")

		// buyer should have find name "user1" or float
		otu.O.Tx("devadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find-admin"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find-admin"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "find"),
			WithArg("requiresReservation", false),
			WithArg("startTime", map[string]float64{"whiteList": 1.0, "pre-sale": 2.0, "public sale": 3.0}),
			WithArg("endTime", map[string]float64{"whiteList": 2.0, "pre-sale": 3.0, "public sale": 4.0}),
			WithArg("floatEventId", map[string]uint64{"whiteList": floatID, "pre-sale": floatID, "public sale": floatID}),
			WithArg("price", map[string]float64{"whiteList": 3.3, "pre-sale": 2.2, "public sale": 1.1}),
			WithArg("purchaseLimit", map[string]uint64{}),
			WithArg("checkAll", false),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "MetadataRegistered"), map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.O.Script("getAllFindPackSaleDetails",
			WithArg("packTypeName", "user1"),
		).
			AssertWithPointerWant(t, fmt.Sprintf("/%d", packTypeId), autogold.Want("getFindPackSaleDetails", map[string]interface{}{
				"collectionDisplay": map[string]interface{}{
					"bannerImage": map[string]interface{}{"file": map[string]interface{}{"url": "Example NFT banner image"}, "mediaType": "image"},
					"description": "Example NFT FIND",
					"externalURL": map[string]interface{}{"url": "Example NFT external url"},
					"name":        "user1 season #21",
					"socials": map[string]interface{}{
						"Discord": map[string]interface{}{"url": "discord.gg/"},
						"Twitter": map[string]interface{}{"url": "https://twitter.com/home"},
					},
					"squareImage": map[string]interface{}{
						"file":      map[string]interface{}{"url": "Example NFT square image"},
						"mediaType": "image",
					},
				},
				"description":         "user1 season #21",
				"itemTypes":           []interface{}{"A.179b6b1cb6755e31.ExampleNFT.NFT"},
				"name":                "user1 season #21",
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
							"User with one of these FLOATs are verified : 5335",
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
							"User with one of these FLOATs are verified : 5335",
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
							"User with one of these FLOATs are verified : 5335",
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
	floatID := otu.createFloatEvent("find")

	t.Run("Should get the running sale for user with the lowest price -> 2.2", func(t *testing.T) {

		otu.claimFloat("find", buyer, floatID)

		// buyer should have find name "user1" or float
		otu.O.Tx("devadminRegisterFindPackMetadataWithMultipleVerifier",
			WithSigner("find-admin"),
			WithArg("lease", "user1"),
			WithArg("typeId", packTypeId),
			WithArg("thumbnailHash", "thumbnailHash"),
			WithArg("wallet", "find-admin"),
			WithArg("openTime", 2.0),
			WithArg("royaltyCut", 0.15),
			WithArg("royaltyAddress", "find"),
			WithArg("requiresReservation", false),
			WithArg("startTime", map[string]float64{"whiteList": 1.0, "pre-sale": 2.0, "public sale": 3.0}),
			WithArg("endTime", map[string]float64{"whiteList": 2.0}),
			WithArg("floatEventId", map[string]uint64{"whiteList": floatID, "pre-sale": floatID}),
			WithArg("price", map[string]float64{"whiteList": 1.1, "pre-sale": 2.2, "public sale": 3.3}),
			WithArg("purchaseLimit", map[string]uint64{}),
			WithArg("checkAll", false),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "MetadataRegistered"), map[string]interface{}{
				"packTypeId": packTypeId,
			})

		otu.O.Script("getFindPackSaleDetailsWithUser",
			WithArg("packTypeName", "user1"),
			WithArg("packTypeId", packTypeId),
			WithArg("user", buyer),
		).
			AssertWant(t, autogold.Want("getFindPackSaleDetailsWithUser1", map[string]interface{}{
				"collectionDisplay": map[string]interface{}{
					"bannerImage": map[string]interface{}{"file": map[string]interface{}{"url": "Example NFT banner image"}, "mediaType": "image"},
					"description": "Example NFT FIND",
					"externalURL": map[string]interface{}{"url": "Example NFT external url"},
					"name":        "user1 season #22",
					"socials": map[string]interface{}{
						"Discord": map[string]interface{}{"url": "discord.gg/"},
						"Twitter": map[string]interface{}{"url": "https://twitter.com/home"},
					},
					"squareImage": map[string]interface{}{
						"file":      map[string]interface{}{"url": "Example NFT square image"},
						"mediaType": "image",
					},
				},
				"description":         "user1 season #22",
				"itemTypes":           []interface{}{"A.179b6b1cb6755e31.ExampleNFT.NFT"},
				"name":                "user1 season #22",
				"openTime":            2,
				"packFields":          map[string]interface{}{"Items": "1"},
				"packsLeft":           0,
				"requiresReservation": false,
				"saleInfos": []interface{}{
					map[string]interface{}{
						"name":      "pre-sale",
						"price":     2.2,
						"startTime": 2,
						"verifiers": []interface{}{
							"User with one of these FLOATs are verified : 5339",
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
					map[string]interface{}{
						"endTime":   2,
						"name":      "whiteList",
						"price":     1.1,
						"startTime": 1,
						"verifiers": []interface{}{
							"User with one of these FLOATs are verified : 5339",
							"Users with one of these find names are verified : user1",
						},
						"verifyAll": false,
					},
				},
				"storageRequirement": 10000,
				"thumbnailHash":      "thumbnailHash",
				"userQualifiedSale": map[string]interface{}{
					"canBuyNow":          true,
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
				"collectionDisplay": map[string]interface{}{
					"bannerImage": map[string]interface{}{"file": map[string]interface{}{"url": "Example NFT banner image"}, "mediaType": "image"},
					"description": "Example NFT FIND",
					"externalURL": map[string]interface{}{"url": "Example NFT external url"},
					"name":        "user1 season #22",
					"socials": map[string]interface{}{
						"Discord": map[string]interface{}{"url": "discord.gg/"},
						"Twitter": map[string]interface{}{"url": "https://twitter.com/home"},
					},
					"squareImage": map[string]interface{}{
						"file":      map[string]interface{}{"url": "Example NFT square image"},
						"mediaType": "image",
					},
				},
				"description":         "user1 season #22",
				"itemTypes":           []interface{}{"A.179b6b1cb6755e31.ExampleNFT.NFT"},
				"name":                "user1 season #22",
				"openTime":            2,
				"packFields":          map[string]interface{}{"Items": "1"},
				"packsLeft":           0,
				"requiresReservation": false,
				"saleInfos": []interface{}{
					map[string]interface{}{
						"name":      "pre-sale",
						"price":     2.2,
						"startTime": 2,
						"verifiers": []interface{}{
							"User with one of these FLOATs are verified : 5339",
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
					map[string]interface{}{
						"endTime":   2,
						"name":      "whiteList",
						"price":     1.1,
						"startTime": 1,
						"verifiers": []interface{}{
							"User with one of these FLOATs are verified : 5339",
							"Users with one of these find names are verified : user1",
						},
						"verifyAll": false,
					},
				},
				"storageRequirement": 10000,
				"thumbnailHash":      "thumbnailHash",
				"userQualifiedSale": map[string]interface{}{
					"canBuyNow":          true,
					"name":               "public sale",
					"price":              3.3,
					"startTime":          3,
					"userPurchaseRecord": 0,
				},
				"walletType": "A.0ae53cb6e3f42a79.FlowToken.Vault",
			}))

	})

	t.Run("Should get all pack sale under a lease name type", func(t *testing.T) {

		otu.O.Script("getAllFindPackSaleDetails",
			WithArg("packTypeName", "user1"),
		).
			AssertWithPointerWant(t, "/"+fmt.Sprint(packTypeId), autogold.Want("getAllFindPackSaleDetails", map[string]interface{}{
				"collectionDisplay": map[string]interface{}{
					"bannerImage": map[string]interface{}{"file": map[string]interface{}{"url": "Example NFT banner image"}, "mediaType": "image"},
					"description": "Example NFT FIND",
					"externalURL": map[string]interface{}{"url": "Example NFT external url"},
					"name":        "user1 season #22",
					"socials": map[string]interface{}{
						"Discord": map[string]interface{}{"url": "discord.gg/"},
						"Twitter": map[string]interface{}{"url": "https://twitter.com/home"},
					},
					"squareImage": map[string]interface{}{
						"file":      map[string]interface{}{"url": "Example NFT square image"},
						"mediaType": "image",
					},
				},
				"description":         "user1 season #22",
				"itemTypes":           []interface{}{"A.179b6b1cb6755e31.ExampleNFT.NFT"},
				"name":                "user1 season #22",
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
							"User with one of these FLOATs are verified : 5339",
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
					map[string]interface{}{
						"endTime":   2,
						"name":      "whiteList",
						"price":     1.1,
						"startTime": 1,
						"verifiers": []interface{}{
							"User with one of these FLOATs are verified : 5339",
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

	// Tests with 2 NFT Types
	doubleTypes := []string{exampleNFTType(otu), dandyNFTType(otu)}
	otu.mintThreeExampleDandies()
	otu.registerFtInRegistry()

	find := otu.O.Address("find-admin")
	otu.createUser(100.0, "find-admin")

	t.Run("Should be able to register pack data with 2 NFT Types", func(t *testing.T) {

		otu.registerPackType("user1", packTypeId, doubleTypes, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")
		packTypeId++
	})

	t.Run("Should be able to mint pack", func(t *testing.T) {

		example := otu.mintExampleNFTs()
		dandy := otu.mintThreeExampleDandies()[0]
		otu.sendDandy(find, "user1", dandy)

		otu.registerPackType("user1", packTypeId, doubleTypes, 0.0, 1.0, 1.0, false, 0, "find-admin", "find").
			mintPack("user1", packTypeId, []uint64{example, dandy}, doubleTypes, salt)
		packTypeId++

	})

	t.Run("Should be able to buy pack with 2 NFT Types", func(t *testing.T) {

		example := otu.mintExampleNFTs()
		dandy := otu.mintThreeExampleDandies()[0]
		otu.sendDandy(find, "user1", dandy)
		ids := []uint64{example, dandy}

		otu.registerPackType("user1", packTypeId, doubleTypes, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")
		otu.mintPack("user1", packTypeId, ids, doubleTypes, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		packTypeId++

	})

	t.Run("Should be able to buy pack and open pack with 2 NFT Types", func(t *testing.T) {

		example := otu.mintExampleNFTs()
		dandy := otu.mintThreeExampleDandies()[0]
		otu.sendDandy(find, "user1", dandy)
		ids := []uint64{example, dandy}

		otu.registerPackType("user1", packTypeId, doubleTypes, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")
		packId := otu.mintPack("user1", packTypeId, ids, doubleTypes, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)
		packTypeId++

	})

	t.Run("Should be able to buy and open with 2 NFT Types", func(t *testing.T) {

		example := otu.mintExampleNFTs()
		dandy := otu.mintThreeExampleDandies()[0]
		otu.sendDandy(find, "user1", dandy)
		ids := []uint64{example, dandy}

		otu.registerPackType("user1", packTypeId, doubleTypes, 0.0, 1.0, 1.0, false, 0, "find-admin", "find")
		packId := otu.mintPack("user1", packTypeId, ids, doubleTypes, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)

		otu.O.Tx("adminFulfillFindPack",
			WithSigner("find-admin"),
			WithArg("packId", packId),
			WithArg("typeIdentifiers", doubleTypes),
			WithArg("rewardIds", ids),
			WithArg("salt", salt),
		).
			AssertSuccess(t).
			AssertEvent(t, "Fulfilled", map[string]interface{}{
				"packId": packId,
			})

		packTypeId++
	})
}
