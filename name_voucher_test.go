package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/stretchr/testify/assert"
)

func TestNameVoucher(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(10.0, "user1")

	initUser := func(s string) *OverflowTestUtils {
		otu.O.Tx(
			"initNameVoucher",
			WithSigner(s),
		).
			AssertSuccess(otu.T)

		return otu
	}

	var id uint64
	var err error

	// User 1 : have collection set up
	// User 2 : does not have collection
	t.Run("Should be able to mint NFT to User 1 with collection", func(t *testing.T) {
		initUser("user1")

		minCharLength := 4

		id, err = otu.O.Tx(
			"adminMintAndAirdropNameVoucher",
			WithSigner("find-admin"),
			WithAddresses("users", "user1"),
			WithArg("minCharLength", minCharLength),
		).
			AssertSuccess(t).
			AssertEvent(t, "Minted", map[string]interface{}{
				"address":       otu.O.Address("find"),
				"minCharLength": minCharLength,
			}).
			AssertEvent(t, "Deposit", map[string]interface{}{
				"to": otu.O.Address("user1"),
			}).
			GetIdFromEvent("Minted", "id")
		assert.NoError(t, err)
	})

	t.Run("Should be able to use the name for register new name", func(t *testing.T) {

		otu.O.Tx(
			"redeemNameVoucher",
			WithSigner("user1"),
			WithArg("id", id),
			WithArg("name", "test"),
		).
			AssertSuccess(t).
			AssertEvent(t, "Redeemed", map[string]interface{}{
				"id":            id,
				"address":       otu.O.Address("user1"),
				"minCharLength": 4,
				"findName":      "test",
				"action":        "register",
			})
	})

	otu.createDapperUser("user2")
	var ticketID uint64
	t.Run("Should be able to mint NFT to User 1 without collection", func(t *testing.T) {

		minCharLength := 5

		res := otu.O.Tx(
			"adminMintAndAirdropNameVoucher",
			WithSigner("find-admin"),
			WithAddresses("users", "user2"),
			WithArg("minCharLength", minCharLength),
		).
			AssertSuccess(t).
			AssertEvent(t, "Minted", map[string]interface{}{
				"address":       otu.O.Address("find"),
				"minCharLength": minCharLength,
			}).
			AssertEvent(t, "AirdroppedToLostAndFound", map[string]interface{}{
				"from": otu.O.Address("find"),
				"to":   otu.O.Address("user2"),
			})
		ticketID, err = res.GetIdFromEvent("AirdroppedToLostAndFound", "ticketID")
		assert.NoError(t, err)
		id, err = res.GetIdFromEvent("Minted", "id")
		assert.NoError(t, err)
	})

	t.Run("Should be able to use the name for register new name in LostAndFound directly", func(t *testing.T) {

		otu.O.Tx(
			"redeemNameVoucher",
			WithSigner("user2"),
			WithArg("id", ticketID),
			WithArg("name", "testingisgood"),
		).
			AssertSuccess(t).
			AssertEvent(t, "NameVoucher.Redeemed", map[string]interface{}{
				"id":            id,
				"address":       otu.O.Address("user2"),
				"minCharLength": 5,
				"findName":      "testingisgood",
				"action":        "register",
			})
	})

	type TestCase struct {
		NameVoucherLength uint64
		Names             map[bool][]string
		ExpectedAction    string
	}

	tcs := []TestCase{
		{
			NameVoucherLength: 3,
			Names: map[bool][]string{
				true: {"aaa", "aaaa", "aaaaa", "aaaaaaaaaaa"},
			},
			ExpectedAction: "register",
		},
		{
			NameVoucherLength: 4,
			Names: map[bool][]string{
				false: {"bbb"},
				true:  {"bbbb", "bbbbb", "bbbbbbbbbbbbbb"},
			},
			ExpectedAction: "register",
		},
		{
			NameVoucherLength: 5,
			Names: map[bool][]string{
				false: {"ccc", "cccc"},
				true:  {"ccccc", "ccccccc", "cccccccccccc"},
			},
			ExpectedAction: "register",
		},
		{
			NameVoucherLength: 3,
			Names: map[bool][]string{
				true: {"aaa", "aaaa", "aaaaa", "aaaaaaaaaaa"},
			},
			ExpectedAction: "renew",
		},
	}

	for _, tf := range tcs {
		for success, names := range tf.Names {
			for _, name := range names {
				msg := "Should %sbe able to redeem a voucher and %s a %d character name. Name : %s"
				var s string
				if !success {
					s = "not "
				}
				adminSigner := "find-admin"
				user := "user1"

				t.Run(fmt.Sprintf(msg, s, tf.ExpectedAction, tf.NameVoucherLength, name), func(t *testing.T) {

					// send out the voucher and get prepared
					id, err := otu.O.Tx(
						"adminMintAndAirdropNameVoucher",
						WithSigner(adminSigner),
						WithAddresses("users", user),
						WithArg("minCharLength", tf.NameVoucherLength),
					).
						AssertSuccess(t).
						GetIdFromEvent("Minted", "id")
					assert.NoError(t, err)

					// redeem executes here
					res := otu.O.Tx(
						"redeemNameVoucher",
						WithSigner(user),
						WithArg("id", id),
						WithArg("name", name),
					)

					if success {
						res.AssertSuccess(t).
							AssertEvent(t, "Redeemed", map[string]interface{}{
								"id":            id,
								"address":       otu.O.Address(user),
								"minCharLength": tf.NameVoucherLength,
								"findName":      name,
								"action":        tf.ExpectedAction,
							}).
							AssertEvent(t, "Register", map[string]interface{}{
								"owner": otu.O.Address(user),
								"name":  name,
							})
						return
					}
					res.AssertFailure(t, fmt.Sprintf("You are trying to register a %d character name, but the voucher can only support names with minimun character of %d", len(name), tf.NameVoucherLength))

				})
			}
		}

	}

	nameVoucherLength := 4
	id, err = otu.O.Tx(
		"adminMintAndAirdropNameVoucher",
		WithSigner("find-admin"),
		WithAddresses("users", "user1"),
		WithArg("minCharLength", nameVoucherLength),
	).
		AssertSuccess(t).
		GetIdFromEvent("Minted", "id")
	assert.NoError(t, err)

	type PointerWant struct {
		pointer  string
		expected autogold.Value
	}

	type ViewTestCase struct {
		view  string
		cases []PointerWant
	}

	viewsTC := []ViewTestCase{
		{
			view: "Display",
			cases: []PointerWant{
				{
					pointer:  "/name",
					expected: autogold.Want("display_name", fmt.Sprintf("%d-characters .find name voucher", nameVoucherLength)),
				},
				{
					pointer: "/description",
					expected: autogold.Want("display_description", `The owner of this voucher can claim OR extend any available / owned .find name of 4 characters or more.
This voucher is single-use only and will be destroyed after any registration or extension of .find name.
If the voucher was airdropped then you will find it in your inbox ready to be claimed or used. If it is already in your collection then it is already claimed and can be used in one of two ways:
- To register a new name, login and search for the name using the top search bar. If it is available you will have the option to either Register or Use Voucher. Click Use Voucher and follow the prompts to register that name using your voucher. Once successful the voucher will be burnt and you will have the chosen name in your account
- To extend an existing name. Log in to find and go to the Names tab in your dashboard. Click Manage on the name you wish to extend and if you have this voucher in that account you will an option of Use Voucher underneath Extend. Click that and follow the prompts. On success you will have extended your lease and the voucher will be burnt.`),
				},
				{
					pointer:  "/thumbnail/cid",
					expected: autogold.Want("display_thumbnail", "QmWpQRvGudYrkZw6rKKTrkghkYKs4wt3KQGzxcXJ8JmuSc"),
				},
			},
		},
		{
			view: "ExternalURL",
			cases: []PointerWant{
				{
					pointer:  "/url",
					expected: autogold.Want("ExternalURL_url", fmt.Sprintf("https://find.xyz/%s/collection/nameVoucher/%d", otu.O.Address("user1"), id)),
				},
			},
		},
		{
			view: "Royalties",
			cases: []PointerWant{
				{
					pointer:  "/cutInfos/0/cut",
					expected: autogold.Want("Royalties_cut", 0.025),
				},
				{
					pointer:  "/cutInfos/0/description",
					expected: autogold.Want("Royalties_description", "network"),
				},
			},
		},
		{
			view: "NFTCollectionDisplay",
			cases: []PointerWant{
				{
					pointer:  "/name",
					expected: autogold.Want("NFTCollectionDisplay_name", "NameVoucher"),
				},
				{
					pointer:  "/description",
					expected: autogold.Want("NFTCollectionDisplay_description", "Name Vouchers can be used to claim or extend any available .find name of 3-characters or more, depending on voucher rarity. Vouchers can be used only once and will be destroyed after use. Enjoy!"),
				},
				{
					pointer:  "/externalURL",
					expected: autogold.Want("NFTCollectionDisplay_externalURL", map[string]interface{}{"url": "https://find.xyz/"}),
				},
				{
					pointer: "/squareImage",
					expected: autogold.Want("NFTCollectionDisplay_squareImage", map[string]interface{}{
						"file":      map[string]interface{}{"url": "https://pbs.twimg.com/profile_images/1467546091780550658/R1uc6dcq_400x400.jpg"},
						"mediaType": "image",
					}),
				},
				{
					pointer: "/bannerImage",
					expected: autogold.Want("NFTCollectionDisplay_bannerImage", map[string]interface{}{
						"file":      map[string]interface{}{"url": "https://pbs.twimg.com/profile_banners/1448245049666510848/1674733461/1500x500"},
						"mediaType": "image",
					}),
				},
				{
					pointer:  "/socials",
					expected: autogold.Want("NFTCollectionDisplay_socials", map[string]interface{}{"discord": map[string]interface{}{"url": "https://discord.gg/findonflow"}, "twitter": map[string]interface{}{"url": "https://twitter.com/findonflow"}}),
				},
			},
		},
		{
			view: "Traits",
			cases: []PointerWant{
				{
					pointer:  "/traits/0",
					expected: autogold.Want("Traits_first", map[string]interface{}{"displayType": "number", "name": "Minimum number of characters", "value": nameVoucherLength}),
				},
			},
		},
	}

	for _, tc := range viewsTC {
		for _, p := range tc.cases {
			t.Run(fmt.Sprintf("should get %s view with %s", tc.view, p.expected.Name()), func(t *testing.T) {

				iden, err := otu.O.QualifiedIdentifier("MetadataViews", tc.view)
				assert.NoError(t, err)

				otu.O.Script(
					"view",
					WithArg("user", "user1"),
					WithArg("path", "/public/nameVoucher"),
					WithArg("id", id),
					WithArg("identifier", iden),
				).
					AssertWithPointerWant(t, p.pointer, p.expected)
			})
		}
	}

}
