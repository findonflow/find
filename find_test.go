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
	otu := &OverflowTestUtils{T: t, O: ot.O}

	// these users have profiles and names
	user1Address := otu.O.Address("user1")
	user2Address := otu.O.Address("user2")

	// this user has a profile but no name
	user3Address := otu.O.Address("user3")

	// this use does not have a profile at all
	user4Address := otu.O.Address("user4")

	ot.Run(t, "Should get error if you try to register a name and dont have enough money", func(t *testing.T) {
		otu.O.Tx("register",
			WithSigner("user1"),
			WithArg("name", "usr"),
			WithArg("amount", 500.0),
		).AssertFailure(t, "Amount withdrawn must be less than or equal than the balance of the Vault")
	})

	ot.Run(t, "Should get error if you try to register a name that is too short", func(t *testing.T) {
		otu.O.Tx("register",
			WithSigner("user1"),
			WithArg("name", "ur"),
			WithArg("amount", 5.0),
		).AssertFailure(t, "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters")
	})

	ot.Run(t, "Should get error if you try to register a name that is already claimed", func(t *testing.T) {
		otu.O.Tx("register",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("amount", 5.0),
		).AssertFailure(t, "Name already registered")
	})

	ot.Run(t, "Should allow registering a lease after it is freed", func(t *testing.T) {
		otu.expireLease().tickClock(2.0)

		otu.O.Tx(`
				import FIND from "../contracts/FIND.cdc"

				transaction(name: String) {

				    prepare(account: &Account) {
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
	})

	ot.Run(t, "Should be able to lookup address", func(t *testing.T) {
		otu.assertLookupAddress("user1", user1Address)
	})

	ot.Run(t, "Should not be able to lookup lease after expired", func(t *testing.T) {
		otu.expireLease().tickClock(2.0)

		otu.O.Script("getNameStatus",
			WithArg("name", "user1"),
		).AssertWant(t, autogold.Want("getNameStatus", nil))
	})

	ot.Run(t, "Admin should be able to register without paying FUSD", func(t *testing.T) {
		otu.O.Tx("adminRegisterName",
			WithSigner("find-admin"),
			WithArg("names", `["find-admin2"]`),
			WithArg("user", "find"),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FIND", "Register"), map[string]interface{}{
				"name": "find-admin2",
			})
	})

	ot.Run(t, "Should automatically set Find name to empty if sender have none", func(t *testing.T) {
		otu.O.Script("getName",
			WithArg("address", "user3"),
		).AssertWant(t, autogold.Want("getName empty", nil))
	})

	ot.Run(t, "Should automatically set Find Name if sender have one", func(t *testing.T) {
		otu.registerUserWithName("user3", "name1")

		otu.O.Script("getName",
			WithArg("address", "user3"),
		).AssertWant(t, autogold.Want("getName", "name1"))
	})

	ot.Run(t, "Should be able to register related account and remove it", func(t *testing.T) {
		otu.O.Tx("setRelatedAccount",
			WithSigner("user1"),
			WithArg("name", "dapper"),
			WithArg("target", "user2"),
		).
			AssertSuccess(t).
			AssertEvent(t, otu.identifier("FindRelatedAccounts", "RelatedAccount"), map[string]interface{}{
				"walletName": "dapper",
				"user":       user1Address,
				"address":    user2Address,
				"action":     "add",
			})

		otu.O.Script("getFindStatus",
			WithArg("user", "user1"),
		).AssertWithPointerWant(t, "/accounts/0",
			autogold.Want("getFindStatus Dapper", map[string]interface{}{
				"address": otu.O.Address("user2"),
				"name":    "dapper",
				"network": "Flow",
				"node":    "FindRelatedAccounts",
				"trusted": false,
			}))

		otu.O.Tx("removeRelatedAccount",
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
			})

		otu.O.Script("getFindStatus",
			WithArg("user", "user1"),
		).
			AssertWithPointerError(t, "/accounts",
				"Object has no key 'accounts'")
	})

	ot.Run(t, "Should be able to set private mode", func(t *testing.T) {
		otu.O.Tx("setPrivateMode",
			WithSigner("user1"),
			WithArg("mode", true),
		).AssertSuccess(t)

		otu.O.Script("getFindStatus",
			WithArg("user", "user1"),
		).
			AssertWithPointerWant(t, "/privateMode",
				autogold.Want("privatemode true", true),
			)

		otu.O.Tx("setPrivateMode",
			WithSigner("user1"),
			WithArg("mode", false),
		).AssertSuccess(t)

		otu.O.Script("getFindStatus",
			WithArg("user", "user1"),
		).
			AssertWithPointerWant(t, "/privateMode",
				autogold.Want("privatemode false", false),
			)
	})

	/*
		* TODO: fix
			ot.Run(t, "Should be able to getFindPaths of a user", func(t *testing.T) {
				otu.O.Script("getFindPaths",
					WithArg("user", "user1"),
				).AssertWant(t,
					autogold.Want("getFindPaths", map[string]interface{}{"address": "0xf669cb8d41ce0c74", "paths": []interface{}{
						"findDandy",
						"A_179b6b1cb6755e31_FindMarketDirectOfferEscrow_SaleItemCollection_find",
						"FindPackCollection",
					}}),
				)
			})
	*/

	ot.Run(t, "If a user holds an invalid find name, get status should not return it", func(t *testing.T) {
		otu.moveNameTo("user2", "user1", "user2")
		otu.O.Script("getFindStatus",
			WithArg("user", user2Address),
		).AssertWithPointerError(t,
			"/profile/findName",
			"Object has no key 'findName'",
		)
	})

	ot.Run(t, "Should be able to create and edit the social link", func(t *testing.T) {
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

		otu.O.Script("getFindStatus",
			WithArg("user", "user1"),
		).AssertWithPointerWant(t,
			"/profile/links/FindTwitter",
			autogold.Want("getFindStatus Find twitter", map[string]interface{}{
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

		otu.O.Script("getFindStatus",
			WithArg("user", "user1"),
		).AssertWithPointerError(t,
			"/profile/links/FindTwitter",
			"Object has no key 'FindTwitter'",
		)
	})

	ot.Run(t, "Should not be able to buy forge for less then amount", func(t *testing.T) {
		otu.O.Tx("buyAddon",
			WithSigner("user2"),
			WithArg("name", "user2"),
			WithArg("addon", "forge"),
			WithArg("amount", 10.0),
		).
			AssertFailure(t, "Expect 50.00000000 FUSD for forge addon")
	})

	ot.Run(t, "Should be able to buy addons that are on Network", func(t *testing.T) {
		otu.buyForge("user2")
	})

	ot.Run(t, "Should not be able to buy unavaialbe addon", func(t *testing.T) {
		otu.O.Tx("buyAddon",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("addon", "foo"),
			WithArg("amount", 10.0),
		).
			AssertFailure(t, "This addon is not available.")
	})

	ot.Run(t, "Should be able to fund users without profile", func(t *testing.T) {
		otu.O.Tx("sendFT",
			WithSigner("user1"),
			WithArg("name", user4Address),
			WithArg("amount", 10.0),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("tag", `""`),
			WithArg("message", `""`),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FungibleTokenSent")
	})

	ot.Run(t, "Should be able to fund users with profile but without find name", func(t *testing.T) {
		otu.O.Tx("sendFT",
			WithSigner("user1"),
			WithArg("name", user3Address),
			WithArg("amount", 10.0),
			WithArg("ftAliasOrIdentifier", "Flow"),
			WithArg("tag", `""`),
			WithArg("message", `""`),
		).
			AssertSuccess(t).
			AssertEmitEventName(t, "FungibleTokenSent")
	})

	ot.Run(t, "Should be able to resolve find name with .find", func(t *testing.T) {
		otu.O.Script("resolve",
			WithArg("name", "user1.find"),
		).
			AssertWant(t, autogold.Want("user 1 address", otu.O.Address("user1")))
	})

	ot.Run(t, "Should panic if user pass in invalid character '.'", func(t *testing.T) {
		_, err := otu.O.Script("resolve",
			WithArg("name", "user1.fn"),
		).
			GetAsJson()

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "invalid byte in hex string")
	})

	ot.Run(t, "Should be able to getFindStatus of an FREE lease", func(t *testing.T) {
		res := otu.O.Script("getNameSearchbar",
			WithArg("name", "lease"),
		).AssertWant(t, autogold.Want("getNameSearchbar, FREE", map[string]interface{}{
			"cost":   5,
			"status": "FREE",
		}))

		assert.NoError(t, res.Err)
	})

	ot.Run(t, "Should be able to getFindStatus of an TAKEN lease", func(t *testing.T) {
		otu.registerUserWithName("user1", "lease")
		res := otu.O.Script("getNameSearchbar",
			WithArg("name", "lease"),
		).AssertWant(t, autogold.Want("getNameSearchbar, TAKEN", map[string]interface{}{
			"avatar":         "https://find.xyz/assets/img/avatars/avatar14.png",
			"cost":           5,
			"lockedUntil":    3.9312001e+07,
			"owner":          "0xf669cb8d41ce0c74",
			"registeredTime": 1,
			"status":         "TAKEN",
			"validUntil":     3.1536001e+07,
		}))
		assert.NoError(t, res.Err)
	})

	ot.Run(t, "Should be able to getFindStatus of an LOCKED lease", func(t *testing.T) {
		otu.registerUserWithName("user1", "lease")
		otu.expireLease()
		res := otu.O.Script("getNameSearchbar",
			WithArg("name", "lease"),
		).
			Print().
			AssertWant(t, autogold.Want("getFindStatus, LOCKED", map[string]interface{}{
				"avatar":         "https://find.xyz/assets/img/avatars/avatar14.png",
				"cost":           5,
				"lockedUntil":    3.9312001e+07,
				"owner":          "0xf669cb8d41ce0c74",
				"registeredTime": 1,
				"status":         "LOCKED",
				"validUntil":     3.1536001e+07,
			}))
		assert.NoError(t, res.Err)
	})

	ot.Run(t, "Should be able to register related account and mutually link it for trust", func(t *testing.T) {
		otu.O.Tx("setRelatedAccount",
			WithSigner("user1"),
			WithArg("name", "link"),
			WithArg("target", user2Address),
		).
			AssertSuccess(t)

		otu.O.Script("devgetLinked",
			WithArg("user", "user1"),
			WithArg("name", "link"),
			WithArg("address", user2Address),
		).
			AssertWant(t, autogold.Want("should be false, not linked", false))

		otu.O.Tx("setRelatedAccount",
			WithSigner("user2"),
			WithArg("name", "wrongName"),
			WithArg("target", user1Address),
		).
			AssertSuccess(t)

		otu.O.Script("devgetLinked",
			WithArg("user", "user1"),
			WithArg("name", "link"),
			WithArg("address", user2Address),
		).
			AssertWant(t, autogold.Want("should be false, wrong name", false))

		otu.O.Tx("setRelatedAccount",
			WithSigner("user2"),
			WithArg("name", "link"),
			WithArg("target", user1Address),
		).
			AssertSuccess(t)

		otu.O.Script("devgetLinked",
			WithArg("user", "user1"),
			WithArg("name", "link"),
			WithArg("address", user2Address),
		).
			AssertWant(t, autogold.Want("should be true", true))

		otu.O.Tx("removeRelatedAccount",
			WithSigner("user2"),
			WithArg("name", "link"),
			WithArg("network", "Flow"),
			WithArg("address", user1Address),
		).
			AssertSuccess(t)

		otu.O.Script("devgetLinked",
			WithArg("user", "user1"),
			WithArg("name", "link"),
			WithArg("address", user2Address),
		).
			AssertWant(t, autogold.Want("should be false, removed link", false))

		otu.O.Tx("removeRelatedAccount",
			WithSigner("user1"),
			WithArg("name", "link"),
			WithArg("network", "Flow"),
			WithArg("address", user2Address),
		).
			AssertSuccess(t)

		otu.O.Tx("removeRelatedAccount",
			WithSigner("user2"),
			WithArg("name", "wrongName"),
			WithArg("network", "Flow"),
			WithArg("address", user1Address),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should be able to getFindStatus for trusted accounts", func(t *testing.T) {
		otu.O.Tx("setRelatedAccount",
			WithSigner("user1"),
			WithArg("name", "link"),
			WithArg("target", user2Address),
		).
			AssertSuccess(t)

		otu.O.Tx("setRelatedAccount",
			WithSigner("user1"),
			WithArg("name", "notLink"),
			WithArg("target", user3Address),
		).
			AssertSuccess(t)

		otu.O.Tx("setRelatedAccount",
			WithSigner("user2"),
			WithArg("name", "link"),
			WithArg("target", user1Address),
		).
			AssertSuccess(t)

		otu.O.Script("getFindStatus",
			WithArg("user", "user1"),
		).
			Print().
			AssertWithPointerWant(t, "/accounts",
				autogold.Want("with accounts", `[]interface {}{
  map[string]interface {}{
    "address": "0x192440c99cb17282",
    "name": "link",
    "network": "Flow",
    "node": "FindRelatedAccounts",
    "trusted": true,
  },
  map[string]interface {}{
    "address": "0xfd43f9148d4b725d",
    "name": "notLink",
    "network": "Flow",
    "node": "FindRelatedAccounts",
    "trusted": false,
  },
}`))
	})

	ot.Run(t, "Should be able to follow someone", func(t *testing.T) {
		otu.O.Tx(
			"follow",
			WithSigner("user1"),
			WithArg("follows", map[string][]string{
				"user2": {"user2", "man"},
			}),
		).
			AssertSuccess(t).
			AssertEvent(t, "Follow", map[string]interface{}{
				"follower":  otu.O.Address("user1"),
				"following": otu.O.Address("user2"),
				"tags":      []interface{}{"user2", "man"},
			})
	})

	ot.Run(t, "Should be able to unfollow someone", func(t *testing.T) {
		otu.O.Tx(
			"unfollow",
			WithSigner("user1"),
			WithArg("unfollows", []string{
				"user2",
			}),
		).
			AssertSuccess(t).
			AssertEvent(t, "Unfollow", map[string]interface{}{
				"follower":    otu.O.Address("user1"),
				"unfollowing": otu.O.Address("user2"),
			})
	})

	ot.Run(t, "Should not be able to move old leases", func(t *testing.T) {
		otu.expireLease().expireLease().tickClock(2.0)

		// should not be able to move name to other user
		otu.O.Tx("moveNameTO",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("receiver", user2Address),
		).
			AssertFailure(t, "This is not a valid lease. Lease already expires and some other user registered it. Lease : user1")
	})

	ot.Run(t, "Should not be able to get old leases information", func(t *testing.T) {
		otu.expireLease().expireLease().tickClock(2.0)

		otu.O.Script(`
		 			import FIND from "../contracts/FIND.cdc"

		 			access(all) fun main(user: Address) : [FIND.LeaseInformation] {
            let finLeases= getAccount(user).capabilities.borrow<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)!
            return finLeases.getLeaseInformation()
		 			}
		 		`,
			WithArg("user", "user1"),
		).
			AssertWant(t, autogold.Want("should be nil", nil))
	})

	ot.Run(t, "Should not be able to get old leases", func(t *testing.T) {
		otu.expireLease().expireLease().tickClock(2.0)

		otu.O.Script(`
		 			import FIND from "../contracts/FIND.cdc"

		 			access(all) fun main(user: Address) : [String] {
            let finLeases= getAccount(user).capabilities.borrow<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)!
            return finLeases.getLeases()
		 			}
		 		`,
			WithArg("user", "user1"),
		).
			AssertWant(t, autogold.Want("should not be able to get old leases", nil))
	})

	ot.Run(t, "Should be able to get old leases in getInvalidatedLeases", func(t *testing.T) {
		otu.expireLease().expireLease().tickClock(2.0)

		otu.O.Script(`
		 			import FIND from "../contracts/FIND.cdc"

		 			access(all) fun main(user: Address) : [String] {
            let finLeases= getAccount(user).capabilities.borrow<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)!
            return finLeases.getInvalidatedLeases()
		 			}
		 		`,
			WithArg("user", "user1"),
		).
			AssertWant(t, autogold.Want("should get invalid leases", `[]interface {}{
  "user1",
}`))
	})

	ot.Run(t, "Should not be able to list old leases for sale", func(t *testing.T) {
		otu.expireLease().expireLease().tickClock(2.0)
		// should be able to list name for sale
		otu.O.Tx("listNameForSale",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("directSellPrice", 10.0),
		).AssertFailure(t, "This is not a valid lease")
	})

	ot.Run(t, "Should be able to list lease for auction", func(t *testing.T) {
		otu.O.Tx("listNameForAuction",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("auctionStartPrice", 5.0),
			WithArg("auctionReservePrice", 20.0),
			WithArg("auctionDuration", auctionDurationFloat),
			WithArg("auctionExtensionOnLateBid", 300.0),
		).AssertSuccess(t)
	})

	ot.Run(t, "Should not be able to list old lease for auction", func(t *testing.T) {
		otu.expireLease().expireLease().tickClock(2.0)
		otu.O.Tx("listNameForAuction",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("auctionStartPrice", 5.0),
			WithArg("auctionReservePrice", 20.0),
			WithArg("auctionDuration", auctionDurationFloat),
			WithArg("auctionExtensionOnLateBid", 300.0),
		).AssertFailure(t, "This is not a valid lease")
	})

	ot.Run(t, "Should be able to delist old leases for sale", func(t *testing.T) {
		otu.listNameForSale("user1", "user1")
		otu.expireLease().expireLease().tickClock(2.0)

		otu.O.Tx("delistNameSale",
			WithSigner("user1"),
			WithArg("names", []string{"user1"}),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should be able to delist old leases for auction", func(t *testing.T) {
		otu.O.Tx("listNameForAuction",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("auctionStartPrice", 5.0),
			WithArg("auctionReservePrice", 20.0),
			WithArg("auctionDuration", auctionDurationFloat),
			WithArg("auctionExtensionOnLateBid", 300.0),
		).AssertSuccess(t)

		otu.expireLease().expireLease().tickClock(2.0)
		otu.O.Tx("cancelNameAuction",
			WithSigner("user1"),
			WithArg("names", []string{"user1"}),
		).AssertSuccess(t)
	})

	ot.Run(t, "Should be able to cleanup invalid leases", func(t *testing.T) {
		otu.O.Tx("cleanUpInvalidatedLease",
			WithSigner("user1"),
			WithArg("names", []string{"user1"}),
		).
			AssertFailure(t, "This is a valid lease. You cannot clean this up")

		otu.expireLease().expireLease().tickClock(2.0)
		otu.O.Tx("cleanUpInvalidatedLease",

			WithSigner("user1"),
			WithArg("names", []string{"user1"}),
		).AssertSuccess(t)
	})
}
