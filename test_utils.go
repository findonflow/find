package test_main

import (
	"fmt"
	"strings"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/findonflow/find/findGo"
	"github.com/findonflow/find/utils"
	"github.com/hexops/autogold"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var (
	findAdminSigner = WithSigner("find-admin")
	findSigner      = WithSigner("find")
	user1Signer     = WithSigner("user1")

	exampleNFTType = func(otu *OverflowTestUtils) string {
		res, _ := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
		return res
	}
	dandyNFTType = func(otu *OverflowTestUtils) string {
		res, _ := otu.O.QualifiedIdentifier("Dandy", "NFT")
		return res
	}
)

type OverflowTestUtils struct {
	T *testing.T
	O *OverflowState
}

type FindMarket_TenantRule struct {
	Name     string              `json:"name"`
	Types    []cadence.TypeValue `json:"types"`
	RuleType string              `json:"ruleType"`
	Allow    bool                `json:"allow"`
}

func NewOverflowTest(t *testing.T) *OverflowTestUtils {
	o := Overflow(
		WithNetwork("testing"),
		WithFlowForNewUsers(100.0),
	)
	require.NoError(t, o.Error)
	return &OverflowTestUtils{
		T: t,
		O: o,
	}
}

const (
	leaseDurationFloat   = 31536000.0
	lockDurationFloat    = 7776000.0
	auctionDurationFloat = 86400.0
)

func (otu *OverflowTestUtils) AutoGold(classifier string, value interface{}) *OverflowTestUtils {
	otu.T.Helper()
	autogold.Equal(otu.T, value, autogold.Name(otu.T.Name()+"_"+classifier))
	return otu
}

func (otu *OverflowTestUtils) AutoGoldRename(fullname string, value interface{}) *OverflowTestUtils {
	otu.T.Helper()
	fullname = strings.Replace(fullname, " ", "_", -1)
	autogold.Equal(otu.T, value, autogold.Name(otu.T.Name()+"/"+fullname))
	return otu
}

func (otu *OverflowTestUtils) setupMarketAndDandy() uint64 {
	otu.setupFIND().
		setupDandy("user1").
		createUser(100.0, "user2").
		createUser(100.0, "user3").
		registerUser("user2").
		registerUser("user3")

	id := otu.mintThreeExampleDandies()[0]
	return id
}

func (otu *OverflowTestUtils) setupMarketAndDandyDapper() uint64 {
	t := otu.T

	otu.setupFIND().
		createDapperUser("user1").
		registerDapperUser("user1")

	// works as buyForge
	otu.O.Tx("adminAddAddon",
		WithSigner("find-admin"),
		WithArg("name", "user1"),
		WithArg("addon", "forge"),
	).
		AssertSuccess(t).
		AssertEvent(t, "AddonActivated", map[string]interface{}{
			"name":  "user1",
			"addon": "forge",
		})

	forge, _ := otu.O.QualifiedIdentifier("Dandy", "Forge")

	otu.O.Tx("adminAddForge",
		WithSigner("find-admin"),
		WithArg("type", forge),
		WithArg("name", "user1"),
	).AssertSuccess(t)

	otu.createDapperUser("user2").
		createDapperUser("user3").
		registerDapperUser("user2").
		registerDapperUser("user3")

	id := otu.mintThreeExampleDandies()[0]
	return id
}

func (otu *OverflowTestUtils) setupMarketAndMintDandys() []uint64 {
	otu.setupFIND().
		setupDandy("user1").
		createUser(100.0, "user2").
		createUser(100.0, "user3").
		registerUser("user2").
		registerUser("user3")
	otu.setUUID(600)
	ids := otu.mintThreeExampleDandies()
	return ids
}

func (otu *OverflowTestUtils) assertLookupAddress(user, expected interface{}) *OverflowTestUtils {
	otu.O.Script(`import FIND from "../contracts/FIND.cdc"
access(all) fun main(name: String) :  Address? {
    return FIND.lookupAddress(name) } `,
		WithArg("name", user),
	).AssertWant(otu.T, autogold.Want(fmt.Sprintf("lookupAddress-%s", user), expected))
	return otu
}

func (otu *OverflowTestUtils) setupFIND() *OverflowTestUtils {
	// first step create the adminClient as the fin user

	otu.O.Tx("setup_fin_1_create_client", findAdminSigner).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	// link in the server in the versus client
	otu.O.Tx("setup_fin_2_register_client",
		findSigner,
		WithArg("ownerAddress", "find-admin"),
	).AssertSuccess(otu.T).AssertNoEvents(otu.T)

	// set up fin network as the fin user
	otu.O.Tx("setup_fin_3_create_network", findAdminSigner).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	otu.O.Tx("setup_find_market_1_dapper",
		findSigner,
		WithArg("dapperAddress", "dapper"),
	).
		AssertSuccess(otu.T)

	// link in the server in the versus client
	otu.O.Tx("setup_find_market_2",
		findAdminSigner,
		WithArg("tenant", "find"),
		WithArg("tenantAddress", "find"),
		WithArg("findCut", 0.025),
	).AssertSuccess(otu.T)

	otu.setupInfrastructureCut()

	otu.createUser(100.0, "find")

	// link in the server in the versus client
	otu.O.Tx("devSetResidualAddress",
		findAdminSigner,
		WithArg("address", "residual"),
	).AssertSuccess(otu.T)

	otu.O.Tx(
		"initSwitchboard",
		WithSigner("residual"),
		WithArg("dapperAddress", "dapper"),
	).
		AssertSuccess(otu.T)

	// setup find forge
	otu.O.Tx("setup_find_forge_1", WithSigner("find-forge")).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	// link in the server in the versus client
	otu.O.Tx("setup_find_forge_2",
		findSigner,
		WithArg("ownerAddress", "find-forge"),
	).AssertSuccess(otu.T).AssertNoEvents(otu.T)

	return otu.tickClock(1.0)
}

func (otu *OverflowTestUtils) setupOneFootball() *OverflowTestUtils {
	// first step create the adminClient as the fin user

	otu.O.Tx("setup_fin_1_create_client", findAdminSigner).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	// link in the server in the versus client
	otu.O.Tx("setup_fin_2_register_client",
		findSigner,
		WithArg("ownerAddress", "find-admin"),
	).AssertSuccess(otu.T).AssertNoEvents(otu.T)

	// set up fin network as the fin user
	otu.O.Tx("setup_fin_3_create_network", findAdminSigner).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	otu.O.Tx("setup_find_market_1_dapper",
		findSigner,
		WithArg("dapperAddress", "dapper"),
	).
		AssertSuccess(otu.T)

	// link in the server in the versus client
	otu.O.Tx("setup_find_dapper_market",
		findAdminSigner,
		WithArg("adminAddress", "find"),
		WithArg("tenantAddress", "find"),
		WithArg("tenant", "onefootball"),
		WithArg("findCut", 0.025),
	).AssertSuccess(otu.T)

	otu.setupInfrastructureCut()

	otu.createDapperUser("find")

	// link in the server in the versus client
	otu.O.Tx("devSetResidualAddress",
		findAdminSigner,
		WithArg("address", "residual"),
	).AssertSuccess(otu.T)

	otu.O.Tx(
		"initSwitchboard",
		WithSigner("residual"),
		WithArg("dapperAddress", "dapper"),
	).
		AssertSuccess(otu.T)

	// setup find forge
	otu.O.Tx("setup_find_forge_1", WithSigner("find-forge")).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	// link in the server in the versus client
	otu.O.Tx("setup_find_forge_2",
		findSigner,
		WithArg("ownerAddress", "find-forge"),
	).AssertSuccess(otu.T).AssertNoEvents(otu.T)

	return otu.tickClock(1.0)
}

func (otu *OverflowTestUtils) tickClock(time float64) *OverflowTestUtils {
	otu.O.Tx("devClock",
		findAdminSigner,
		WithArg("clock", time),
	).AssertSuccess(otu.T)
	return otu
}

func (otu *OverflowTestUtils) createUser(fusd float64, name string) *OverflowTestUtils {
	nameSigner := WithSigner(name)
	nameArg := WithArg("name", name)

	nameAddress := otu.O.Address(name)

	otu.O.Tx("createProfile", nameSigner, nameArg).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "Profile.Created", map[string]interface{}{
			"userName":  name,
			"createdAt": "find",
		})

	mintFn := otu.O.TxFN(WithSigner("account"),
		WithArg("recipient", name),
		WithArg("amount", fusd),
	)

	for _, mintName := range []string{
		"devMintFusd",
		"devMintUsdc",
	} {
		mintFn(mintName).AssertSuccess(otu.T).
			AssertEvent(otu.T, "TokensDeposited", map[string]interface{}{
				"amount": fusd,
				"to":     nameAddress,
			})
	}

	return otu
}

func (otu *OverflowTestUtils) createDapperUser(name string) *OverflowTestUtils {
	nameSigner := WithSigner(name)
	nameArg := WithArg("name", name)

	otu.O.Tx("initDapperAccount", nameSigner, WithArg("dapperAddress", "dapper")).
		AssertSuccess(otu.T)

	otu.O.Tx("createProfileDapper",
		nameSigner,
		nameArg).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "Profile.Created", map[string]interface{}{
			"userName":  name,
			"createdAt": "find",
		})

	return otu
}

func (otu *OverflowTestUtils) createWearableUser(name string) *OverflowTestUtils {
	nameSigner := WithSigner(name)

	otu.O.Tx("initWearables",
		nameSigner,
	).
		AssertSuccess(otu.T)
	return otu
}

func (otu *OverflowTestUtils) mintWearables(name string) uint64 {
	nameSigner := WithSigner(name)

	id, err := otu.O.Tx("devmintWearables",
		nameSigner,
		WithArg("receiver", name),
	).
		AssertSuccess(otu.T).
		GetIdFromEvent("Minted", "id")

	require.NoError(otu.T, err)
	return id
}

func (otu *OverflowTestUtils) registerUser(name string) *OverflowTestUtils {
	otu.registerUserTransaction(name)
	return otu
}

func (otu *OverflowTestUtils) registerFIND() *OverflowTestUtils {
	nameAddress := otu.O.Address("find-admin")
	expireTime := otu.currentTime() + leaseDurationFloat

	lockedTime := otu.currentTime() + leaseDurationFloat + lockDurationFloat

	otu.createUser(1000.0, "find-admin")

	otu.O.Tx("register",
		WithSigner("find-admin"),
		WithArg("name", "find"),
		WithArg("amount", 100.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Register", map[string]interface{}{
			"validUntil":  expireTime,
			"lockedUntil": lockedTime,
			"owner":       nameAddress,
			"name":        "find",
		})

	return otu
}

func (otu *OverflowTestUtils) registerUserTransaction(name string) OverflowResult {
	nameAddress := otu.O.Address(name)
	expireTime := otu.currentTime() + leaseDurationFloat

	lockedTime := otu.currentTime() + leaseDurationFloat + lockDurationFloat

	return otu.O.Tx("register",
		WithSigner(name),
		WithArg("name", name),
		WithArg("amount", 5.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Register", map[string]interface{}{
			"validUntil":  expireTime,
			"lockedUntil": lockedTime,
			"owner":       nameAddress,
			"name":        name,
		}).
		AssertEvent(otu.T, "FUSD.TokensDeposited", map[string]interface{}{
			"amount": 5.0,
			"to":     otu.O.Address("find-admin"),
		}).
		AssertEvent(otu.T, "FUSD.TokensWithdrawn", map[string]interface{}{
			"amount": 5.0,
			"from":   nameAddress,
		})
}

func (otu *OverflowTestUtils) registerDapperUser(name string) *OverflowTestUtils {
	nameAddress := otu.O.Address(name)
	expireTime := otu.currentTime() + leaseDurationFloat

	lockedTime := otu.currentTime() + leaseDurationFloat + lockDurationFloat

	otu.O.Tx("devRegisterDapper",
		WithSigner(name),
		WithPayloadSigner("dapper"),
		WithArg("merchAccount", "dapper"),
		WithArg("name", name),
		WithArg("amount", 5.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Register", map[string]interface{}{
			"validUntil":  expireTime,
			"lockedUntil": lockedTime,
			"owner":       nameAddress,
			"name":        name,
		}).
		AssertEvent(otu.T, "TokensDeposited", map[string]interface{}{
			"amount": 5.0,
			"to":     otu.O.Address("dapper"),
		})

	return otu
}

func (otu *OverflowTestUtils) registerDapperUserWithName(buyer, name string) *OverflowTestUtils {
	nameAddress := otu.O.Address(buyer)
	expireTime := otu.currentTime() + leaseDurationFloat

	lockedTime := otu.currentTime() + leaseDurationFloat + lockDurationFloat

	otu.O.Tx("devRegisterDapper",
		WithSigner(buyer),
		WithPayloadSigner("dapper"),
		WithArg("merchAccount", "dapper"),
		WithArg("name", name),
		WithArg("amount", 5.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Register", map[string]interface{}{
			"validUntil":  expireTime,
			"lockedUntil": lockedTime,
			"owner":       nameAddress,
			"name":        name,
		}).
		AssertEvent(otu.T, "TokensDeposited", map[string]interface{}{
			"amount": 5.0,
			"to":     otu.O.Address("dapper"),
		})

	return otu
}

func (otu *OverflowTestUtils) renewUserWithName(user, name string) *OverflowTestUtils {
	otu.O.Tx("renewName",
		WithSigner(user),
		WithArg("name", name),
		WithArg("amount", 5.0),
	)
	return otu
}

func (otu *OverflowTestUtils) renewDapperUserWithName(user, name string) *OverflowTestUtils {
	otu.O.Tx("devRenewNameDapper",
		WithSigner(user),
		WithPayloadSigner("dapper"),
		WithArg("merchAccount", "dapper"),
		WithArg("name", name),
		WithArg("amount", 5.0),
	).
		AssertSuccess(otu.T)
	return otu
}

func (otu *OverflowTestUtils) registerUserWithName(buyer, name string) *OverflowTestUtils {
	otu.registerUserWithNameTransaction(buyer, name)
	return otu
}

func (otu *OverflowTestUtils) registerUserWithNameAndForge(buyer, name string) *OverflowTestUtils {
	otu.registerUserWithNameTransaction(buyer, name)
	otu.buyForgeForName(buyer, name)
	return otu
}

func (otu *OverflowTestUtils) registerUserWithNameTransaction(buyer, name string) OverflowResult {
	nameAddress := otu.O.Address(buyer)
	expireTime := otu.currentTime() + leaseDurationFloat

	lockedTime := otu.currentTime() + leaseDurationFloat + lockDurationFloat
	return otu.O.Tx("register",
		WithSigner(buyer),
		WithArg("name", name),
		WithArg("amount", 5.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Register", map[string]interface{}{
			"validUntil":  expireTime,
			"lockedUntil": lockedTime,
			"owner":       nameAddress,
			"name":        name,
		})
	//TODO: fix these once we have propper standard
	/*
		AssertEvent(otu.T, "FUSD.TokensDeposited", map[string]interface{}{
			"amount": 5.0,
			"to":     otu.O.Address("find-admin"),
		}).
		AssertEvent(otu.T, "FUSD.TokensWithdrawn", map[string]interface{}{
			"amount": 5.0,
			"from":   nameAddress,
		})
	*/
}

func (out *OverflowTestUtils) currentTime() float64 {
	value, err := out.O.Script(`import Clock from "../contracts/Clock.cdc"
access(all) fun main() :  UFix64 {
    return Clock.time()
}`).GetAsInterface()
	assert.NoErrorf(out.T, err, "Could not execute script")
	res, _ := value.(float64)
	return res
}

func (otu *OverflowTestUtils) listForSale(name string) *OverflowTestUtils {
	otu.O.Tx("listNameForSale",
		WithSigner(name),
		WithArg("name", name),
		WithArg("directSellPrice", 10.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Sale", map[string]interface{}{
			"amount": 10.0,
			"status": "active_listed",
			"name":   name,
			"seller": otu.O.Address(name),
		})
	return otu
}

func (otu *OverflowTestUtils) listNameForSale(seller, name string) *OverflowTestUtils {
	otu.O.Tx("listNameForSale",
		WithSigner(seller),
		WithArg("name", name),
		WithArg("directSellPrice", 10.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Sale", map[string]interface{}{
			"amount":     10.0,
			"status":     "active_listed",
			"seller":     otu.O.Address(seller),
			"sellerName": seller,
		})
	return otu
}

func (otu *OverflowTestUtils) directOffer(buyer, name string, amount float64) *OverflowTestUtils {
	otu.O.Tx("bidName",
		WithSigner(buyer),
		WithArg("name", name),
		WithArg("amount", amount),
	).AssertSuccess(otu.T).AssertEvent(otu.T, "FIND.DirectOffer", map[string]interface{}{
		"amount": amount,
		"buyer":  otu.O.Address(buyer),
		"name":   name,
		"status": "active_offered",
	})

	return otu
}

func (otu *OverflowTestUtils) listForAuction(name string) *OverflowTestUtils {
	otu.O.Tx("listNameForAuction",
		WithSigner(name),
		WithArg("name", name),
		WithArg("auctionStartPrice", 5.0),
		WithArg("auctionReservePrice", 20.0),
		WithArg("auctionDuration", auctionDurationFloat),
		WithArg("auctionExtensionOnLateBid", 300.0),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.EnglishAuction", map[string]interface{}{
			"amount":              5.0,
			"auctionReservePrice": 20.0,
			"status":              "active_listed",
			"name":                name,
			"seller":              otu.O.Address(name),
		})
	return otu
}

func (otu *OverflowTestUtils) bid(buyer, name string, amount float64) *OverflowTestUtils {
	endTime := otu.currentTime() + auctionDurationFloat
	otu.O.Tx("bidName",
		WithSigner(buyer),
		WithArg("name", name),
		WithArg("amount", amount),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.EnglishAuction", map[string]interface{}{
			"amount":    amount,
			"endsAt":    endTime,
			"buyer":     otu.O.Address(buyer),
			"buyerName": buyer,
			"name":      name,
			"status":    "active_ongoing",
		})
	return otu
}

func (otu *OverflowTestUtils) auctionBid(buyer, name string, amount float64) *OverflowTestUtils {
	endTime := otu.currentTime() + auctionDurationFloat
	otu.O.Tx("bidName",
		WithSigner(buyer),
		WithArg("name", name),
		WithArg("amount", amount),
	).AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.EnglishAuction", map[string]interface{}{
			"amount":    amount,
			"endsAt":    endTime,
			"buyer":     otu.O.Address(buyer),
			"buyerName": buyer,
			"name":      name,
			"status":    "active_ongoing",
		})
	return otu
}

func (otu *OverflowTestUtils) expireAuction() *OverflowTestUtils {
	return otu.tickClock(auctionDurationFloat)
}

func (otu *OverflowTestUtils) expireLease() *OverflowTestUtils {
	return otu.tickClock(leaseDurationFloat)
}

func (otu *OverflowTestUtils) expireLock() *OverflowTestUtils {
	return otu.tickClock(lockDurationFloat)
}

func (otu *OverflowTestUtils) mintThreeExampleDandies() []uint64 {
	result := otu.O.Tx("mintDandy",
		user1Signer,
		WithArg("name", "user1"),
		WithArg("maxEdition", 3),
		WithArg("artist", "Neo"),
		WithArg("nftName", "Neo Motorcycle"),
		WithArg("nftDescription", `Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK`),

		WithArg("nftUrl", "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"),
		WithArg("collectionDescription", "Neo Collectibles FIND"),
		WithArg("collectionExternalURL", "https://neomotorcycles.co.uk/index.html"),
		WithArg("collectionSquareImage", "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp"),
		WithArg("collectionBannerImage", "https://neomotorcycles.co.uk/assets/img/neo-logo-web-dark.png?h=5a4d226197291f5f6370e79a1ee656a1"),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "Dandy.Minted", map[string]interface{}{
			"description": "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK",
			"minter":      "user1",
			"name":        "Neo Motorcycle 3 of 3",
		})

	return result.GetIdsFromEvent("Dandy.Deposit", "id")
}

func (otu *OverflowTestUtils) buyForge(user string) *OverflowTestUtils {
	otu.O.Tx("buyAddon",
		WithSigner(user),
		WithArg("name", user),
		WithArg("addon", "forge"),
		WithArg("amount", 50.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.AddonActivated", map[string]interface{}{
			"name":  user,
			"addon": "forge",
		})

	return otu
}

func (otu *OverflowTestUtils) buyForgeDapper(user string) *OverflowTestUtils {
	otu.O.Tx("buyAddonDapper",
		WithSigner(user),
		WithPayloadSigner("dapper"),
		WithArg("merchAccount", "dapper"),
		WithArg("name", user),
		WithArg("addon", "forge"),
		WithArg("amount", 50.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.AddonActivated", map[string]interface{}{
			"name":  user,
			"addon": "forge",
		})

	return otu
}

func (otu *OverflowTestUtils) buyForgeForName(user, name string) *OverflowTestUtils {
	otu.O.Tx("buyAddon",
		WithSigner(user),
		WithArg("name", name),
		WithArg("addon", "forge"),
		WithArg("amount", 50.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.AddonActivated", map[string]interface{}{
			"name":  name,
			"addon": "forge",
		})

	return otu
}

func (otu *OverflowTestUtils) setupDandy(user string) *OverflowTestUtils {
	return otu.createUser(100.0, user).
		registerUser(user).
		buyForge(user)
}

func (otu *OverflowTestUtils) cancelNFTForSale(name string, id uint64) *OverflowTestUtils {
	otu.O.Tx("delistNFTSale",
		WithSigner(name),
		WithArg("ids", []uint64{id}),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "Sale", map[string]interface{}{
			"status": "cancel",
			"id":     id,
			"seller": otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) cancelLeaseForSale(user, name string) *OverflowTestUtils {
	otu.O.Tx("delistLeaseSale",
		WithSigner(user),
		WithArg("leases", []string{name}),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "Sale", map[string]interface{}{
			"status": "cancel",
			"seller": otu.O.Address(user),
		})
	return otu
}

func (otu *OverflowTestUtils) cancelAllNFTForSale(name string) *OverflowTestUtils {
	otu.O.Tx("delistAllNFTSale",
		WithSigner(name),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) cancelAllLeaseForSale(name string) *OverflowTestUtils {
	otu.O.Tx("delistAllLeaseSale",
		WithSigner(name),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) listNFTForSale(name string, id uint64, price float64) *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	otu.O.Tx("listNFTForSale",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("directSellPrice", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketSale.Sale", map[string]interface{}{
			"status": "active_listed",
			"amount": price,
			"id":     id,
			"seller": otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) listExampleNFTForSale(name string, id uint64, price float64) []uint64 {
	typ, err := otu.O.QualifiedIdentifier("FindMarketSale", "Sale")
	assert.NoError(otu.T, err)

	nftIden, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("listNFTForSale",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("directSellPrice", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		GetIdsFromEvent(typ, "id")

	return res
}

func (otu *OverflowTestUtils) listNFTForEscrowedAuction(name string, id uint64, price float64) *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	otu.O.Tx("listNFTForAuctionEscrowed",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionStartTime", nil),
		WithArg("auctionValidUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"status":              "active_listed",
			"amount":              price,
			"auctionReservePrice": price + 5.0,
			"id":                  id,
			"seller":              otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) listExampleNFTForEscrowedAuction(name string, id uint64, price float64) []uint64 {
	nftIden, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)

	eventIden, err := otu.O.QualifiedIdentifier("FindMarketAuctionEscrow", "EnglishAuction")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("listNFTForAuctionEscrowed",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionStartTime", nil),
		WithArg("auctionValidUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		GetIdsFromEvent(eventIden, "id")

	return res
}

func (otu *OverflowTestUtils) delistAllNFTForEscrowedAuction(name string) *OverflowTestUtils {
	otu.O.Tx("cancelAllMarketAuctionEscrowed",
		WithSigner(name),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) listNFTForSoftAuction(name string, id uint64, price float64) *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	otu.O.Tx("listNFTForAuctionSoft",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"status":              "active_listed",
			"amount":              price,
			"auctionReservePrice": price + 5.0,
			"id":                  id,
			"seller":              otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) listLeaseForSoftAuction(user string, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("listLeaseForAuctionSoftDapper",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"status":              "active_listed",
			"amount":              price,
			"auctionReservePrice": price + 5.0,
			"seller":              otu.O.Address(user),
		})

	return otu
}

func (otu *OverflowTestUtils) delistAllNFT(name string) *OverflowTestUtils {
	otu.O.Tx("cancelAllMarketListings",
		WithSigner(name),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) delistAllNFTForSoftAuction(name string) *OverflowTestUtils {
	otu.O.Tx("cancelAllMarketAuctionSoft",
		WithSigner(name),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) delistAllLeaseForSoftAuction(name string) *OverflowTestUtils {
	otu.O.Tx("cancelAllLeaseMarketAuctionSoft",
		WithSigner(name),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) checkRoyalty(name string, id uint64, royaltyName string, nftAlias string, expectedPlatformRoyalty float64) *OverflowTestUtils {
	/* Ben : Should we rename the check royalty script name? */
	var royalty Royalty

	royaltyIden, err := otu.O.QualifiedIdentifier("MetadataViews", "Royalties")
	assert.NoError(otu.T, err)

	err = otu.O.Script("getCheckRoyalty",
		WithSigner(name),
		WithArg("name", name),
		WithArg("id", id),
		WithArg("nftAliasOrIdentifier", nftAlias),
		WithArg("viewIdentifier", royaltyIden),
	).
		MarshalAs(&royalty)

	assert.NoError(otu.T, err)

	for _, item := range royalty.Items {
		if item.Description == royaltyName {
			assert.Equal(otu.T, expectedPlatformRoyalty, item.Cut)
			return otu
		}
	}

	assert.Equal(otu.T, expectedPlatformRoyalty, 0.0)
	return otu
}

func (otu *OverflowTestUtils) buyNFTForMarketSale(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("buyNFTForSale",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketSale.Sale", map[string]interface{}{
			"amount": price,
			"id":     id,
			"seller": otu.O.Address(seller),
			"buyer":  otu.O.Address(name),
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) increaseAuctioBidMarketEscrow(name string, id uint64, price float64, totalPrice float64) *OverflowTestUtils {
	otu.O.Tx("increaseBidMarketAuctionEscrowed",
		WithSigner(name),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"amount": totalPrice,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) increaseAuctionBidMarketSoft(name string, id uint64, price float64, totalPrice float64) *OverflowTestUtils {
	otu.O.Tx("increaseBidMarketAuctionSoft",
		WithSigner(name),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": totalPrice,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) increaseAuctionBidLeaseMarketSoft(buyer string, name string, price float64, totalPrice float64) *OverflowTestUtils {
	otu.O.Tx("increaseBidLeaseMarketAuctionSoft",
		WithSigner(buyer),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": totalPrice,
			"buyer":  otu.O.Address(buyer),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) saleItemListed(name string, saleType string, price float64) *OverflowTestUtils {
	t := otu.T
	itemsForSale := otu.getItemsForSale(name)

	assert.Equal(t, 1, len(itemsForSale))
	assert.Equal(t, saleType, itemsForSale[0].SaleType)
	assert.Equal(t, price, itemsForSale[0].Amount)
	return otu
}

func (otu *OverflowTestUtils) saleLeaseListed(name string, saleType string, price float64) *OverflowTestUtils {
	t := otu.T
	itemsForSale := otu.getLeasesForSale(name)

	assert.Equal(t, 1, len(itemsForSale))
	assert.Equal(t, saleType, itemsForSale[0].SaleType)
	assert.Equal(t, price, itemsForSale[0].Amount)
	return otu
}

func (otu *OverflowTestUtils) auctionBidMarketEscrow(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("bidMarketAuctionEscrowed",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) auctionBidMarketSoft(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("bidMarketAuctionSoftDapper",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) auctionBidLeaseMarketSoft(buyer string, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
		WithSigner(buyer),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"amount": price,
			"buyer":  otu.O.Address(buyer),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) increaseDirectOfferMarketEscrowed(name string, id uint64, price float64, totalPrice float64) *OverflowTestUtils {
	otu.O.Tx("increaseBidMarketDirectOfferEscrowed",
		WithSigner(name),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"amount": totalPrice,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_offered",
		})

	return otu
}

func (otu *OverflowTestUtils) increaseDirectOfferMarketSoft(name string, id uint64, price float64, totalPrice float64) *OverflowTestUtils {
	otu.O.Tx("increaseBidMarketDirectOfferSoft",
		WithSigner(name),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"amount": totalPrice,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_offered",
		})

	return otu
}

func (otu *OverflowTestUtils) increaseDirectOfferLeaseMarketSoft(user, name string, price float64, totalPrice float64) *OverflowTestUtils {
	otu.O.Tx("increaseBidLeaseMarketDirectOfferSoft",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"amount": totalPrice,
			"buyer":  otu.O.Address(user),
			"status": "active_offered",
		})

	return otu
}

func (otu *OverflowTestUtils) directOfferMarketEscrowed(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	otu.O.Tx("bidMarketDirectOfferEscrowed",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) directOfferMarketEscrowedExampleNFT(name string, seller string, id uint64, price float64) []uint64 {
	nftIden, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)

	eventIden, err := otu.O.QualifiedIdentifier("FindMarketDirectOfferEscrow", "DirectOffer")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("bidMarketDirectOfferEscrowed",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"amount": price,
			"buyer":  otu.O.Address(name),
		}).
		GetIdsFromEvent(eventIden, "id")

	return res
}

func (otu *OverflowTestUtils) cancelAllDirectOfferMarketEscrowed(signer string) *OverflowTestUtils {
	otu.O.Tx("cancelAllMarketDirectOfferEscrowed",
		WithSigner(signer),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) directOfferMarketSoft(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	otu.O.Tx("bidMarketDirectOfferSoftDapper",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
		})

	return otu
}

func (otu *OverflowTestUtils) directOfferLeaseMarketSoft(user string, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("bidLeaseMarketDirectOfferSoftDapper",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("ftAliasOrIdentifier", "FUT"),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"amount": price,
			"buyer":  otu.O.Address(user),
		})

	return otu
}

func (otu *OverflowTestUtils) cancelAllDirectOfferMarketSoft(signer string) *OverflowTestUtils {
	otu.O.Tx("cancelAllMarketDirectOfferSoft",
		WithSigner(signer),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) cancelAllDirectOfferLeaseMarketSoft(signer string) *OverflowTestUtils {
	otu.O.Tx("cancelAllLeaseMarketDirectOfferSoft",
		WithSigner(signer),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) acceptDirectOfferMarketEscrowed(name string, id uint64, buyer string, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillMarketDirectOfferEscrowed",
		WithSigner(name),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"id":     id,
			"seller": otu.O.Address(name),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) acceptDirectOfferMarketSoft(name string, id uint64, buyer string, price float64) *OverflowTestUtils {
	otu.O.Tx("acceptDirectOfferSoftDapper",
		WithSigner(name),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"id":     id,
			"seller": otu.O.Address(name),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "active_accepted",
		})

	return otu
}

func (otu *OverflowTestUtils) acceptLeaseDirectOfferMarketSoft(buyer, seller string, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("acceptLeaseDirectOfferSoftDapper",
		WithSigner(seller),
		WithArg("leaseName", name),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"seller": otu.O.Address(seller),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "active_accepted",
		})

	return otu
}

func (otu *OverflowTestUtils) rejectDirectOfferEscrowed(name string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("cancelMarketDirectOfferEscrowed",
		WithSigner(name),
		WithArg("ids", []uint64{id}),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"status": "rejected",
			"id":     id,
			"seller": otu.O.Address(name),
			"amount": price,
		})

	return otu
}

func (otu *OverflowTestUtils) retractOfferDirectOfferEscrowed(buyer, seller string, id uint64) *OverflowTestUtils {
	otu.O.Tx("retractOfferMarketDirectOfferEscrowed",
		WithSigner(buyer),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferEscrow.DirectOffer", map[string]interface{}{
			"status": "cancel",
			"id":     id,
			"seller": otu.O.Address(seller),
		})

	return otu
}

func (otu *OverflowTestUtils) rejectDirectOfferSoft(name string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("cancelMarketDirectOfferSoft",
		WithSigner(name),
		WithArg("ids", []uint64{id}),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"status": "cancel_rejected",
			"id":     id,
			"seller": otu.O.Address(name),
			"amount": price,
		})

	return otu
}

func (otu *OverflowTestUtils) rejectDirectOfferLeaseSoft(user, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("cancelLeaseMarketDirectOfferSoft",
		WithSigner(user),
		WithArg("leaseNames", []string{name}),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"status": "cancel_rejected",
			"seller": otu.O.Address(user),
			"amount": price,
		})

	return otu
}

func (otu *OverflowTestUtils) retractOfferDirectOfferSoft(buyer, seller string, id uint64) *OverflowTestUtils {
	otu.O.Tx("retractOfferMarketDirectOfferSoft",
		WithSigner(buyer),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"status": "cancel",
			"id":     id,
			"seller": otu.O.Address(seller),
		})

	return otu
}

func (otu *OverflowTestUtils) retractOfferDirectOfferLeaseSoft(buyer, seller, name string) *OverflowTestUtils {
	otu.O.Tx("retractOfferLeaseMarketDirectOfferSoft",
		WithSigner(buyer),
		WithArg("leaseName", name),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"status": "cancel",
			"seller": otu.O.Address(seller),
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionEscrowFromBidder(name string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillMarketAuctionEscrowedFromBidder",
		WithSigner(name),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"id":     id,
			"buyer":  otu.O.Address(name),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionEscrow(name string, id uint64, buyer string, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillMarketAuctionEscrowed",
		WithSigner(name),
		WithArg("owner", name),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionEscrow.EnglishAuction", map[string]interface{}{
			"id":     id,
			"seller": otu.O.Address(name),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionSoft(name string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillMarketAuctionSoftDapper",
		WithSigner(name),
		WithPayloadSigner("dapper"),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"id":     id,
			"buyer":  otu.O.Address(name),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillLeaseMarketAuctionSoft(user string, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
		WithSigner(user),
		WithPayloadSigner("dapper"),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketAuctionSoft.EnglishAuction", map[string]interface{}{
			"buyer":  otu.O.Address(user),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketDirectOfferSoft(name string, id uint64, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
		WithSigner(name),
		WithPayloadSigner("dapper"),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"id":     id,
			"buyer":  otu.O.Address(name),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillLeaseMarketDirectOfferSoft(user, name string, price float64) *OverflowTestUtils {
	otu.O.Tx("fulfillLeaseMarketDirectOfferSoftDapper",
		WithSigner(user),
		WithPayloadSigner("dapper"),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLeaseMarketDirectOfferSoft.DirectOffer", map[string]interface{}{
			"buyer":  otu.O.Address(user),
			"amount": price,
			"status": "sold",
		})

	return otu
}

type Royalty struct {
	Items []struct {
		Cut         float64 `json:"cut"`
		Description string  `json:"description"`
		Receiver    string  `json:"receiver"`
	} `json:"cutInfos"`
}

func (otu *OverflowTestUtils) getItemsForSale(name string) []SaleItemInformation {
	var findReport FINDReport
	err := otu.O.Script("getFindMarket",
		WithArg("user", name),
	).MarshalAs(&findReport)
	if err != nil {
		swallowErr(err)
	}
	var list []SaleItemInformation
	for _, saleItemCollectionReport := range findReport.ItemsForSale {
		list = append(list, saleItemCollectionReport.Items...)
	}
	return list
}

func (otu *OverflowTestUtils) getLeasesForSale(name string) []SaleItemInformation {
	var findReport FINDReport
	err := otu.O.Script("getFindLeaseMarket",
		WithArg("user", name),
	).MarshalAs(&findReport)
	if err != nil {
		panic(err)
		//		swallowErr(err)
	}
	var list []SaleItemInformation
	for _, saleItemCollectionReport := range findReport.LeasesForSale {
		list = append(list, saleItemCollectionReport.Items...)
	}
	return list
}

func swallowErr(err error) {
}

func (otu *OverflowTestUtils) registerFTInFtRegistry(alias string, eventName string, eventResult map[string]interface{}) *OverflowTestUtils {
	otu.O.Tx("adminSetFTInfo_"+alias,
		WithSigner("find-admin"),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventName, eventResult)

	return otu
}

func (otu *OverflowTestUtils) removeFTInFtRegistry(transactionFile, argument, eventName string, eventResult map[string]interface{}) *OverflowTestUtils {
	arg := WithArg("typeIdentifier", argument)

	if transactionFile == "adminRemoveFTInfoByAlias" {
		arg = WithArg("alias", argument)
	}

	otu.O.Tx(transactionFile,
		WithSigner("find-admin"),
		arg,
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventName, eventResult)

	return otu
}

func (otu *OverflowTestUtils) getDandies() []uint64 {
	otu.T.Helper()
	var data []uint64
	err := otu.O.Script("getDandiesIDsFor",
		WithArg("user", "user1"),
		WithArg("minter", "user1"),
	).MarshalAs(&data)

	require.NoError(otu.T, err)
	return data
}

func (otu *OverflowTestUtils) registerDandyInNFTRegistry() *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	result, _ := otu.O.Script("getDandiesIDsFor",
		WithArg("user", "user1"),
		WithArg("minter", "user1"),
	).GetAsInterface()

	var id uint64

	if result == nil {
		result, _ := otu.O.Script("getDandiesIDsFor",
			WithArg("user", "user1"),
			WithArg("minter", "neomotorcycle"),
		).GetAsInterface()

		if result == nil {
			return otu
		}

		ids := result.([]interface{})
		id = ids[0].(uint64)

	} else {
		ids := result.([]interface{})
		id = ids[0].(uint64)
	}

	otu.O.Tx("devaddNFTCatalog",
		WithSigner("account"),
		WithArg("collectionIdentifier", nftIden),
		WithArg("contractName", nftIden),
		WithArg("contractAddress", "find"),
		WithArg("addressWithNFT", "user1"),
		WithArg("nftID", id),
		WithArg("publicPathIdentifier", "findDandy"),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) registerExampleNFTInNFTRegistry() *OverflowTestUtils {
	nftIden, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)

	otu.O.Tx("devaddNFTCatalog",
		WithSigner("account"),
		WithArg("collectionIdentifier", nftIden),
		WithArg("contractName", nftIden),
		WithArg("contractAddress", "find"),
		WithArg("addressWithNFT", "find"),
		WithArg("nftID", 0),
		WithArg("publicPathIdentifier", "exampleNFTCollection"),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) registerFtInRegistry() *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FTRegistry", "FTInfoRegistered")
	assert.NoError(otu.T, err)

	tokens := map[string]string{
		"Flow": "FlowToken",
		"FUSD": "FUSD",
		"USDC": "FiatToken",
	}

	for alias, token := range tokens {
		tokenIden, err := otu.O.QualifiedIdentifier(token, "Vault")
		assert.NoError(otu.T, err)

		otu.registerFTInFtRegistry(strings.ToLower(alias), eventIden, map[string]interface{}{
			"alias":          alias,
			"typeIdentifier": tokenIden,
		})
	}

	otu.registerDandyInNFTRegistry()
	return otu
}

func (otu *OverflowTestUtils) setProfile(user string) *OverflowTestUtils {
	otu.O.Tx("setProfile",
		WithSigner(user),
		WithArg("avatar", "https://find.xyz/assets/img/avatars/avatar14.png"),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) setFlowDandyMarketOption(tenant string) *OverflowTestUtils {
	id, err := otu.O.QualifiedIdentifier("Dandy", "NFT")
	assert.NoError(otu.T, err)

	tx := "tenantsetMarketOption"
	if tenant == "dapper" {
		tx = "devtenantsetMarketOptionDapper"
	}

	otu.O.Tx(tx,
		WithSigner("find"),
		WithArg("nftName", "Dandy"),
		WithArg("nftTypes", []string{id}),
		WithArg("cut", 0.0),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) setFlowExampleMarketOption(tenant string) *OverflowTestUtils {
	id, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)

	tx := "tenantsetMarketOption"
	if tenant == "dapper" {
		tx = "devtenantsetMarketOptionDapper"
	}

	otu.O.Tx(tx,
		WithSigner("find"),
		WithArg("nftName", "ExampleNFT"),
		WithArg("nftTypes", []string{id}),
		WithArg("cut", 0.0),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) setFlowLeaseMarketOption() *OverflowTestUtils {
	id, err := otu.O.QualifiedIdentifier("FIND", "Lease")
	assert.NoError(otu.T, err)
	otu.O.Tx("tenantsetLeaseOptionDapper",
		WithSigner("find"),
		WithArg("nftName", "Lease"),
		WithArg("nftType", id),
		WithArg("cut", 0.0),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) alterMarketOption(ruleName string) *OverflowTestUtils {
	otu.O.Tx("devAlterMarketOption",
		WithSigner("find"),
		WithArg("action", ruleName),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) alterMarketOptionDapper(ruleName string) *OverflowTestUtils {
	otu.O.Tx("devAlterMarketOptionDapper",
		WithSigner("find"),
		WithArg("action", ruleName),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) alterLeaseMarketOption(ruleName string) *OverflowTestUtils {
	otu.O.Tx("devAlterLeaseMarketOption",
		WithSigner("find"),
		WithArg("action", ruleName),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) removeMarketOption(marketType string) *OverflowTestUtils {
	otu.O.Tx("removeMarketOption",
		WithSigner("find"),
		WithArg("saleItemName", marketType),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) setFindCut(cut float64) *OverflowTestUtils {
	otu.O.Tx("adminSetFindCut",
		WithSigner("find-admin"),
		WithArg("tenant", "find"),
		WithArg("cut", cut),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindCutRules", map[string]interface{}{
			"tenant":   "find",
			"ruleName": "findRoyalty",
			"cut":      cut,
			"status":   "active",
		})

	return otu
}

// func (otu *OverflowTestUtils) setFindCutDapper(cut float64) *OverflowTestUtils {

// 	otu.O.Tx("adminSetFindCut",
// 		WithSigner("find-admin"),
// 		WithArg("saleItemName", "findFutRoyalty"),
// 		WithArg("tenant", "find"),
// 		WithArg("cut", cut),
// 	).
// 		AssertSuccess(otu.T)

// 	return otu
// }

// func (otu *OverflowTestUtils) setFindLeaseCutDapper(cut float64) *OverflowTestUtils {

// 	otu.O.Tx("adminSetFindCut",
// 		WithSigner("find-admin"),
// 		WithArg("tenant", "find"),
// 		WithArg("saleItemName", "findFutRoyalty"),
// 		WithArg("cut", cut),
// 	).
// 		AssertSuccess(otu.T)

// 	return otu
// }

func (otu *OverflowTestUtils) blockDandy(script string) *OverflowTestUtils {
	otu.O.Tx(script,
		WithSigner("find-admin"),
		WithArg("tenant", "find"),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) removeProfileWallet(user string) *OverflowTestUtils {
	otu.O.Tx("devRemoveProfileWallet",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) unlinkProfileWallet(user string) *OverflowTestUtils {
	otu.O.Tx("devUnlinkProfileWallet",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) destroyFUSDVault(user string) *OverflowTestUtils {
	otu.O.Tx("devDestroyFUSDVault",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) unlinkDUCVaultReceiver(user string) *OverflowTestUtils {
	otu.O.Tx("unlinkDUCVaultReceiver",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) linkDUCVaultReceiver(user string) *OverflowTestUtils {
	otu.O.Tx("linkDUCVaultReceiver",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) initFUSDVault(user string) *OverflowTestUtils {
	otu.O.Tx("testInitFUSDVault",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) unlinkDandyProvider(user string) *OverflowTestUtils {
	otu.O.Tx("devUnlinkDandyProvider",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) unlinkDandyReceiver(user string) *OverflowTestUtils {
	otu.O.Tx("devUnlinkDandyReceiver",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) destroyDandyCollection(user string) *OverflowTestUtils {
	otu.O.Tx("devDestroyDandyCollection",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) sendDandy(receiver, sender string, id uint64) *OverflowTestUtils {
	otu.O.Tx("sendDandy",
		WithSigner(sender),
		WithArg("user", receiver),
		WithArg("id", id),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) sendFT(receiver, sender, ft string, amount float64) *OverflowTestUtils {
	otu.O.Tx("sendFT",
		WithSigner(sender),
		WithArg("name", receiver),
		WithArg("amount", amount),
		WithArg("ftAliasOrIdentifier", ft),
		WithArg("tag", "tag"),
		WithArg("message", "message"),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) profileBan(user string) *OverflowTestUtils {
	otu.O.Tx("adminSetProfileBan",
		WithSigner("find"),
		WithArg("user", user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) leaseProfileBan(user string) *OverflowTestUtils {
	otu.O.Tx("adminSetProfileBan",
		WithSigner("find"),
		WithArg("user", user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) removeProfileBan(user string) *OverflowTestUtils {
	otu.O.Tx("adminRemoveProfileBan",
		WithSigner("find"),
		WithArg("user", user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) removeLeaseProfileBan(user string) *OverflowTestUtils {
	otu.O.Tx("adminRemoveProfileBan",
		WithSigner("find"),
		WithArg("user", user),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) replaceID(result string, dandyIds []uint64) string {
	counter := 0
	for _, id := range dandyIds {
		result = strings.Replace(result, fmt.Sprint(id)+`"`, "ID"+fmt.Sprint(counter)+`"`, -1)
		counter = counter + 1
	}
	return result
}

func (otu *OverflowTestUtils) moveNameTo(owner, receiver, name string) *OverflowTestUtils {
	otu.O.Tx("moveNameTO",
		WithSigner(owner),
		WithArg("name", name),
		WithArg("receiver", otu.O.Address(receiver)),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.Moved", map[string]interface{}{
			"name": name,
		})

	return otu
}

func (otu *OverflowTestUtils) cancelNameAuction(owner, name string) *OverflowTestUtils {
	otu.O.Tx("cancelNameAuction",
		WithSigner(owner),
		WithArg("names", []string{name}),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FIND.EnglishAuction", map[string]interface{}{
			"name":       name,
			"sellerName": owner,
			"status":     "cancel_listing",
		})

	return otu
}

func (otu *OverflowTestUtils) sendExampleNFT(receiver, sender string, id uint64) *OverflowTestUtils {
	otu.O.Tx("setupExampleNFTCollection",
		WithSigner(receiver),
	).
		AssertSuccess(otu.T)

	otu.O.Tx("sendExampleNFT",
		WithSigner(sender),
		WithArg("user", otu.O.Address(receiver)),
		WithArg("id", id),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) sendSoulBoundNFT(receiver, sender string) *OverflowTestUtils {
	otu.O.Tx("setupExampleNFTCollection",
		WithSigner(receiver),
	).
		AssertSuccess(otu.T)

	otu.O.Tx("sendExampleNFT",
		WithSigner(sender),
		WithArg("user", receiver),
		WithArg("id", 1),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) setExampleNFT() *OverflowTestUtils {
	id, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)
	otu.O.Tx("devtenantsetMarketOptionDapper",
		WithSigner("find"),
		WithArg("nftName", "ExampleNFT"),
		WithArg("nftTypes", []string{id}),
		WithArg("cut", 0.0),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) setDUCExampleNFT() *OverflowTestUtils {
	id, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)
	otu.O.Tx("devtenantsetMarketOptionDapper",
		WithSigner("find"),
		WithArg("nftName", "ExampleNFT"),
		WithArg("nftTypes", []string{id}),
		WithArg("cut", 0.0),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) listNFTForSaleDUC(name string, id uint64, price float64) []uint64 {
	nftIden, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)

	ftIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	eventIden, err := otu.O.QualifiedIdentifier("FindMarketSale", "Sale")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("listNFTForSaleDapper",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", ftIden),
		WithArg("directSellPrice", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		GetIdsFromEvent(eventIden, "id")

	return res
}

func (otu *OverflowTestUtils) listLeaseForSaleDUC(user string, name string, price float64) *OverflowTestUtils {
	ftIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	otu.O.Tx("listLeaseForSaleDapper",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("ftAliasOrIdentifier", ftIden),
		WithArg("directSellPrice", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) getNFTForMarketSale(seller string, id uint64, price float64) *OverflowTestUtils {
	result, err := otu.O.Script("getMetadataForSaleItem",
		WithArg("merchantAddress", "find"),
		WithArg("address", seller),
		WithArg("id", id),
		WithArg("amount", price),
	).GetWithPointer("/name")

	assert.NoError(otu.T, err)
	assert.Equal(otu.T, "DUCExampleNFT", result)

	return otu
}

func (otu *OverflowTestUtils) buyNFTForMarketSaleDUC(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindMarketSale", "Sale")
	assert.NoError(otu.T, err)

	otu.O.Tx("buyNFTForSaleDapper",
		WithSigner(name),
		WithPayloadSigner("dapper"),
		WithArg("address", seller),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"amount": price,
			"id":     id,
			"seller": otu.O.Address(seller),
			"buyer":  otu.O.Address(name),
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) buyLeaseForMarketSaleDUC(buyer, seller, name string, price float64) *OverflowTestUtils {
	amount := price * 0.025
	dapperAmount := price * 0.01
	if dapperAmount < 0.44 {
		dapperAmount = 0.44
	}
	eventIden, err := otu.O.QualifiedIdentifier("FindLeaseMarketSale", "Sale")
	assert.NoError(otu.T, err)

	otu.O.Tx("buyLeaseForSaleDapper",
		WithSigner(buyer),
		WithPayloadSigner("dapper"),
		WithArg("sellerAccount", seller),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"amount": price,
			"seller": otu.O.Address(seller),
			"buyer":  otu.O.Address(buyer),
			"status": "sold",
		}).
		AssertEvent(otu.T, "RoyaltyPaid", map[string]interface{}{
			"amount":      amount,
			"address":     otu.O.Address("find"),
			"royaltyName": "find",
			"tenant":      "find",
		}).
		AssertEvent(otu.T, "RoyaltyPaid", map[string]interface{}{
			"amount":      dapperAmount,
			"address":     otu.O.Address("dapper"),
			"royaltyName": "dapper",
			"tenant":      "find",
		})

	return otu
}

func (otu *OverflowTestUtils) registerDUCInRegistry() *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FTRegistry", "FTInfoRegistered")
	assert.NoError(otu.T, err)

	tokenIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	futTokenIden, err := otu.O.QualifiedIdentifier("FlowUtilityToken", "Vault")
	assert.NoError(otu.T, err)

	otu.registerFTInFtRegistry("duc", eventIden, map[string]interface{}{
		"alias":          "DUC",
		"typeIdentifier": tokenIden,
	})

	otu.registerFTInFtRegistry("fut", eventIden, map[string]interface{}{
		"alias":          "FUT",
		"typeIdentifier": futTokenIden,
	})

	otu.registerExampleNFTInNFTRegistry()
	return otu
}

func (otu *OverflowTestUtils) listNFTForSoftAuctionDUC(name string, id uint64, price float64) []uint64 {
	ftIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	nftIden, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)

	eventIden, err := otu.O.QualifiedIdentifier("FindMarketAuctionSoft", "EnglishAuction")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("listNFTForAuctionSoftDapper",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", ftIden),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+10.0),
	).
		AssertSuccess(otu.T).
		GetIdsFromEvent(eventIden, "id")

	return res
}

func (otu *OverflowTestUtils) listLeaseForSoftAuctionDUC(user, name string, price float64) *OverflowTestUtils {
	ftIden, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	otu.O.Tx("listLeaseForAuctionSoftDapper",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("ftAliasOrIdentifier", ftIden),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+10.0),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) listExampleNFTForSoftAuction(name string, id uint64, price float64) []uint64 {
	nftIden, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)

	eventIden, err := otu.O.QualifiedIdentifier("FindMarketAuctionSoft", "EnglishAuction")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("listNFTForAuctionSoft",
		WithSigner(name),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "DUC"),
		WithArg("price", price),
		WithArg("auctionReservePrice", price+5.0),
		WithArg("auctionDuration", 300.0),
		WithArg("auctionExtensionOnLateBid", 60.0),
		WithArg("minimumBidIncrement", 1.0),
		WithArg("auctionValidUntil", otu.currentTime()+10.0),
	).
		AssertSuccess(otu.T).
		GetIdsFromEvent(eventIden, "id")

	return res
}

func (otu *OverflowTestUtils) auctionBidMarketSoftDUC(name string, seller string, id uint64, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindMarketAuctionSoft", "EnglishAuction")
	assert.NoError(otu.T, err)

	otu.O.Tx("bidMarketAuctionSoftDapper",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"amount": price,
			"id":     id,
			"buyer":  otu.O.Address(name),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) auctionBidLeaseMarketSoftDUC(user string, name string, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindLeaseMarketAuctionSoft", "EnglishAuction")
	assert.NoError(otu.T, err)

	otu.O.Tx("bidLeaseMarketAuctionSoftDapper",
		WithSigner(user),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"amount": price,
			"buyer":  otu.O.Address(user),
			"status": "active_ongoing",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillLeaseMarketAuctionSoftDUC(user string, name string, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindLeaseMarketAuctionSoft", "EnglishAuction")
	assert.NoError(otu.T, err)

	otu.O.Tx("fulfillLeaseMarketAuctionSoftDapper",
		WithSigner(user),
		WithPayloadSigner("dapper"),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"buyer":  otu.O.Address(user),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketAuctionSoftDUC(name string, id uint64, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindMarketAuctionSoft", "EnglishAuction")
	assert.NoError(otu.T, err)

	otu.O.Tx("fulfillMarketAuctionSoftDapper",
		WithSigner(name),
		WithPayloadSigner("dapper"),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"id":     id,
			"buyer":  otu.O.Address(name),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) directOfferMarketSoftDUC(name string, seller string, id uint64, price float64) []uint64 {
	nftIden, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)

	DUC, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("bidMarketDirectOfferSoftDapper",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", DUC),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		GetIdsFromEvent("FindMarketDirectOfferSoft.DirectOffer", "id")

	return res
}

func (otu *OverflowTestUtils) directOfferLeaseMarketSoftDUC(buyer string, name string, price float64) *OverflowTestUtils {
	DUC, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)

	otu.O.Tx("bidLeaseMarketDirectOfferSoftDapper",
		WithSigner(buyer),
		WithArg("leaseName", name),
		WithArg("ftAliasOrIdentifier", DUC),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) directOfferMarketSoftExampleNFT(name string, seller string, id uint64, price float64) []uint64 {
	nftIden, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)

	eventIden, err := otu.O.QualifiedIdentifier("FindMarketDirectOfferSoft", "DirectOffer")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("bidMarketDirectOfferSoftDapper",
		WithSigner(name),
		WithArg("user", seller),
		WithArg("nftAliasOrIdentifier", nftIden),
		WithArg("id", id),
		WithArg("ftAliasOrIdentifier", "DUC"),
		WithArg("amount", price),
		WithArg("validUntil", otu.currentTime()+100.0),
	).
		AssertSuccess(otu.T).
		GetIdsFromEvent(eventIden, "id")

	return res
}

func (otu *OverflowTestUtils) acceptDirectOfferMarketSoftDUC(name string, id uint64, buyer string, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindMarketDirectOfferSoft", "DirectOffer")
	assert.NoError(otu.T, err)

	otu.O.Tx("acceptDirectOfferSoftDapper",
		WithSigner(name),
		WithArg("id", id),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"id":     id,
			"seller": otu.O.Address(name),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "active_accepted",
		})

	return otu
}

func (otu *OverflowTestUtils) acceptDirectOfferLeaseMarketSoftDUC(buyer, seller string, name string, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindLeaseMarketDirectOfferSoft", "DirectOffer")
	assert.NoError(otu.T, err)

	otu.O.Tx("acceptLeaseDirectOfferSoftDapper",
		WithSigner(seller),
		WithArg("leaseName", name),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"seller": otu.O.Address(seller),
			"buyer":  otu.O.Address(buyer),
			"amount": price,
			"status": "active_accepted",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillMarketDirectOfferSoftDUC(name string, id uint64, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindMarketDirectOfferSoft", "DirectOffer")
	assert.NoError(otu.T, err)

	otu.O.Tx("fulfillMarketDirectOfferSoftDapper",
		WithSigner(name),
		WithPayloadSigner("dapper"),
		WithArg("id", id),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"id":     id,
			"buyer":  otu.O.Address(name),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillLeaseMarketDirectOfferSoftDUC(user, name string, price float64) *OverflowTestUtils {
	eventIden, err := otu.O.QualifiedIdentifier("FindLeaseMarketDirectOfferSoft", "DirectOffer")
	assert.NoError(otu.T, err)

	otu.O.Tx("fulfillLeaseMarketDirectOfferSoftDapper",
		WithSigner(user),
		WithPayloadSigner("dapper"),
		WithArg("leaseName", name),
		WithArg("amount", price),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, eventIden, map[string]interface{}{
			"buyer":  otu.O.Address(user),
			"amount": price,
			"status": "sold",
		})

	return otu
}

func (otu *OverflowTestUtils) setUUID(uuid uint64) *OverflowTestUtils {
	otu.O.Tx("devSetUUID",
		WithSigner("user1"),
		WithArg("target", uuid),
	).
		AssertSuccess(otu.T)

	return otu
}

func (otu *OverflowTestUtils) changeRoyaltyExampleNFT(user string, id uint64, cheat bool) *OverflowTestUtils {
	otu.O.Tx("devchangeRoyaltyExampleNFT",
		WithSigner(user),
		WithArg("id", id),
		WithArg("cheat", cheat),
	).
		AssertSuccess(otu.T)
	return otu
}

func (otu *OverflowTestUtils) SendNFTsLostAndFound(nftType string, id uint64, receiver string) uint64 {
	t := otu.T
	res := otu.O.Tx("sendNFTs",
		WithSigner("user1"),
		WithArg("nftIdentifiers", []string{nftType}),
		WithArg("allReceivers", []string{otu.O.Address(receiver)}),
		WithArg("ids", []uint64{id}),
		WithArg("memos", `["Hello!"]`),
		WithArg("donationTypes", `[nil]`),
		WithArg("donationAmounts", `[nil]`),
		WithArg("findDonationType", nil),
		WithArg("findDonationAmount", nil),
	).
		AssertSuccess(t).
		AssertEvent(t, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
			"receiver": otu.O.Address(receiver),
			"sender":   otu.O.Address("user1"),
			"type":     nftType,
			"memo":     "Hello!",
			"name":     "Neo Motorcycle 1 of 3",
		})
	ticketID, err := res.GetIdFromEvent("FindLostAndFoundWrapper.TicketDeposited", "ticketID")
	assert.NoError(otu.T, err)
	return ticketID
}

func (otu *OverflowTestUtils) createExampleNFTTicket() uint64 {
	nftIden, err := otu.O.QualifiedIdentifier("ExampleNFT", "NFT")
	assert.NoError(otu.T, err)

	res := otu.O.Tx("sendNFTs",
		WithSigner("find"),
		WithArg("nftIdentifiers", []string{nftIden}),
		WithArg("allReceivers", `["user1"]`),
		WithArg("ids", []uint64{2}),
		WithArg("memos", `["Hello!"]`),
		WithArg("donationTypes", `[nil]`),
		WithArg("donationAmounts", `[nil]`),
		WithArg("findDonationType", nil),
		WithArg("findDonationAmount", nil),
	).
		AssertSuccess(otu.T).
		AssertEvent(otu.T, "FindLostAndFoundWrapper.TicketDeposited", map[string]interface{}{
			"receiver":     otu.O.Address("user1"),
			"receiverName": "user1",
			"sender":       otu.O.Address("find"),
			"type":         nftIden,
			"id":           2,
			"memo":         "Hello!",
			"name":         "FlowExampleNFT",
			"description":  "For testing listing in Flow",
			"thumbnail":    "https://images.ongaia.com/ipfs/QmZPxYTEx8E5cNy5SzXWDkJQg8j5C3bKV6v7csaowkovua/8a80d1575136ad37c85da5025a9fc3daaf960aeab44808cd3b00e430e0053463.jpg",
		})

	ticketID, err := res.GetIdFromEvent("FindLostAndFoundWrapper.TicketDeposited", "ticketID")
	assert.NoError(otu.T, err)
	return ticketID
}

func (otu *OverflowTestUtils) mintExampleNFTs() uint64 {
	t := otu.T

	res, err := otu.O.Tx("devMintExampleNFT",
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
	).
		AssertSuccess(t).
		GetIdFromEvent("ExampleNFT.Deposit", "id")

	otu.O.Tx("setupExampleNFTCollection",
		WithSigner("find-admin"),
	).
		AssertSuccess(t)

	otu.O.Tx("sendExampleNFT",
		WithSigner("user1"),
		WithArg("user", otu.O.Address("find-admin")),
		WithArg("id", res),
	).
		AssertSuccess(t)

	assert.NoError(t, err)

	return res
}

func generatePackStruct(o *OverflowState, user string, packTypeId uint64, itemType []string, whitelistTime float64, buyTime float64, openTime float64, requiresReservation bool, floatId uint64, clientAddress string) findGo.FindPack_PackRegisterInfo {
	flow, _ := o.QualifiedIdentifier("FlowToken", "Vault")

	saleInfo := []findGo.FindPack_PackRegisterSaleInfo{
		{
			Name:      "public sale",
			StartTime: buyTime,
			Price:     4.2,
			Verifiers: []findGo.FindVerifier_HasOneFLOAT{},
			VerifyAll: false,
		},
		{
			Name:      "whitelist sale",
			StartTime: whitelistTime,
			Price:     4.2,
			Verifiers: []findGo.FindVerifier_HasOneFLOAT{
				{
					FloatEventIds: []uint64{
						floatId,
					},
					Description: "",
				},
			},
			VerifyAll: true,
		},
	}

	return findGo.FindPack_PackRegisterInfo{
		Forge:           user,
		Name:            user,
		Description:     "description",
		TypeId:          packTypeId,
		ExternalURL:     "url",
		SquareImageHash: "thumbnailHash",
		BannerHash:      "bannerHash",
		Socials: map[string]string{
			"twitter": "@ABC",
		},
		PaymentAddress:      o.Address(clientAddress),
		PaymentType:         flow,
		OpenTime:            openTime,
		RequiresReservation: requiresReservation,
		NFTTypes:            itemType,
		StorageRequirement:  60000.0,
		SaleInfo:            saleInfo,
		PrimaryRoyalty: []findGo.FindPack_Royalty{
			{
				Recipient:   o.Address("find"),
				Cut:         0.15,
				Description: "find",
			},
		},
		SecondaryRoyalty: []findGo.FindPack_Royalty{},
		PackFields: map[string]string{
			"Items": "1",
		},
		Extra: map[string]interface{}{},
	}
}

func (otu *OverflowTestUtils) registerPackType(user string, packTypeId uint64, itemType []string, whitelistTime, buyTime, openTime float64, requiresReservation bool, floatId uint64, clientAddress, marketAddress string) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	eventIden, err := otu.O.QualifiedIdentifier("FindPack", "MetadataRegistered")
	assert.NoError(otu.T, err)

	info := generatePackStruct(otu.O, user, packTypeId, itemType, whitelistTime, buyTime, openTime, requiresReservation, floatId, clientAddress)

	/*
		o.Tx("setupFindPackMinterPlatform",
			WithSigner(user),
			WithArg("lease", user),
		).
			AssertSuccess(t)
	*/

	o.Tx("adminRegisterFindPackMetadataStruct",
		WithSigner("find-admin"),
		WithArg("info", info),
	).
		AssertSuccess(t).
		AssertEvent(t, eventIden, map[string]interface{}{
			"packTypeId": packTypeId,
		})
	return otu
}

func (otu *OverflowTestUtils) mintPack(minter string, packTypeId uint64, input []uint64, types []string, salt string) uint64 {
	o := otu.O
	t := otu.T

	packHash := utils.CreateSha3Hash(input, types, salt)

	eventIden, err := otu.O.QualifiedIdentifier("FindPack", "%s")
	assert.NoError(otu.T, err)

	res, err := o.Tx("adminMintFindPack",
		WithSigner("find-admin"),
		WithArg("packTypeName", minter),
		WithArg("typeId", packTypeId),
		WithArg("hashes", []string{packHash}),
	).
		AssertSuccess(t).
		AssertEvent(t, fmt.Sprintf(eventIden, "Minted"), map[string]interface{}{
			"typeId": packTypeId,
		}).
		GetIdFromEvent(fmt.Sprintf(eventIden, "Deposit"), "id")

	publicPathIdentifier := "FindPack_" + minter + "_" + fmt.Sprint(packTypeId)

	otu.O.Tx("devaddNFTCatalog",
		WithSigner("account"),
		WithArg("collectionIdentifier", minter+" season#"+fmt.Sprint(packTypeId)),
		WithArg("contractName", fmt.Sprintf(eventIden, "NFT")),
		WithArg("contractAddress", "find"),
		WithArg("addressWithNFT", "find"),
		WithArg("nftID", res),
		WithArg("publicPathIdentifier", publicPathIdentifier),
	).
		AssertSuccess(otu.T)

	assert.NoError(t, err)
	return res
}

func (otu *OverflowTestUtils) mintPackWithSignature(minter string, packTypeId uint64, input []uint64, types []string, salt string) (uint64, string) {
	o := otu.O
	t := otu.T

	packHash := utils.CreateSha3Hash(input, types, salt)

	eventIden, err := otu.O.QualifiedIdentifier("FindPack", "%s")
	assert.NoError(otu.T, err)

	res, err := o.Tx("adminMintFindPack",
		WithSigner("find-admin"),
		WithArg("packTypeName", minter),
		WithArg("typeId", packTypeId),
		WithArg("hashes", []string{packHash}),
	).
		AssertSuccess(t).
		AssertEvent(t, fmt.Sprintf(eventIden, "Minted"), map[string]interface{}{
			"typeId": packTypeId,
		}).
		GetIdFromEvent(fmt.Sprintf(eventIden, "Deposit"), "id")

	assert.NoError(t, err)

	signature, err := o.SignUserMessage("find", packHash)
	assert.NoError(otu.T, err)

	return res, signature
}

func (otu *OverflowTestUtils) buyPack(user, packTypeName string, packTypeId uint64, numberOfPacks uint64, amount float64) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	eventIden, err := otu.O.QualifiedIdentifier("FindPack", "Purchased")
	assert.NoError(otu.T, err)

	o.Tx("buyFindPack",
		WithSigner(user),
		WithArg("packTypeName", packTypeName),
		WithArg("packTypeId", packTypeId),
		WithArg("numberOfPacks", numberOfPacks),
		WithArg("totalAmount", amount),
	).
		AssertSuccess(t).
		AssertEvent(t, eventIden, map[string]interface{}{
			"amount":  amount,
			"address": otu.O.Address(user),
			"packFields": map[string]interface{}{
				"packImage": "ipfs://thumbnailHash",
				"Items":     "1",
			},
		})

	return otu
}

func (otu *OverflowTestUtils) openPack(user string, packId uint64) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	eventIden, err := otu.O.QualifiedIdentifier("FindPack", "Opened")
	assert.NoError(otu.T, err)

	o.Tx("openFindPack",
		WithSigner(user),
		WithArg("packId", packId),
	).
		AssertSuccess(t).
		AssertEvent(t, eventIden, map[string]interface{}{
			"packId":  packId,
			"address": otu.O.Address(user),
			"packFields": map[string]interface{}{
				"packImage": "ipfs://thumbnailHash",
				"Items":     "1",
			},
		})

	return otu
}

func (otu *OverflowTestUtils) fulfillPack(packId uint64, ids []uint64, salt string) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	o.Tx("adminFulfillFindPack",
		WithSigner("find-admin"),
		WithArg("packId", packId),
		WithArg("typeIdentifiers", []string{dandyNFTType(otu)}),
		WithArg("rewardIds", ids),
		WithArg("salt", salt),
	).
		AssertSuccess(t).
		AssertEvent(t, "Fulfilled", map[string]interface{}{
			"packId": packId,
		})

	return otu
}

func (otu *OverflowTestUtils) createFloatEvent(minter string) uint64 {
	o := otu.O
	t := otu.T

	eventIden, err := otu.O.QualifiedIdentifier("FLOAT", "FLOATEventCreated")
	assert.NoError(otu.T, err)

	floatId, err := o.Tx("devfloatCreateEvent",
		WithSigner(minter),
		WithArg("forHost", minter),
		WithArg("claimable", true),
		WithArg("name", "FloatName"),
		WithArg("description", "FloatDesciption"),
		WithArg("image", "IMG"),
		WithArg("url", "URL"),
		WithArg("transferrable", true),
		WithArg("timelock", false),
		WithArg("dateStart", 0.0),
		WithArg("timePeriod", 0.0),
		WithArg("secret", false),
		WithArg("secrets", `[]`),
		WithArg("limited", false),
		WithArg("capacity", 0),
		WithArg("initialGroups", `[]`),
		WithArg("flowTokenPurchase", false),
		WithArg("flowTokenCost", 0.0),
	).
		AssertSuccess(t).
		GetIdFromEvent(eventIden, "eventId")

	assert.NoError(t, err)
	return floatId
}

func (otu *OverflowTestUtils) claimFloat(minter, receiver string, floatId uint64) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	o.Tx("devfloatClaim",
		WithSigner(receiver),
		WithArg("eventId", floatId),
		WithArg("host", minter),
	).
		AssertSuccess(t)

	return otu
}

func (otu *OverflowTestUtils) addRelatedAccount(user, wallet, network, address string) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	var res *OverflowResult
	if network == "Flow" {

		res = o.Tx("addRelatedFlowAccount",
			WithSigner(user),
			WithArg("name", wallet),
			WithArg("address", address),
		)
		address = o.Address(address)
	} else {
		res = o.Tx("addRelatedAccount",
			WithSigner(user),
			WithArg("name", wallet),
			WithArg("network", network),
			WithArg("address", address),
		)
	}

	res.AssertSuccess(t).
		AssertEvent(t, "RelatedAccount", map[string]interface{}{
			"user":       otu.O.Address(user),
			"walletId":   fmt.Sprintf("%s_%s_%s", network, wallet, address),
			"walletName": wallet,
			"address":    address,
			"network":    network,
			"action":     "add",
		})
	return otu
}

func (otu *OverflowTestUtils) updateRelatedAccount(user, wallet, network, oldAddress, address string) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	var res *OverflowResult
	if network == "Flow" {

		res = o.Tx("updateRelatedFlowAccount",
			WithSigner(user),
			WithArg("name", wallet),
			WithArg("oldAddress", oldAddress),
			WithArg("address", address),
		)
		address = o.Address(address)
		oldAddress = o.Address(oldAddress)
	} else {
		res = o.Tx("updateRelatedAccount",
			WithSigner(user),
			WithArg("name", wallet),
			WithArg("network", network),
			WithArg("oldAddress", oldAddress),
			WithArg("address", address),
		)
	}

	res.AssertSuccess(t).
		AssertEvent(t, "RelatedAccount", map[string]interface{}{
			"walletId":   fmt.Sprintf("%s_%s_%s", network, wallet, address),
			"walletName": wallet,
			"address":    address,
			"network":    network,
			"action":     "add",
		}).
		AssertEvent(t, "RelatedAccount", map[string]interface{}{
			"user":       otu.O.Address(user),
			"walletId":   fmt.Sprintf("%s_%s_%s", network, wallet, oldAddress),
			"walletName": wallet,
			"address":    oldAddress,
			"network":    network,
			"action":     "remove",
		})
	return otu
}

func (otu *OverflowTestUtils) removeRelatedAccount(user, wallet, network, address string) *OverflowTestUtils {
	o := otu.O
	t := otu.T

	var res *OverflowResult

	if network == "Flow" {
		address = o.Address(address)
	}

	res = o.Tx("removeRelatedAccount",
		WithSigner(user),
		WithArg("name", wallet),
		WithArg("network", network),
		WithArg("address", address),
	)

	res.AssertSuccess(t).
		AssertEvent(t, "RelatedAccount", map[string]interface{}{
			"user":       otu.O.Address(user),
			"walletId":   fmt.Sprintf("%s_%s_%s", network, wallet, address),
			"walletName": wallet,
			"address":    address,
			"network":    network,
			"action":     "remove",
		})
	return otu
}

func (otu *OverflowTestUtils) reactToThought(thoughtId uint64, reaction string) *OverflowTestUtils {
	t := otu.T
	otu.O.Tx("reactToFindThoughts",
		WithSigner("user2"),
		WithArg("users", []string{"user1"}),
		WithArg("ids", []uint64{thoughtId}),
		WithArg("reactions", []string{reaction}),
		WithArg("undoReactionUsers", `[]`),
		WithArg("undoReactionIds", `[]`),
	).
		AssertSuccess(t).
		AssertEvent(t, "FindThoughts.Reacted", map[string]interface{}{
			"id":          thoughtId,
			"by":          otu.O.Address("user2"),
			"byName":      "user2",
			"creator":     otu.O.Address("user1"),
			"creatorName": "user1",
			"reaction":    reaction,
			"totalCount": map[string]interface{}{
				"fire": 1,
			},
		})
	return otu
}

func (otu *OverflowTestUtils) postExampleThought() uint64 {
	t := otu.T
	header := "This is header"
	body := "This is body"
	tags := []string{"tag1", "tag2", "@find"}
	mediaHash := "ipfs://mediaHash"
	mediaType := "mediaType"

	cadMediaHash, err := otu.createOptional(mediaHash)
	assert.NoError(t, err)
	cadMediaType, err := otu.createOptional(mediaType)
	assert.NoError(t, err)

	thoughtId, _ := otu.O.Tx("publishFindThought",
		WithSigner("user1"),
		WithArg("header", header),
		WithArg("body", body),
		WithArg("tags", tags),
		WithArg("mediaHash", cadMediaHash),
		WithArg("mediaType", cadMediaType),
		WithArg("quoteNFTOwner", nil),
		WithArg("quoteNFTType", nil),
		WithArg("quoteNFTId", nil),
		WithArg("quoteCreator", nil),
		WithArg("quoteId", nil),
	).
		AssertSuccess(t).
		AssertEvent(t, "FindThoughts.Published", map[string]interface{}{
			"creator":     otu.O.Address("user1"),
			"creatorName": "user1",
			"header":      header,
			"message":     body,
			"medias": []interface{}{
				mediaHash,
			},
			"tags": []interface{}{"tag1", "tag2", "@find"},
		}).
		GetIdFromEvent("Published", "id")
	return thoughtId
}

func (otu *OverflowTestUtils) createOptional(value any) (cadence.Value, error) {
	val, err := cadence.NewValue(value)
	if err != nil {
		return nil, err
	}
	opt := cadence.NewOptional(val)
	return opt, nil
}

func (otu *OverflowTestUtils) identifier(contract, structName string) string {
	s, err := otu.O.QualifiedIdentifier(contract, structName)
	assert.NoError(otu.T, err)
	return s
}

func (otu *OverflowTestUtils) mintRoyaltylessNFT(user string) (uint64, error) {
	otu.O.Tx("setupExampleNFTCollection",
		WithSigner(user),
	).
		AssertSuccess(otu.T)

	return otu.O.Tx("mintExampleNFT",
		WithSigner(user),
		WithArg("user", user),
		WithArg("name", "sample"),
		WithArg("description", "sample description"),
		WithArg("thumbnail", "sample thumbnail"),
		WithArg("soulBound", false),
		WithArg("traits", []uint64{}),
	).
		AssertSuccess(otu.T).
		GetIdFromEvent("Deposit", "id")
}

func (otu *OverflowTestUtils) setupInfrastructureCut() *OverflowTestUtils {
	id, err := otu.O.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	assert.NoError(otu.T, err)
	otu.O.Tx(
		"tenantsetExtraCut",
		WithSigner("find"),
		WithArg("ftTypes", []string{id}),
		WithArg("category", "infrastructure"),
		WithArg("cuts", []findGo.FindMarketCutStruct_ThresholdCut{
			{
				Name:           "dapper",
				Address:        otu.O.Address("dapper"),
				Cut:            0.01,
				Description:    "Dapper takes 0.01% or 0.44 dollars, whichever is higher",
				PublicPath:     "dapperUtilityCoinReceiver",
				MinimumPayment: 0.44,
			},
		}),
	).
		AssertSuccess(otu.T)

	return otu
}

type SaleItem struct {
	Amount              float64 `json:"amount"`
	AuctionReservePrice float64 `json:"auctionReservePrice"`
	Bidder              string  `json:"bidder"`
	ExtensionOnLateBid  string  `json:"extensionOnLateBid"`
	FtType              string  `json:"ftType"`
	FtTypeIdentifier    string  `json:"ftTypeIdentifier"`
	ID                  uint64  `json:"id"`
	ListingValidUntil   string  `json:"listingValidUntil"`
	Owner               string  `json:"owner"`
	SaleType            string  `json:"saleType"`
	Type                string  `json:"type"`
	TypeID              string  `json:"typeId"`
}

type Report struct {
	FINDReport FINDReport `json:"FINDReport"`
	NameReport NameReport `json:"NameReport"`
}

type NameReport struct {
	Status string  `json:"status"`
	Cost   float64 `json:"cost"`
}

type FINDReport struct {
	Profile         interface{}                          `json:"profile"`
	Bids            []interface{}                        `json:"bids"`
	RelatedAccounts map[string]interface{}               `json:"relatedAccounts"`
	Leases          []interface{}                        `json:"leases"`
	PrivateMode     string                               `json:"privateMode"`
	LeasesForSale   map[string]SaleItemCollectionReport  `json:"leasesForSale"`
	LeasesBids      map[string]MarketBidCollectionPublic `json:"leasesBids"`
	ItemsForSale    map[string]SaleItemCollectionReport  `json:"itemsForSale"`
	MarketBids      map[string]MarketBidCollectionPublic `json:"marketBids"`
}

type SaleItemCollectionReport struct {
	Items  []SaleItemInformation `json:"items"`
	Ghosts []GhostListing        `json:"ghosts"`
}

type MarketBidCollectionPublic struct {
	Items  []BidInfo      `json:"items"`
	Ghosts []GhostListing `json:"ghosts"`
}

type BidInfo struct {
	Id                uint64 `json:"id"`
	BidAmount         string `json:"bidAmount"`
	BidTypeIdentifier string `json:"bidTypeIdentifier"`
	// Timestamp         string              `json:"timestamp"`
	Item SaleItemInformation `json:"item"`

	// For Names
	Name string `json:"name"`
}

type SaleItemInformation struct {
	NftIdentifier         string       `json:"nftIdentifier"`
	NftId                 uint64       `json:"nftId"`
	Seller                string       `json:"seller"`
	SellerName            string       `json:"sellerName"`
	Amount                float64      `json:"amount"`
	Bidder                string       `json:"bidder"`
	BidderName            string       `json:"bidderName"`
	ListingId             uint64       `json:"listingId"`
	SaleType              string       `json:"saleType"`
	ListingTypeIdentifier string       `json:"listingTypeIdentifier"`
	FtAlias               string       `json:"ftAlias"`
	FtTypeIdentifier      string       `json:"ftTypeIdentifier"`
	ListingValidUntil     float64      `json:"listingValidUntil"`
	Auction               *AuctionItem `json:"auction,omitempty"`
	ListingStatus         string       `json:"listingStatus"`

	// For Names
	LeaseIdentifier string `json:"leaseIdentifier"`
	LeaseName       string `json:"leaseName"`
}

type NFTInfo struct {
	Id                    uint64 `json:"id"`
	Name                  string `json:"name"`
	Thumbnail             string `json:"thumbnail"`
	Nfttype               string `json:"type"`
	Rarity                string `json:"rarity"`
	EditionNumber         uint64 `json:"editionNumber"`
	TotalInEdition        uint64 `json:"totalInEdition"`
	CollectionName        string `json:"collectionName"`
	CollectionDescription string `json:"collectionDescription"`
}

type AuctionItem struct {
	StartPrice          float64 `json:"startPrice"`
	CurrentPrice        float64 `json:"currentPrice"`
	MinimumBidIncrement float64 `json:"minimumBidIncrement"`
	ReservePrice        float64 `json:"reservePrice"`
	ExtentionOnLateBid  float64 `json:"extentionOnLateBid"`
	AuctionEndsAt       float64 `json:"auctionEndsAt"`
	// Timestamp           string `json:"timestamp"`
}

type GhostListing struct {
	ListingType           string `json:"listingType"`
	ListingTypeIdentifier string `json:"listingTypeIdentifier"`
	Id                    uint64 `json:"id"`
}

func OptionalString(input string) cadence.Optional {
	s, err := cadence.NewString(input)
	if err != nil {
		panic(err)
	}
	return cadence.NewOptional(s)
}

type CollectionData struct {
	Collection          string `json:"collection"`
	Media               string `json:"media"`
	MediaType           string `json:"mediaType"`
	Name                string `json:"name"`
	NftDetailIdentifier string `json:"nftDetailIdentifier"`
	Source              string `json:"source"`
	SubCollection       string `json:"subCollection"`
	Edition             int    `json:"edition"`
	SoulBounded         bool   `json:"soulBounded"`
}
