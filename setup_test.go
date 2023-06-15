package test_main

import (
	"fmt"
	"os"
	"strings"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/findonflow/find/findGo"
)

// we set the shared overflow test struct that will reset to known setup state after each test
var ot *OverflowTest

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

	//link in the server in the versus client
	stx("setup_fin_2_register_client",
		findSigner,
		WithArg("ownerAddress", "find-admin"),
	)

	//set up fin network as the fin user
	stx("setup_fin_3_create_network", findAdminSigner)

	stx("setup_find_market_1_dapper",
		findSigner,
		WithArg("dapperAddress", "dapper"),
	)

	//link in the server in the versus client
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

	createUser(stx, 100.0, "find")

	//link in the server in the versus client
	stx("devSetResidualAddress",
		findAdminSigner,
		WithArg("address", "residual"),
	)

	stx(
		"initSwitchboard",
		WithSigner("residual"),
		WithArg("dapperAddress", "dapper"),
	)

	// setup find forge
	stx("setup_find_forge_1", WithSigner("find-forge"))

	//link in the server in the versus client
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

	//	otu.registerDandyInNFTRegistry()

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
