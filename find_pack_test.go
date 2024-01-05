package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
)

// There used to be lots more tests here, but since we are not actively using that part of packs anymore then i have commented them out.
func TestFindPack(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}
	packTypeId := uint64(1)
	buyer := "user1"

	ot.Run(t, "Should be able to buy pack", func(_ *testing.T) {
		otu.buyPack(buyer, packTypeName, packTypeId, 1, 4.20)
	})

	ot.Run(t, "Should be able to buy pack and open pack", func(t *testing.T) {
		otu.buyPack(buyer, packTypeName, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)
	})

	ot.Run(t, "Should be able to buy,  open and fulfill", func(t *testing.T) {
		otu.buyPack(buyer, packTypeName, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)
		otu.fulfillPack(packId, packRewardIds, packSalt)
	})

	ot.Run(t, "Should be able to buy,  open and fulfill with no collection setup", func(t *testing.T) {
		otu.buyPack("user3", packTypeName, packTypeId, 1, 4.20)
		otu.openPack("user3", packId)
		otu.fulfillPack(packId, packRewardIds, packSalt)
	})

	ot.Run(t, "Should get transferred to DLQ if try to open with wrong salt", func(t *testing.T) {
		otu.buyPack(buyer, buyer, packTypeId, 1, 4.20)
		otu.openPack(buyer, packId)

		otu.O.Tx("adminFulfillFindPack",
			WithSigner("find-admin"),
			WithArg("packId", packId),
			WithArg("typeIdentifiers", []string{dandyIdentifier}),
			WithArg("rewardIds", packRewardIds),
			WithArg("salt", "wrong salt"),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindPack", "FulfilledError"), map[string]interface{}{
				"packId":  packId,
				"address": otu.O.Address(buyer),
				"reason":  "The content of the pack was not verified with the hash provided at mint",
			})
	})

	ot.Run(t, "Should not be able to buy pack before drop is open", func(t *testing.T) {
		otu.registerPackType("user1", 2, []string{dandyIdentifier}, 0.0, 200.0, 200.0, false, 0, "find-admin", "find")
		otu.mintPack("user1", 2, packRewardIds, []string{dandyIdentifier}, packSalt)

		otu.O.Tx("buyFindPack",
			WithSigner(buyer),
			WithArg("packTypeName", buyer),
			WithArg("packTypeId", 2),
			WithArg("numberOfPacks", 1),
			WithArg("totalAmount", 4.2),
		).
			AssertFailure(t, "Cannot buy the pack now")
	})

	ot.Run(t, "Should not be able to open pack before drop is available", func(t *testing.T) {
		otu.registerPackType("user1", 2, []string{dandyIdentifier}, 0.0, 1.0, 200.0, false, 0, "find-admin", "find")
		newPackId := otu.mintPack("user1", 2, packRewardIds, []string{dandyIdentifier}, packSalt)
		otu.buyPack(buyer, buyer, 2, 1, 4.20)
		otu.O.Tx("openFindPack",
			WithSigner(buyer),
			WithArg("packId", newPackId),
		).
			AssertFailure(t, "You cannot open the pack yet")
	})

	//  Tests on Float implementation
	ot.Run(t, "Should be able to buy nft if the user has the float and with a whitelist.", func(t *testing.T) {
		floatID := otu.createFloatEvent("find")
		otu.claimFloat("find", buyer, floatID)
		otu.registerPackType("user1", 2, []string{dandyIdentifier}, 0.0, 1.0, 1.0, false, floatID, "find-admin", "find")
		otu.mintPack("user1", 2, packRewardIds, []string{dandyIdentifier}, packSalt)
		otu.buyPack(buyer, buyer, 2, 1, 4.20)
	})

	//TODO:Dont want to bother with storage fillup now...
	/*
		ot.Run(t, "Should get transferred to DLQ if storage full", func(t *testing.T) {
			otu.buyPack("user3", packTypeName, packTypeId, 1, 4.20)
			otu.openPack("user3", packId)

			otu.O.Tx("devFillUpStorage",
				WithSigner(buyer),
			).AssertSuccess(t)

			res := otu.O.FillUpStorage(buyer)
			require.NoError(t, res.Error)

			fmt.Println(otu.O.GetFreeCapacity(buyer))

			otu.O.Tx("adminFulfillFindPack",
				WithSigner("find-admin"),
				WithArg("packId", packId),
				WithArg("typeIdentifiers", []string{dandyIdentifier}),
				WithArg("rewardIds", packRewardIds),
				WithArg("salt", packSalt),
			).
				AssertSuccess(t).
				AssertEvent(t, otu.identifier("FindPack", "FulfilledError"), map[string]interface{}{
					"packId":  packId,
					"address": otu.O.Address(buyer),
					"reason":  "Not enough flow to hold the content of the pack. Please top up your account",
				})
		})
	*/
}
