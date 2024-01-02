package test_main

import (
	"fmt"
	"os"
	"strings"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/findonflow/find/findGo"
	"github.com/findonflow/find/utils"
)

// we set the shared overflow test struct that will reset to known setup state after each test
var (
	ot         *OverflowTest
	dandyIds   []uint64 // ids for test dandies minted
	exampleIds []uint64 // ids for test example nfts minted
	packId     uint64   // the id for the test pack
	packTypeId uint64
)

func TestMain(m *testing.M) {
	var err error
	ot, err = SetupTest([]OverflowOption{
		WithCoverageReport(),
		WithFlowForNewUsers(100.0),
	}, SetupFIND)
	if err != nil {
		panic(err)
	}
	code := m.Run()
	ot.Teardown()
	os.Exit(code)
}

/*
* user1 and user2 are the same
* user3 does not have a name
 */
func SetupFIND(o *OverflowState) error {
	stx := o.TxFN(WithPanicInteractionOnError(true))

	stx("setup_fin_1_create_client", findAdminSigner)

	// link in the server in the versus client
	stx("setup_fin_2_register_client",
		findSigner,
		WithArg("ownerAddress", "find-admin"),
	)

	// set up fin network as the fin user
	stx("setup_fin_3_create_network", findAdminSigner)

	stx("setup_find_market_1_dapper",
		findSigner,
		WithArg("dapperAddress", "dapper"),
	)

	// link in the server in the versus client
	res := stx("setup_find_market_2",
		findAdminSigner,
		WithArg("tenant", "find"),
		WithArg("tenantAddress", "find"),
		WithArg("findCut", 0.025),
	)

	if res.Err != nil {
		panic(res.Err.Error())
	}

	id, err := o.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	if err != nil {
		panic(err)
	}
	stx(
		"tenantsetExtraCut",
		WithSigner("find"),
		WithArg("ftTypes", []string{id}),
		WithArg("category", "infrastructure"),
		WithArg("cuts", []findGo.FindMarketCutStruct_ThresholdCut{
			{
				Name:           "dapper",
				Address:        o.Address("dapper"),
				Cut:            0.01,
				Description:    "Dapper takes 0.01% or 0.44 dollars, whichever is higher",
				PublicPath:     "dapperUtilityCoinReceiver",
				MinimumPayment: 0.44,
			},
		}),
	)

	// link in the server in the versus client
	stx("devSetResidualAddress",
		findAdminSigner,
		WithArg("address", "residual"),
	)

	createUser(stx, 100.0, "find")
	stx(
		"initSwitchboard",
		WithSigner("residual"),
		WithArg("dapperAddress", "dapper"),
	)

	// setup find forge
	stx("setup_find_forge_1", WithSigner("find-forge"))

	// link in the server in the versus client
	stx("setup_find_forge_2",
		findSigner,
		WithArg("ownerAddress", "find-forge"),
	)

	stx("devClock",
		findAdminSigner,
		WithArg("clock", 1.0),
	)

	createUser(stx, 100.0, "user1")

	stx("register",
		WithSigner("user1"),
		WithArg("name", "user1"),
		WithArg("amount", 5.0),
	)

	stx("buyAddon",
		WithSigner("user1"),
		WithArg("name", "user1"),
		WithArg("addon", "forge"),
		WithArg("amount", 50.0),
	)

	createUser(stx, 100.0, "user2")

	stx("register",
		WithSigner("user2"),
		WithArg("name", "user2"),
		WithArg("amount", 5.0),
	)

	createUser(stx, 100.0, "user3")

	tokens := []string{
		"Flow",
		"FUSD",
		"USDC",
	}

	for _, alias := range tokens {
		registerFtInFTRegistry(stx, strings.ToLower(alias))
	}

	stx("devsetupRelatedAccount",
		WithSigner("user1"),
	)

	stx("setupExampleNFTCollection", WithSigner("user1"))

	er := stx("mintExampleNFT",
		findSigner,
		WithArg("address", "user1"),
		WithArg("name", "Example1"),
		WithArg("description", "An example NFT"),
		WithArg("thumbnail", "http://foo.bar"),
		WithArg("soulBound", false),
	)

	exampleIds = er.GetIdsFromEvent("NonFungibleToken.Deposit", "id")

	// we register example NFT in the catalog
	exampleNFTIdentifier, _ := o.QualifiedIdentifier("ExampleNFT", "NFT")
	stx("devaddNFTCatalog",
		WithSigner("account"),
		WithArg("collectionIdentifier", exampleNFTIdentifier),
		WithArg("contractName", exampleNFTIdentifier),
		WithArg("contractAddress", "find"),
		WithArg("addressWithNFT", "user1"),
		WithArg("nftID", exampleIds[0]),
		WithArg("publicPathIdentifier", "exampleNFTCollection"),
	)

	// we mint dandy for testing
	result := stx("mintDandy",
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
	)

	dandyIds = result.GetIdsFromEvent("Dandy.Deposit", "id")

	dandyIdentifier, _ := o.QualifiedIdentifier("Dandy", "NFT")
	stx("devaddNFTCatalog",
		WithSigner("account"),
		WithArg("collectionIdentifier", dandyIdentifier),
		WithArg("contractName", dandyIdentifier),
		WithArg("contractAddress", "find"),
		WithArg("addressWithNFT", "user1"),
		WithArg("nftID", dandyIds[0]),
		WithArg("publicPathIdentifier", "findDandy"),
	)

	// add that we can sell dandies on the market
	stx("tenantsetMarketOption",
		WithSigner("find"),
		WithArg("nftName", "Dandy"),
		WithArg("nftTypes", []string{dandyIdentifier}),
		WithArg("cut", 0.0),
	)

	// add that we can sell dandies on the market
	stx("tenantsetMarketOption",
		WithSigner("find"),
		WithArg("nftName", "Example"),
		WithArg("nftTypes", []string{exampleNFTIdentifier}),
		WithArg("cut", 0.0),
	)

	// set up packs
	packTypeId = uint64(1)
	salt := "find"
	singleType := []string{dandyIdentifier}
	minter := "user1"

	info := generatePackStruct(o, minter, packTypeId, singleType, 0.0, 1.0, 1.0, false, 0, "find")

	stx("setupFindPackMinterPlatform",
		WithSigner("user1"),
		WithArg("lease", "user1"),
	)

	stx("adminRegisterFindPackMetadataStruct",
		WithSigner("find-admin"),
		WithArg("info", info),
	)

	// mint a pack
	packHash := utils.CreateSha3Hash([]uint64{dandyIds[0]}, singleType, salt)

	packIdentTemplate, _ := o.QualifiedIdentifier("FindPack", "%s")

	packId, _ = stx("adminMintFindPack",
		WithSigner("find-admin"),
		WithArg("packTypeName", minter),
		WithArg("typeId", packTypeId),
		WithArg("hashes", []string{packHash}),
	).GetIdFromEvent(fmt.Sprintf(packIdentTemplate, "Deposit"), "id")

	publicPathIdentifier := "FindPack_" + minter + "_" + fmt.Sprint(packTypeId)

	stx("devaddNFTCatalog",
		WithSigner("account"),
		WithArg("collectionIdentifier", minter+" season#"+fmt.Sprint(packTypeId)),
		WithArg("contractName", fmt.Sprintf(packIdentTemplate, "NFT")),
		WithArg("contractAddress", "find"),
		WithArg("addressWithNFT", "find"),
		WithArg("nftID", packId),
		WithArg("publicPathIdentifier", publicPathIdentifier),
	)

	return nil
}

func registerFtInFTRegistry(stx OverflowTransactionFunction, alias string) {
	stx(fmt.Sprintf("adminSetFTInfo_%s", alias),
		WithSigner("find-admin"),
	)
}

func createUser(stx OverflowTransactionFunction, fusd float64, name string) {
	nameSigner := WithSigner(name)
	nameArg := WithArg("name", name)

	stx("createProfile", nameSigner, nameArg)

	stx("setProfile",
		WithSigner(name),
		WithArg("avatar", "https://find.xyz/assets/img/avatars/avatar14.png"),
	)

	for _, mintName := range []string{
		"devMintFusd",
		"devMintUsdc",
	} {
		stx(mintName, WithSigner("account"),
			WithArg("recipient", name),
			WithArg("amount", fusd),
		)
	}
}
