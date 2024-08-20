package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow/v2"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestFindVerifier(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}
	user := "user1"

	// Has One FLOAT
	ot.Run(t, "Should return false if user have no float", func(t *testing.T) {
		floatID := otu.createFloatEvent("find")

		otu.O.Script("devFindVerifierHasOneFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{floatID, 0}),
		).
			AssertWant(t, autogold.Want("Has no float, false", map[string]interface{}{
				"description": fmt.Sprintf("User with one of these FLOATs are verified : %d, %d", floatID, 0),
				"result":      false,
			}))
	})

	ot.Run(t, "Should panic if no float is specified", func(t *testing.T) {
		_, err := otu.O.Script("devFindVerifierHasOneFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{}),
		).
			GetAsInterface()

		assert.Error(t, err)
	})

	ot.Run(t, "Should return true if user has one of the float", func(t *testing.T) {
		floatID := otu.createFloatEvent("find")

		otu.claimFloat("find", user, floatID)

		otu.O.Script("devFindVerifierHasOneFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{floatID, 0}),
		).
			AssertWant(t, autogold.Want("Has one float, true", map[string]interface{}{
				"description": fmt.Sprintf("User with one of these FLOATs are verified : %d, %d", floatID, 0),
				"result":      true,
			}))
	})

	ot.Run(t, "Should return false if user doesn't have float contained", func(t *testing.T) {
		claimedFloatID := otu.createFloatEvent("find")
		notClaimedFloatID := otu.createFloatEvent("find")

		otu.claimFloat("find", user, claimedFloatID)

		otu.O.Script("devFindVerifierHasOneFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{notClaimedFloatID, 0}),
		).
			AssertWant(t, autogold.Want("Has one float, false", map[string]interface{}{
				"description": fmt.Sprintf("User with one of these FLOATs are verified : %d, %d", notClaimedFloatID, 0),
				"result":      false,
			}))
	})

	// Has All FLOAT
	ot.Run(t, "Should return true if user has all of the float", func(t *testing.T) {
		floatID := otu.createFloatEvent("find")
		floatID2 := otu.createFloatEvent("find")

		otu.claimFloat("find", user, floatID)
		otu.claimFloat("find", user, floatID2)

		otu.O.Script("devFindVerifierHasAllFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{floatID, floatID2}),
		).
			AssertWant(t, autogold.Want("Has all float, true", map[string]interface{}{
				"description": fmt.Sprintf("User with all of these FLOATs are verified : %d, %d", floatID, floatID2),
				"result":      true,
			}))
	})

	ot.Run(t, "Should return false if user doesn't have all float contained", func(t *testing.T) {
		floatID := otu.createFloatEvent("find")
		floatID2 := otu.createFloatEvent("find")

		otu.claimFloat("find", user, floatID)
		otu.claimFloat("find", user, floatID2)

		otu.O.Script("devFindVerifierHasAllFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{floatID, floatID2, 0}),
		).
			AssertWant(t, autogold.Want("Has all float, false", map[string]interface{}{
				"description": fmt.Sprintf("User with all of these FLOATs are verified : %d, %d, %d", floatID, floatID2, 0),
				"result":      false,
			}))
	})

	ot.Run(t, "Should panic if no float is specified", func(t *testing.T) {
		_, err := otu.O.Script("devFindVerifierHasAllFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{}),
		).
			GetAsInterface()

		assert.Error(t, err)
	})

	// WhiteLabel
	ot.Run(t, "Should return true if user is in whiteLabel", func(t *testing.T) {
		otu.O.Script("devFindVerifierIsInWhiteList",
			WithArg("user", otu.O.Address(user)),
			WithAddresses("addresses", user, "user2", "user3"),
		).
			AssertWant(t, autogold.Want("whitelabel, true", map[string]interface{}{
				"description": fmt.Sprintf("Only these wallet addresses are verified : %s, %s, %s", otu.O.Address(user), otu.O.Address("user2"), otu.O.Address("user3")),
				"result":      true,
			}))
	})

	ot.Run(t, "Should return true if user is not in whiteLabel", func(t *testing.T) {
		otu.O.Script("devFindVerifierIsInWhiteList",
			WithArg("user", otu.O.Address(user)),
			WithAddresses("addresses", "user2", "user3"),
		).
			AssertWant(t, autogold.Want("whitelabel, false", map[string]interface{}{
				"description": fmt.Sprintf("Only these wallet addresses are verified : %s, %s", otu.O.Address("user2"), otu.O.Address("user3")),
				"result":      false,
			}))
	})

	ot.Run(t, "Should panic if no one is not in whiteLabel", func(t *testing.T) {
		_, err := otu.O.Script("devFindVerifierIsInWhiteList",
			WithArg("user", otu.O.Address(user)),
			WithArg("addresses", "[]"),
		).
			GetAsInterface()

		assert.Error(t, err)
	})

	// Has Find Name
	ot.Run(t, "Should return true if user has the find name", func(t *testing.T) {
		otu.O.Script("devFindVerifierHasFindName",
			WithArg("user", otu.O.Address(user)),
			WithArg("findNames", []string{"user1", "user2"}),
		).
			AssertWant(t, autogold.Want("HasFindName, true", map[string]interface{}{
				"description": "Users with one of these find names are verified : user1, user2",
				"result":      true,
			}))
	})

	ot.Run(t, "Should return false if user does not have the find name", func(t *testing.T) {
		otu.O.Script("devFindVerifierHasFindName",
			WithArg("user", otu.O.Address(user)),
			WithArg("findNames", []string{"user2", "user3"}),
		).
			AssertWant(t, autogold.Want("HasFindName, false", map[string]interface{}{
				"description": "Users with one of these find names are verified : user2, user3",
				"result":      false,
			}))
	})

	ot.Run(t, "Should panic if no find name is specified", func(t *testing.T) {
		_, err := otu.O.Script("devFindVerifierHasFindName",
			WithArg("user", otu.O.Address(user)),
			WithArg("findNames", "[]"),
		).
			GetAsInterface()

		assert.Error(t, err)
	})

	ot.Run(t, "Should return false if user has no lease collection", func(t *testing.T) {
		otu.O.Script("devFindVerifierHasFindName",
			WithArg("user", otu.O.Address("user3")),
			WithArg("findNames", []string{"user3"}),
		).
			AssertWant(t, autogold.Want("HasFindName user no lease collection, false", map[string]interface{}{
				"description": "Users with one of these find names are verified : user3",
				"result":      false,
			}))
	})

	// Has No. of NFTs in Path

	ot.Run(t, "Should return true if user has no of NFTs equal to threshold", func(t *testing.T) {
		otu.O.Script("devFindVerifierHasNFTsInPath",
			WithArg("user", otu.O.Address("user1")),
			WithArg("path", "findDandy"),
			WithArg("threshold", 2),
		).
			AssertWant(t, autogold.Want("Has no. of NFT equal to threshold, true", map[string]interface{}{
				"description": "Users with at least 2 nos. of NFT in path /public/findDandy are verified",
				"result":      true,
			}))
	})

	ot.Run(t, "Should return true if user has no of NFTs more than threshold", func(t *testing.T) {
		otu.O.Script("devFindVerifierHasNFTsInPath",
			WithArg("user", otu.O.Address("user1")),
			WithArg("path", "exampleNFTCollection"),
			WithArg("threshold", 1),
		).
			AssertWant(t, autogold.Want("Has no. of NFT more than threshold, true", map[string]interface{}{
				"description": "Users with at least 1 nos. of NFT in path /public/exampleNFTCollection are verified",
				"result":      true,
			}))
	})

	ot.Run(t, "Should return false if user has no of NFTs less than threshold", func(t *testing.T) {
		otu.O.Script("devFindVerifierHasNFTsInPath",
			WithArg("user", otu.O.Address("user1")),
			WithArg("path", "exampleNFTCollection"),
			WithArg("threshold", 100),
		).
			AssertWant(t, autogold.Want("Has no. of NFT less than threshold, false", map[string]interface{}{
				"description": "Users with at least 100 nos. of NFT in path /public/exampleNFTCollection are verified",
				"result":      false,
			}))
	})

	ot.Run(t, "Should panic if 0 threshold is specified", func(t *testing.T) {
		_, err := otu.O.Script("devFindVerifierHasNFTsInPath",
			WithArg("user", otu.O.Address("user1")),
			WithArg("path", "exampleNFTCollection"),
			WithArg("threshold", 0),
		).
			GetAsInterface()

		assert.Error(t, err)
	})

	ot.Run(t, "Should return false if user has no collection", func(t *testing.T) {
		otu.O.Script("devFindVerifierHasNFTsInPath",
			WithArg("user", otu.O.Address("user3")),
			WithArg("path", "exampleNFTCollection"),
			WithArg("threshold", 3),
		).
			AssertWant(t, autogold.Want("Has no collection, false", map[string]interface{}{
				"description": "Users with at least 3 nos. of NFT in path /public/exampleNFTCollection are verified",
				"result":      false,
			}))
	})

	ot.Run(t, "Should return true if user has nft with specified rarity", func(t *testing.T) {
		otu.O.Script("devFindVerifierHasNFTsWithRarity",
			WithArg("user", otu.O.Address("user1")),
			WithArg("path", "exampleNFTCollection"),
			WithArg("rarityA", true),
			WithArg("rarityB", true),
		).
			AssertWant(t, autogold.Want("has nft with specified rarity, true", map[string]interface{}{
				"description": "Users with at least 1 NFT in path /public/exampleNFTCollection with one of these rarities are verified : description : rarity description, score : 1.00000000, max score : 2.00000000; description : fake rarity, score : 1.00000000, max score : 2.00000000; ",
				"result":      true,
			}))
	})

	ot.Run(t, "Should return false if user does not have nft with specified rarity", func(t *testing.T) {
		otu.O.Script("devFindVerifierHasNFTsWithRarity",
			WithArg("user", otu.O.Address("user1")),
			WithArg("path", "exampleNFTCollection"),
			WithArg("rarityA", false),
			WithArg("rarityB", true),
		).
			AssertWant(t, autogold.Want("does not have nft with specified rarity, false", map[string]interface{}{
				"description": "Users with at least 1 NFT in path /public/exampleNFTCollection with one of these rarities are verified : description : fake rarity, score : 1.00000000, max score : 2.00000000; ",
				"result":      false,
			}))
	})

	ot.Run(t, "Should panic if no rarity is specified", func(t *testing.T) {
		_, err := otu.O.Script("devFindVerifierHasNFTsWithRarity",
			WithArg("user", otu.O.Address("user1")),
			WithArg("path", "exampleNFTCollection"),
			WithArg("rarityA", false),
			WithArg("rarityB", false),
		).
			GetAsInterface()

		assert.Error(t, err)
	})

	ot.Run(t, "Should return false if user has no collection specified for rarity", func(t *testing.T) {
		otu.O.Script("devFindVerifierHasNFTsWithRarity",
			WithArg("user", otu.O.Address("user3")),
			WithArg("path", "exampleNFTCollection"),
			WithArg("rarityA", true),
			WithArg("rarityB", false),
		).
			AssertWant(t, autogold.Want("user has no collection, false", map[string]interface{}{
				"description": "Users with at least 1 NFT in path /public/exampleNFTCollection with one of these rarities are verified : description : rarity description, score : 1.00000000, max score : 2.00000000; ",
				"result":      false,
			}))
	})
}
