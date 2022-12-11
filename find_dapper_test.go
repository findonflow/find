package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

/*
Tests must be in the same folder as flow.json with contracts and transactions/scripts in subdirectories in order for the path resolver to work correctly
*/
func TestFINDDapper(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createDapperUser("user1").
		registerDapperUser("user1")

	t.Run("Should be able to register a name", func(t *testing.T) {

		// Can fix this with pointerWant
		otu.O.Script("getLeases").AssertWithPointerWant(t, "/0/name",
			autogold.Want("allLeases", "user1"),
		)
	})

	t.Run("Should get expected output for register script", func(t *testing.T) {

		otu.O.Script("getMetadataForRegisterDapper",
			WithArg("merchAccount", "find"),
			WithArg("name", "user2"),
			WithArg("amount", 5.0),
		).AssertWant(t, autogold.Want("getMetadataForRegisterDapper", map[string]interface{}{
			"amount": 5, "description": "Name :user2 for Dapper Credit 5.00000000",
			"id":       0,
			"imageURL": "https://ik.imagekit.io/xyvsisxky/tr:ot-user2,ots-55,otc-58B792,ox-N166,oy-N24,ott-b/https://i.imgur.com/8W8NoO1.png",
			"name":     "user2",
		}))
	})

	t.Run("Should get error if you try to register a name that is too short", func(t *testing.T) {

		otu.O.Tx("registerDapper",
			WithSigner("user1"),
			WithPayloadSigner("dapper"),
			WithArg("merchAccount", "find"),
			WithArg("name", "ur"),
			WithArg("amount", 5.0),
		).AssertFailure(t, "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
	})

	t.Run("Should get error if you try to register a name that is already claimed", func(t *testing.T) {
		otu.O.Tx("registerDapper",
			WithSigner("user1"),
			WithPayloadSigner("dapper"),
			WithArg("merchAccount", "find"),
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
		).AssertFailure(t, "locked")

		otu.expireLease()
		otu.registerDapperUser("user1")
	})

	t.Run("Should be able to lookup address", func(t *testing.T) {

		otu.assertLookupAddress("user1", otu.O.Address("user1"))
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

		otu.O.Tx("adminRegisterName",
			WithSigner("find-admin"),
			WithArg("names", `["find-admin"]`),
			WithArg("user", "find"),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FIND", "Register"), map[string]interface{}{
				"name": "find-admin",
			})

	})

	t.Run("Should get expected output for renew name script", func(t *testing.T) {

		otu.O.Script("getMetadataForRenewNameDapper",
			WithArg("merchAccount", "find"),
			WithArg("name", "user1"),
			WithArg("amount", 5.0),
		).AssertWant(t, autogold.Want("getMetadataForRenewNameDapper", map[string]interface{}{
			"amount": 5, "description": "Renew name :user1 for Dapper Credit 5.00000000",
			"id":       0,
			"imageURL": "https://ik.imagekit.io/xyvsisxky/tr:ot-user1,ots-55,otc-58B792,ox-N166,oy-N24,ott-b/https://i.imgur.com/8W8NoO1.png",
			"name":     "user1",
		}))
	})

	otu.renewDapperUserWithName("user1", "user1").
		createDapperUser("user2").
		registerDapperUser("user2")

	otu.tickClock(1.0)

	t.Run("Should be able to send lease to another name", func(t *testing.T) {

		otu.O.Tx("moveNameToDapper",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("receiver", "user2"),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FIND", "Moved"), map[string]interface{}{
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

		otu.registerDapperUserWithName("user1", "name1").
			moveNameTo("user1", "user2", "user1")

		otu.O.Script("getName",
			WithArg("address", "user1"),
		).
			AssertWant(t, autogold.Want("getName empty", "name1"))

		otu.moveNameTo("user2", "user1", "user1")

	})

	otu.setProfile("user2")

	t.Run("Should be able to register related account and remove it", func(t *testing.T) {

		otu.O.Tx("setRelatedAccountDapper",
			WithSigner("user1"),
			WithArg("name", "dapper"),
			WithArg("target", "user2"),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindRelatedAccounts", "RelatedAccount"), map[string]interface{}{
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

		otu.O.Tx("removeRelatedAccountDapper",
			WithSigner("user1"),
			WithArg("name", "dapper"),
			WithArg("network", "Flow"),
			WithArg("address", otu.O.Address("user2")),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindRelatedAccounts", "RelatedAccount"), map[string]interface{}{
				"walletName": "dapper",
				"user":       otu.O.Address("user1"),
				"address":    otu.O.Address("user2"),
				"action":     "remove",
				"network":    "Flow",
			})

		otu.O.Script("getStatus",
			WithArg("user", "user1"),
		).
			AssertWithPointerError(t, "/FINDReport/relatedAccounts",
				"Object has no key 'relatedAccounts'")

	})

	// t.Run("Should be able to set private mode", func(t *testing.T) {

	// 	otu.O.Tx("setPrivateModeDapper",
	// 		WithSigner("user1"),
	// 		WithArg("mode", true),
	// 	).AssertSuccess(t)

	// 	otu.O.Script("getStatus",
	// 		WithArg("user", "user1"),
	// 	).
	// 		AssertWithPointerWant(t, "/FINDReport/privateMode",
	// 			autogold.Want("privatemode true", true),
	// 		)

	// 	otu.O.Tx("setPrivateModeDapper",
	// 		WithSigner("user1"),
	// 		WithArg("mode", false),
	// 	).AssertSuccess(t)

	// 	otu.O.Script("getStatus",
	// 		WithArg("user", "user1"),
	// 	).
	// 		AssertWithPointerWant(t, "/FINDReport/privateMode",
	// 			autogold.Want("privatemode false", false),
	// 		)

	// })

	// t.Run("Should be able to getStatus of new user", func(t *testing.T) {

	// 	nameAddress := otu.O.Address("user3")
	// 	otu.O.Script("getStatus",
	// 		WithArg("user", nameAddress),
	// 	).AssertWithPointerWant(t,
	// 		"/FINDReport",
	// 		autogold.Want("getStatus", map[string]interface{}{"activatedAccount": true, "isDapper": false, "privateMode": false}),
	// 	)
	// })

	// t.Run("If a user holds an invalid find name, get status should not return it", func(t *testing.T) {

	// 	nameAddress := otu.O.Address("user2")
	// 	otu.moveNameTo("user2", "user1", "user2")
	// 	otu.O.Script("getStatus",
	// 		WithArg("user", nameAddress),
	// 	).AssertWithPointerError(t,
	// 		"/FINDReport/profile/findName",
	// 		"Object has no key 'findName'",
	// 	)
	// })

	// t.Run("Should be able to create and edit the social link", func(t *testing.T) {

	// 	otu.O.Tx("editProfileDapper",
	// 		WithSigner("user1"),
	// 		WithArg("name", "user1"),
	// 		WithArg("description", "This is description"),
	// 		WithArg("avatar", "This is avatar"),
	// 		WithArg("tags", `["This is tag"]`),
	// 		WithArg("allowStoringFollowers", true),
	// 		WithArg("linkTitles", map[string]string{"CryptoTwitter": "0xBjartek", "FindTwitter": "find"}),
	// 		WithArg("linkTypes", map[string]string{"CryptoTwitter": "Twitter", "FindTwitter": "Twitter"}),
	// 		WithArg("linkUrls", map[string]string{"CryptoTwitter": "https://twitter.com/0xBjartek", "FindTwitter": "https://twitter.com/findonflow"}),
	// 		WithArg("removeLinks", "[]"),
	// 	).
	// 		AssertSuccess(t)

	// 	otu.O.Script("getStatus",
	// 		WithArg("user", "user1"),
	// 	).AssertWithPointerWant(t,
	// 		"/FINDReport/profile/links/FindTwitter",
	// 		autogold.Want("getStatus Find twitter", map[string]interface{}{
	// 			"title": "find",
	// 			"type":  "Twitter",
	// 			"url":   "https://twitter.com/findonflow",
	// 		}),
	// 	)

	// 	otu.O.Tx("editProfileDapper",
	// 		WithSigner("user1"),
	// 		WithArg("name", "user1"),
	// 		WithArg("description", "This is description"),
	// 		WithArg("avatar", "This is avatar"),
	// 		WithArg("tags", `["This is tag"]`),
	// 		WithArg("allowStoringFollowers", true),
	// 		WithArg("linkTitles", "{}"),
	// 		WithArg("linkTypes", "{}"),
	// 		WithArg("linkUrls", "{}"),
	// 		WithArg("removeLinks", `["FindTwitter"]`),
	// 	).
	// 		AssertSuccess(t)

	// 	otu.O.Script("getStatus",
	// 		WithArg("user", "user1"),
	// 	).AssertWithPointerError(t,
	// 		"/FINDReport/profile/links/FindTwitter",
	// 		"Object has no key 'FindTwitter'",
	// 	)

	// })

	// t.Run("Should get expected output for buyAddon script", func(t *testing.T) {

	// 	otu.O.Script("getMetadataForBuyAddonDapper",
	// 		WithArg("merchAccount", "find"),
	// 		WithArg("name", "name1"),
	// 		WithArg("addon", "forge"),
	// 		WithArg("amount", 10.0),
	// 	).AssertWant(t, autogold.Want("getMetadataForBuyAddonDapper", map[string]interface{}{
	// 		"amount": 10, "description": "Purchase addon forge for name :name1 for Dapper Credit 10.00000000",
	// 		"id":       0,
	// 		"imageURL": "https://i.imgur.com/8W8NoO1.png",
	// 		"name":     "name1",
	// 	}))
	// })

	// t.Run("Should be able to buy addons that are on Network", func(t *testing.T) {

	// 	user := "user1"

	// 	otu.buyForgeDapper(user)

	// 	/* Should not be able to buy addons with wrong balance */
	// 	otu.O.Tx("buyAddonDapper",
	// 		WithSigner("user1"),
	// 		WithPayloadSigner("dapper"),
	// 		WithArg("merchAccount", "find"),
	// 		WithArg("name", "name1"),
	// 		WithArg("addon", "forge"),
	// 		WithArg("amount", 10.0),
	// 	).
	// 		AssertFailure(t, "Expect 50.00000000 Dapper Credit for forge addon")

	// 	/* Should not be able to buy addons that does not exist */
	// 	otu.O.Tx("buyAddonDapper",
	// 		WithSigner(user),
	// 		WithPayloadSigner("dapper"),
	// 		WithArg("merchAccount", "find"),
	// 		WithArg("name", user),
	// 		WithArg("addon", dandyNFTType(otu)),
	// 		WithArg("amount", 10.0),
	// 	).
	// 		AssertFailure(t, "This addon is not available.")

	// })

}
