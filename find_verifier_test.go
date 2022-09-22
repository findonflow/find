package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestFindVerifier(t *testing.T) {

	user := "user1"

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(10000.0, "user1").
		registerUser("user1")

	// Has One FLOAT
	t.Run("Should return false if user have no float", func(t *testing.T) {

		floatID := otu.createFloatEvent("account")

		otu.O.Script("testFindVerifierHasOneFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{floatID, 0}),
		).
			AssertWant(t, autogold.Want("Has no float, false", false))
	})

	t.Run("Should return true if no float is specified", func(t *testing.T) {

		otu.O.Script("testFindVerifierHasOneFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{}),
		).
			AssertWant(t, autogold.Want("Has no float, true", true))
	})

	t.Run("Should return true if user has one of the float", func(t *testing.T) {

		floatID := otu.createFloatEvent("account")

		otu.claimFloat("account", user, floatID)

		otu.O.Script("testFindVerifierHasOneFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{floatID, 0}),
		).
			AssertWant(t, autogold.Want("Has one float, true", true))
	})

	t.Run("Should return false if user doesn't have float contained", func(t *testing.T) {

		claimedFloatID := otu.createFloatEvent("account")
		notClaimedFloatID := otu.createFloatEvent("account")

		otu.claimFloat("account", user, claimedFloatID)

		otu.O.Script("testFindVerifierHasOneFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{notClaimedFloatID, 0}),
		).
			AssertWant(t, autogold.Want("Has one float, false", false))
	})

	// Has All FLOAT
	t.Run("Should return true if user has all of the float", func(t *testing.T) {

		floatID := otu.createFloatEvent("account")
		floatID2 := otu.createFloatEvent("account")

		otu.claimFloat("account", user, floatID)
		otu.claimFloat("account", user, floatID2)

		otu.O.Script("testFindVerifierHasAllFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{floatID, floatID2}),
		).
			AssertWant(t, autogold.Want("Has all float, true", true))
	})

	t.Run("Should return false if user doesn't have all float contained", func(t *testing.T) {

		floatID := otu.createFloatEvent("account")
		floatID2 := otu.createFloatEvent("account")

		otu.claimFloat("account", user, floatID)
		otu.claimFloat("account", user, floatID2)

		otu.O.Script("testFindVerifierHasAllFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{floatID, floatID2, 0}),
		).
			AssertWant(t, autogold.Want("Has all float, false", false))
	})

	t.Run("Should return true if no float is specified", func(t *testing.T) {

		otu.O.Script("testFindVerifierHasAllFLOAT",
			WithArg("user", otu.O.Address(user)),
			WithArg("floatIDs", []uint64{}),
		).
			AssertWant(t, autogold.Want("specified no float, true", true))
	})

	// WhiteLabel
	t.Run("Should return true user is in whiteLabel", func(t *testing.T) {

		otu.O.Script("testFindVerifierHasWhiteLabel",
			WithArg("user", otu.O.Address(user)),
			WithAddresses("addresses", user, "user2", "user3"),
		).
			AssertWant(t, autogold.Want("whitelabel, true", true))
	})

	t.Run("Should return true if user is not in whiteLabel", func(t *testing.T) {

		otu.O.Script("testFindVerifierHasWhiteLabel",
			WithArg("user", otu.O.Address(user)),
			WithAddresses("addresses", "user2", "user3"),
		).
			AssertWant(t, autogold.Want("whitelabel, false", false))
	})

	t.Run("Should return false if no one is not in whiteLabel", func(t *testing.T) {

		otu.O.Script("testFindVerifierHasWhiteLabel",
			WithArg("user", otu.O.Address(user)),
			WithArg("addresses", "[]"),
		).
			AssertWant(t, autogold.Want("no one in whitelabel, false", false))
	})

	// Has Find Name
	t.Run("Should return true if user has the find name", func(t *testing.T) {

		otu.O.Script("testFindVerifierHasFindName",
			WithArg("user", otu.O.Address(user)),
			WithArg("findNames", []string{"user1", "user2"}),
		).
			AssertWant(t, autogold.Want("HasFindName, true", true))
	})

	t.Run("Should return false if user does not have the find name", func(t *testing.T) {

		otu.O.Script("testFindVerifierHasFindName",
			WithArg("user", otu.O.Address(user)),
			WithArg("findNames", []string{"user2", "user3"}),
		).
			AssertWant(t, autogold.Want("HasFindName, false", false))
	})

	t.Run("Should return true if no find name is specified", func(t *testing.T) {

		otu.O.Script("testFindVerifierHasFindName",
			WithArg("user", otu.O.Address(user)),
			WithArg("findNames", "[]"),
		).
			AssertWant(t, autogold.Want("HasFindName specified no find names, true", true))
	})

	t.Run("Should return false if user has no lease collection", func(t *testing.T) {

		otu.O.Script("testFindVerifierHasFindName",
			WithArg("user", otu.O.Address("user2")),
			WithArg("findNames", []string{"user2", "user3"}),
		).
			AssertWant(t, autogold.Want("HasFindName user no lease collection, false", false))
	})
}
