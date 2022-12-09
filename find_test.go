package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestFIND(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(100.0, "user1").
		registerUser("user1")

	t.Run("Should be able to register a name", func(t *testing.T) {

		// Can fix this with pointerWant
		otu.O.Script("getLeases").AssertWant(t,
			autogold.Want("allLeases", `[]interface {}{
  map[string]interface {}{
    "address": "0x179b6b1cb6755e31",
    "lockedUntil": 39312001.0,
    "name": "user1",
    "profile": "Capability<&AnyResource{A.f8d6e0586b0a20c7.Profile.Public}>(address: 0x179b6b1cb6755e31, path: /public/findProfile)",
    "registeredTime": 1.0,
    "validUntil": 31536001.0,
  },
}`),
		)
	})

	t.Run("Should get error if you try to register a name and dont have enough money", func(t *testing.T) {
		otu.O.Tx("register",
			WithSigner("user1"),
			WithArg("name", "usr"),
			WithArg("amount", 500.0),
		).AssertFailure(t, "Amount withdrawn must be less than or equal than the balance of the Vault")

	})

	t.Run("Should get error if you try to register a name that is too short", func(t *testing.T) {

		otu.O.Tx("register",
			WithSigner("user1"),
			WithArg("name", "ur"),
			WithArg("amount", 5.0),
		).AssertFailure(t, "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
	})

	t.Run("Should get error if you try to register a name that is already claimed", func(t *testing.T) {
		otu.O.Tx("register",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("amount", 5.0),
		).AssertFailure(t, "Name already registered")

	})

	t.Run("Should allow registering a lease after it is freed", func(t *testing.T) {

		otu.expireLease().tickClock(2.0)

		otu.O.Tx(`
			import FIND from "../contracts/FIND.cdc"

			transaction(name: String) {

			    prepare(account: AuthAccount) {
			        let status=FIND.status(name)
							if status.status == FIND.LeaseStatus.LOCKED {
								panic("locked")
							}
							if status.status == FIND.LeaseStatus.FREE {
								panic("free")
							}
			    }
			}
			`,
			WithSigner("user1"),
			WithArg("name", "user1"),
		).AssertFailure(t, "locked").
			AssertComputationLessThenOrEqual(t, 1000)

		otu.expireLease()
		otu.registerUser("user1")
	})

	t.Run("Should be able to lookup address", func(t *testing.T) {

		otu.assertLookupAddress("user1", "0x179b6b1cb6755e31")
	})

	t.Run("Should not be able to lookup lease after expired", func(t *testing.T) {

		otu.expireLease().
			tickClock(2.0)

		otu.O.Script("getNameStatus",
			WithArg("name", "user1"),
		).
			AssertWant(t, autogold.Want("getNameStatus n", nil))

	})

	t.Run("Admin should be able to register without paying FUSD", func(t *testing.T) {

		otu.createUser(10.0, "find")

		otu.O.Tx("adminRegisterName",
			WithSigner("find"),
			WithArg("names", `["find-admin"]`),
			WithArg("user", "find"),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FIND.Register", map[string]interface{}{
				"name": "find-admin",
			})

	})

	otu.renewUserWithName("user1", "user1").
		createUser(100.0, "user2").
		registerUser("user2")

	t.Run("Should be able to send lease to another name", func(t *testing.T) {

		otu.O.Tx("moveNameTO",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("receiver", "user2"),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FIND.Moved", map[string]interface{}{
				"name": "user1",
			})

	})

	t.Run("Should automatically set Find name to empty if sender have none", func(t *testing.T) {

		otu.O.Script("getName",
			WithArg("address", "user1"),
		).
			AssertWant(t, autogold.Want("getName empty", nil))

		otu.moveNameTo("user2", "user1", "user1")

	})

	t.Run("Should automatically set Find Name if sender have one", func(t *testing.T) {

		otu.registerUserWithName("user1", "name1").
			moveNameTo("user1", "user2", "user1")

		otu.O.Script("getName",
			WithArg("address", "user1"),
		).
			AssertWant(t, autogold.Want("getName empty", "name1"))

		otu.moveNameTo("user2", "user1", "user1")

	})

	otu.setProfile("user2")

	t.Run("Should be able to register related account and remove it", func(t *testing.T) {

		otu.O.Tx("setRelatedAccount",
			WithSigner("user1"),
			WithArg("name", "dapper"),
			WithArg("target", "user2"),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindRelatedAccounts.RelatedAccount", map[string]interface{}{
				"walletName": "dapper",
				"user":       otu.O.Address("user1"),
				"address":    otu.O.Address("user2"),
				"action":     "add",
			})

		otu.O.Script("getStatus",
			WithArg("user", "user1"),
		).
			AssertWithPointerWant(t, "/FINDReport/relatedAccounts",
				autogold.Want("getStatus Dapper", map[string]interface{}{"Flow_dapper": []interface{}{otu.O.Address("user2")}}))

		otu.O.Tx("removeRelatedAccount",
			WithSigner("user1"),
			WithArg("name", "dapper"),
			WithArg("network", "Flow"),
			WithArg("address", otu.O.Address("user2")),
		).
			AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FindRelatedAccounts.RelatedAccount", map[string]interface{}{
				"walletName": "dapper",
				"user":       otu.O.Address("user1"),
				"address":    otu.O.Address("user2"),
				"action":     "remove",
			})

		otu.O.Script("getStatus",
			WithArg("user", "user1"),
		).
			AssertWithPointerError(t, "/FINDReport/relatedAccounts",
				"Object has no key 'relatedAccounts'")

	})

	t.Run("Should be able to set private mode", func(t *testing.T) {

		otu.O.Tx("setPrivateMode",
			WithSigner("user1"),
			WithArg("mode", true),
		).AssertSuccess(t)

		otu.O.Script("getStatus",
			WithArg("user", "user1"),
		).
			AssertWithPointerWant(t, "/FINDReport/privateMode",
				autogold.Want("privatemode true", true),
			)

		otu.O.Tx("setPrivateMode",
			WithSigner("user1"),
			WithArg("mode", false),
		).AssertSuccess(t)

		otu.O.Script("getStatus",
			WithArg("user", "user1"),
		).
			AssertWithPointerWant(t, "/FINDReport/privateMode",
				autogold.Want("privatemode false", false),
			)

	})

	t.Run("Should be able to getStatus of new user", func(t *testing.T) {

		nameAddress := otu.O.Address("user3")
		otu.O.Script("getStatus",
			WithArg("user", nameAddress),
		).AssertWithPointerWant(t,
			"/FINDReport",
			autogold.Want("getStatus", map[string]interface{}{"activatedAccount": true, "isDapper": false, "privateMode": false}),
		)
	})

	t.Run("If a user holds an invalid find name, get status should not return it", func(t *testing.T) {

		nameAddress := otu.O.Address("user2")
		otu.moveNameTo("user2", "user1", "user2")
		otu.O.Script("getStatus",
			WithArg("user", nameAddress),
		).AssertWithPointerError(t,
			"/FINDReport/profile/findName",
			"Object has no key 'findName'",
		)
	})

	t.Run("Should be able to create and edit the social link", func(t *testing.T) {

		otu.O.Tx("editProfile",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("description", "This is description"),
			WithArg("avatar", "This is avatar"),
			WithArg("tags", `["This is tag"]`),
			WithArg("allowStoringFollowers", true),
			WithArg("linkTitles", map[string]string{"CryptoTwitter": "0xBjartek", "FindTwitter": "find"}),
			WithArg("linkTypes", map[string]string{"CryptoTwitter": "Twitter", "FindTwitter": "Twitter"}),
			WithArg("linkUrls", map[string]string{"CryptoTwitter": "https://twitter.com/0xBjartek", "FindTwitter": "https://twitter.com/findonflow"}),
			WithArg("removeLinks", "[]"),
		).
			AssertSuccess(t)

		otu.O.Script("getStatus",
			WithArg("user", "user1"),
		).AssertWithPointerWant(t,
			"/FINDReport/profile/links/FindTwitter",
			autogold.Want("getStatus Find twitter", map[string]interface{}{
				"title": "find",
				"type":  "Twitter",
				"url":   "https://twitter.com/findonflow",
			}),
		)

		otu.O.Tx("editProfile",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("description", "This is description"),
			WithArg("avatar", "This is avatar"),
			WithArg("tags", `["This is tag"]`),
			WithArg("allowStoringFollowers", true),
			WithArg("linkTitles", "{}"),
			WithArg("linkTypes", "{}"),
			WithArg("linkUrls", "{}"),
			WithArg("removeLinks", `["FindTwitter"]`),
		).
			AssertSuccess(t)

		otu.O.Script("getStatus",
			WithArg("user", "user1"),
		).AssertWithPointerError(t,
			"/FINDReport/profile/links/FindTwitter",
			"Object has no key 'FindTwitter'",
		)

	})

	t.Run("Should be able to buy addons that are on Network", func(t *testing.T) {

		user := "user1"

		otu.buyForge(user)

		/* Should not be able to buy addons with wrong balance */
		otu.O.Tx("buyAddon",
			WithSigner("user1"),
			WithArg("name", "name1"),
			WithArg("addon", "forge"),
			WithArg("amount", 10.0),
		).
			AssertFailure(t, "Expect 50.00000000 FUSD for forge addon")

		/* Should not be able to buy addons that does not exist */
		otu.O.Tx("buyAddon",
			WithSigner(user),
			WithArg("name", user),
			WithArg("addon", "A.f8d6e0586b0a20c7.Dandy.NFT"),
			WithArg("amount", 10.0),
		).
			AssertFailure(t, "This addon is not available.")

	})

	t.Run("Should be able to fund users without profile", func(t *testing.T) {

		user := "user1"
		otu.registerFtInRegistry()

		user3 := otu.O.Address("user3")
		otu.O.Tx("sendFT",
			WithSigner(user),
			WithArg("name", user3),
			WithArg("amount", 10.0),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("tag", `""`),
			WithArg("message", `""`),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FungibleTokenSent")
	})

	t.Run("Should be able to fund users with profile but without find name", func(t *testing.T) {

		user := "user1"
		otu.createUser(1000, "user3")

		user3 := otu.O.Address("user3")

		otu.O.Tx("sendFT",
			WithSigner(user),
			WithArg("name", user3),
			WithArg("amount", 10.0),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("tag", `""`),
			WithArg("message", `""`),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FungibleTokenSent")

		otu.O.Tx("sendFT",
			WithSigner("user3"),
			WithArg("name", user),
			WithArg("amount", 10.0),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("tag", `""`),
			WithArg("message", `""`),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FungibleTokenSent")

	})

	t.Run("Should be able to fund users without profile wallet, but with vault proper set up", func(t *testing.T) {

		user := "user1"

		user3 := otu.O.Address("user3")
		otu.removeProfileWallet("user3")

		otu.O.Tx("sendFT",
			WithSigner(user),
			WithArg("name", user3),
			WithArg("amount", 10.0),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("tag", `""`),
			WithArg("message", `""`),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FungibleTokenSent")

		otu.O.Tx("sendFT",
			WithSigner("user3"),
			WithArg("name", user),
			WithArg("amount", 10.0),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("tag", `""`),
			WithArg("message", `""`),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FungibleTokenSent")

	})

	t.Run("Should be able to resolve find name without .find", func(t *testing.T) {
		otu.O.Script("resolve",
			WithArg("name", "user1.find"),
		).
			AssertWant(t, autogold.Want("user 1 address", otu.O.Address("user1")))

	})

	t.Run("Should panic if user pass in invalid character '.'", func(t *testing.T) {
		_, err := otu.O.Script("resolve",
			WithArg("name", "user1.fn"),
		).
			GetAsJson()

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "invalid byte in hex string")

	})

}
