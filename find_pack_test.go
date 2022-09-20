package test_main

import (
	"testing"
	// . "github.com/bjartek/overflow"
)

func TestFindPack(t *testing.T) {

	packTypeId := uint64(1)
	salt := "find"
	buyer := "user1"

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(100.0, "user1").
		registerUser("user1").
		buyForge("user1")

	t.Run("Should be able to mint Example NFTs", func(t *testing.T) {
		otu.mintExampleNFTs()
	})

	t.Run("Should be able to register pack data", func(t *testing.T) {

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")

	})

	t.Run("Should be able to mint pack", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account").
			mintPack("user1", packTypeId, []uint64{id1}, salt)

	})

	t.Run("Should be able to buy pack", func(t *testing.T) {

		id1 := otu.mintExampleNFTs()
		ids := []uint64{id1}

		otu.registerPackType("user1", packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")
		otu.mintPack("user1", packTypeId, ids, salt)

		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)

	})

	// t.Run("Should be able to buy and open", func(t *testing.T) {

	// 	id1 := otu.mintExampleNFTs()
	// 	ids := []uint64{id1}

	// 	otu.registerPackType("user1",packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")
	// 	packId := otu.mintPack("user1",packTypeId, ids, salt)

	// 	otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
	// 	otu.openPack(buyer, packId)
	// 	otu.fulfillPack(packId, ids, salt)
	// })

	// t.Run("Should get transferred to DLQ if try to open with wrong salt", func(t *testing.T) {

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(10.0, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	otu.registerPackType(packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")
	// 	packId := otu.mintPack(packTypeId, ids, salt)

	// 	otu.buyPack(buyer, packTypeId, 1, 4.20)
	// 	otu.openPack(buyer, packId)

	// 	otu.O.Tx("adminFulfillPack",
	// 		WithSigner("find"),
	// 		WithArg("packId", packId),
	// 		WithArg("rewardIds", ids),
	// 		WithArg("salt", "wrong salt"),
	// 	).
	// 		AssertSuccess(t).
	// 		AssertEvent(t, "A.f8d6e0586b0a20c7.FlomiesPack.FulfilledError", map[string]interface{}{
	// 			"packId":  packId,
	// 			"address": otu.O.Address(buyer),
	// 			"reason":  "The content of the pack was not verified with the hash provided at mint",
	// 		})

	// })

	// t.Run("Should not be able to buy pack before drop is open", func(t *testing.T) {

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(010.0, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	otu.registerPackType(packTypeId, 0.0, 15.0, 15.0, false, 0, "find", "account")
	// 	otu.mintPack(packTypeId, ids, salt)

	// 	otu.O.Tx("buyPack",
	// 		WithSigner(buyer),
	// 		WithArg("packTypeId", packTypeId),
	// 		WithArg("numberOfPacks", 1),
	// 		WithArg("totalAmount", 4.2),
	// 	).
	// 		AssertFailure(t, "You cannot buy the pack yet")

	// })

	// t.Run("Should not be able to open the pack before it is available", func(t *testing.T) {

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(10.0, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	otu.registerPackType(packTypeId, 0.0, 1.0, 15.0, false, 0, "find", "account")
	// 	packId := otu.mintPack(packTypeId, ids, salt)
	// 	otu.buyPack(buyer, packTypeId, 1, 4.20)

	// 	otu.O.Tx("openPack",
	// 		WithSigner(buyer),
	// 		WithArg("packId", packId),
	// 	).
	// 		AssertFailure(t, "You cannot open the pack yet")

	// })

	// t.Run("Should get transferred to DLQ if try to open with wrong salt", func(t *testing.T) {

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(10.0, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	otu.registerPackType(packTypeId, 0.0, 1.0, 1.0, false, 0, "find", "account")
	// 	packId := otu.mintPack(packTypeId, ids, salt)

	// 	otu.buyPack(buyer, packTypeId, 1, 4.20)
	// 	otu.openPack(buyer, packId)

	// 	otu.O.Tx("adminFulfillPack",
	// 		WithSigner("find"),
	// 		WithArg("packId", packId),
	// 		WithArg("rewardIds", ids),
	// 		WithArg("salt", "wrong salt"),
	// 	).
	// 		AssertSuccess(t).
	// 		AssertEvent(t, "A.f8d6e0586b0a20c7.FlomiesPack.FulfilledError", map[string]interface{}{
	// 			"packId":  packId,
	// 			"address": otu.O.Address(buyer),
	// 			"reason":  "The content of the pack was not verified with the hash provided at mint",
	// 		})

	// })

	// t.Run("Should get transferred to DLQ if storage full", func(t *testing.T) {

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(4.20, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	otu.O.Tx("adminRegisterPackMetadata",
	// 		WithSigner("find"),
	// 		WithArg("typeId", packTypeId),
	// 		WithArg("thumbnailHash", "thumbnailHash"),
	// 		WithArg("wallet", "find"),
	// 		WithArg("openTime", 1.0),
	// 		WithArg("royaltyCut", 0.15),
	// 		WithArg("royaltyAddress", "account"),
	// 		WithArg("startTime", createIntUFix64(map[int]float64{1: 1.0})),
	// 		WithArg("endTime", createIntUFix64(map[int]float64{})),
	// 		WithArg("floatEventId", createIntUInt64(map[int]uint64{})),
	// 		WithArg("price", createIntUFix64(map[int]float64{1: 4.2})),
	// 		WithArg("purchaseLimit", createIntUInt64(map[int]uint64{})),
	// 	).
	// 		AssertSuccess(t).
	// 		AssertEvent(t, "A.f8d6e0586b0a20c7.FlomiesPack.MetadataRegistered", map[string]interface{}{
	// 			"typeId": packTypeId,
	// 		})

	// 	packId := otu.mintPack(packTypeId, ids, salt)

	// 	otu.buyPack(buyer, packTypeId, 1, 4.20)
	// 	otu.openPack(buyer, packId)

	// 	otu.withdrawAllBalance(buyer)
	// 	otu.FillUpStorage(buyer)

	// 	// if otu.O.Error != nil {
	// 	// 	panic(otu.O.Error)
	// 	// }

	// 	otu.O.Tx("adminFulfillPack",
	// 		WithSigner("find"),
	// 		WithArg("packId", packId),
	// 		WithArg("rewardIds", ids),
	// 		WithArg("salt", salt),
	// 	).
	// 		AssertSuccess(t).
	// 		AssertEvent(t, "A.f8d6e0586b0a20c7.FlomiesPack.FulfilledError", map[string]interface{}{
	// 			"packId":  packId,
	// 			"address": otu.O.Address(buyer),
	// 			"reason":  "Not enough flow to hold the content of the pack. Please top up your account"})

	// })

	// /* Tests on Float implementation */
	// t.Run("Should be able to buy nft if the user has the float and with a whitelist.", func(t *testing.T) {

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(4.20, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	floatID := otu.createFloatEvent("account")

	// 	otu.claimFloat("account", buyer, floatID)

	// 	otu.registerPackType(packTypeId, 1.0, 10.0, 15.0, false, floatID, "find", "account")
	// 	otu.mintPack(packTypeId, ids, salt)

	// 	otu.buyPack(buyer, packTypeId, 1, 4.20)

	// })

	// t.Run("Should be able to buy with the float (no whitelist).", func(t *testing.T) {

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(4.20, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	floatID := otu.createFloatEvent("account")

	// 	otu.claimFloat("account", buyer, floatID)
	// 	// in the test, 0.0 whitelist time -> no whitelist
	// 	otu.registerPackType(packTypeId, 0.0, 10.0, 15.0, false, floatID, "find", "account")
	// 	otu.mintPack(packTypeId, ids, salt)
	// 	otu.tickClock(10.0)
	// 	otu.buyPack(buyer, packTypeId, 1, 4.20)

	// })

	// t.Run("Should not be able to buy nft if the user doesnt have the float during the whitelist period, but can buy in public sale.", func(t *testing.T) {

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(4.20, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	floatID := otu.createFloatEvent("account")

	// 	// in the test, 0.0 whitelist time -> no whitelist
	// 	otu.registerPackType(packTypeId, 1.0, 10.0, 15.0, false, floatID, "find", "account")
	// 	otu.mintPack(packTypeId, ids, salt)

	// 	otu.O.Tx("buyPack",
	// 		WithSigner(buyer),
	// 		WithArg("packTypeId", packTypeId),
	// 		WithArg("numberOfPacks", 1),
	// 		WithArg("totalAmount", 4.2),
	// 	).
	// 		AssertFailure(t, "You cannot buy the pack yet")

	// 	otu.tickClock(10.0)

	// 	otu.O.Tx("buyPack",
	// 		WithSigner(buyer),
	// 		WithArg("packTypeId", packTypeId),
	// 		WithArg("numberOfPacks", 1),
	// 		WithArg("totalAmount", 4.2),
	// 	).
	// 		AssertSuccess(t)

	// })

	// t.Run("Should not be able to buy nft if the user doesnt have the float", func(t *testing.T) {

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(4.20, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	floatID := otu.createFloatEvent("account")

	// 	// in the test, 0.0 whitelist time -> no whitelist
	// 	otu.O.Tx("adminRegisterPackMetadata",
	// 		WithSigner("find"),
	// 		WithArg("typeId", packTypeId),
	// 		WithArg("thumbnailHash", "thumbnailHash"),
	// 		WithArg("wallet", "find"),
	// 		WithArg("openTime", 1.0),
	// 		WithArg("royaltyCut", 0.15),
	// 		WithArg("royaltyAddress", "account"),
	// 		WithArg("startTime", createIntUFix64(map[int]float64{1: 1.0})),
	// 		WithArg("endTime", createIntUFix64(map[int]float64{})),
	// 		WithArg("floatEventId", createIntUInt64(map[int]uint64{1: floatID})),
	// 		WithArg("price", createIntUFix64(map[int]float64{1: 4.2})),
	// 		WithArg("purchaseLimit", createIntUInt64(map[int]uint64{})),
	// 	).
	// 		AssertSuccess(t).
	// 		AssertEvent(t, "A.f8d6e0586b0a20c7.FlomiesPack.MetadataRegistered", map[string]interface{}{
	// 			"typeId": packTypeId,
	// 		})

	// 	otu.mintPack(packTypeId, ids, salt)
	// 	otu.tickClock(10.0)

	// 	otu.O.Tx("buyPack",
	// 		WithSigner(buyer),
	// 		WithArg("packTypeId", packTypeId),
	// 		WithArg("numberOfPacks", 1),
	// 		WithArg("totalAmount", 4.2),
	// 	).
	// 		AssertFailure(t, "You cannot buy the pack yet unless you own the required float with eventId "+fmt.Sprint(floatID))

	// })

	// t.Run("Should be able to buy nft for free with free-mint Float", func(t *testing.T) {

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(4.20, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	freeMintFloat := otu.createFloatEvent("account")
	// 	whiteListFloat := otu.createFloatEvent("account")

	// 	otu.claimFloat("account", buyer, freeMintFloat)
	// 	otu.claimFloat("account", buyer, whiteListFloat)

	// 	// in the test, 0.0 whitelist time -> no whitelist
	// 	otu.O.Tx("adminRegisterPackMetadata",
	// 		WithSigner("find"),
	// 		WithArg("typeId", packTypeId),
	// 		WithArg("thumbnailHash", "thumbnailHash"),
	// 		WithArg("wallet", "find"),
	// 		WithArg("openTime", 1.0),
	// 		WithArg("royaltyCut", 0.15),
	// 		WithArg("royaltyAddress", "account"),
	// 		WithArg("startTime", createIntUFix64(map[int]float64{1: 0.0, 2: 10.0, 3: 20.0})),
	// 		WithArg("endTime", createIntUFix64(map[int]float64{1: 10.0, 2: 20.0})),
	// 		WithArg("floatEventId", createIntUInt64(map[int]uint64{1: freeMintFloat, 2: whiteListFloat})),
	// 		WithArg("price", createIntUFix64(map[int]float64{1: 0.0, 2: 4.2, 3: 4.2})),
	// 		WithArg("purchaseLimit", createIntUInt64(map[int]uint64{1: 1, 2: 20})),
	// 	).
	// 		AssertSuccess(t).
	// 		AssertEvent(t, "A.f8d6e0586b0a20c7.FlomiesPack.MetadataRegistered", map[string]interface{}{
	// 			"typeId": packTypeId,
	// 		})

	// 	otu.mintPack(packTypeId, ids, salt)

	// 	otu.O.Tx("buyPack",
	// 		WithSigner(buyer),
	// 		WithArg("packTypeId", packTypeId),
	// 		WithArg("numberOfPacks", 1),
	// 		WithArg("totalAmount", 0.0),
	// 	).
	// 		AssertSuccess(t)

	// })

	// t.Run("Should not be able to buy nft for free with free-mint Float more than allowed", func(t *testing.T) {

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(4.20, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	freeMintFloat := otu.createFloatEvent("account")
	// 	whiteListFloat := otu.createFloatEvent("account")

	// 	otu.claimFloat("account", buyer, freeMintFloat)
	// 	otu.claimFloat("account", buyer, whiteListFloat)

	// 	// in the test, 0.0 whitelist time -> no whitelist
	// 	otu.O.Tx("adminRegisterPackMetadata",
	// 		WithSigner("find"),
	// 		WithArg("typeId", packTypeId),
	// 		WithArg("thumbnailHash", "thumbnailHash"),
	// 		WithArg("wallet", "find"),
	// 		WithArg("openTime", 1.0),
	// 		WithArg("royaltyCut", 0.15),
	// 		WithArg("royaltyAddress", "account"),
	// 		WithArg("startTime", createIntUFix64(map[int]float64{1: 0.0, 2: 10.0, 3: 20.0})),
	// 		WithArg("endTime", createIntUFix64(map[int]float64{1: 10.0, 2: 20.0})),
	// 		WithArg("floatEventId", createIntUInt64(map[int]uint64{1: freeMintFloat, 2: whiteListFloat})),
	// 		WithArg("price", createIntUFix64(map[int]float64{1: 0.0, 2: 4.2, 3: 4.2})),
	// 		WithArg("purchaseLimit", createIntUInt64(map[int]uint64{1: 0, 2: 20})),
	// 	).
	// 		AssertSuccess(t).
	// 		AssertEvent(t, "A.f8d6e0586b0a20c7.FlomiesPack.MetadataRegistered", map[string]interface{}{
	// 			"typeId": packTypeId,
	// 		})

	// 	otu.mintPack(packTypeId, ids, salt)

	// 	otu.O.Tx("buyPack",
	// 		WithSigner(buyer),
	// 		WithArg("packTypeId", packTypeId),
	// 		WithArg("numberOfPacks", 1),
	// 		WithArg("totalAmount", 0.0),
	// 	).
	// 		AssertFailure(t, "You are only allowed to purchase 0")

	// })

	// /* Tests on Royalty implementation */
	// t.Run("Should have 0.15 cut to find with a whitelist.", func(t *testing.T) {

	// 	var numberOfPacks uint64 = 1
	// 	totalAmount := 4.2

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(4.20, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	floatID := otu.createFloatEvent("account")

	// 	otu.claimFloat("account", buyer, floatID)

	// 	otu.registerPackType(packTypeId, 1.0, 10.0, 15.0, false, floatID, "find", "account")
	// 	otu.mintPack(packTypeId, ids, salt)

	// 	otu.O.Tx("buyPack",
	// 		WithSigner(buyer),
	// 		WithArg("packTypeId", packTypeId),
	// 		WithArg("numberOfPacks", numberOfPacks),
	// 		WithArg("totalAmount", totalAmount),
	// 	).
	// 		AssertSuccess(t).
	// 		AssertEvent(t, "A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
	// 			"amount": totalAmount * 0.15,
	// 			"to":     otu.O.Address("account"),
	// 		}).
	// 		AssertEvent(t, "A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
	// 			"amount": totalAmount * 0.15,
	// 			"to":     otu.O.Address("account"),
	// 		})

	// })

	// t.Run("Should have 0.15 cut to find (no whitelist).", func(t *testing.T) {
	// 	var numberOfPacks uint64 = 1
	// 	totalAmount := 4.2

	// 	otu := NewOverflowTest(t).
	// 		setupFIND().
	// 		createUser(100.0, "account").
	// 		createUser(4.20, buyer)

	// 	id1 := otu.mintflomies()
	// 	ids := []uint64{id1}

	// 	floatID := otu.createFloatEvent("account")

	// 	otu.claimFloat("account", buyer, floatID)
	// 	// in the test, 0.0 whitelist time -> no whitelist
	// 	otu.registerPackType(packTypeId, 0.0, 10.0, 15.0, false, floatID, "find", "account")
	// 	otu.mintPack(packTypeId, ids, salt)
	// 	otu.tickClock(10.0)

	// 	otu.O.Tx("buyPack",
	// 		WithSigner(buyer),
	// 		WithArg("packTypeId", packTypeId),
	// 		WithArg("numberOfPacks", numberOfPacks),
	// 		WithArg("totalAmount", totalAmount),
	// 	).
	// 		AssertSuccess(t).
	// 		AssertEvent(t, "A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
	// 			"amount": totalAmount * 0.15,
	// 			"to":     otu.O.Address("account"),
	// 		}).
	// 		AssertEvent(t, "A.0ae53cb6e3f42a79.FlowToken.TokensDeposited", map[string]interface{}{
	// 			"amount": totalAmount * 0.15,
	// 			"to":     otu.O.Address("account"),
	// 		})

	// })
}
