package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestMarketContract(t *testing.T) {
	/*
		User 1 : with profile and switchboard
		User 2 : with profile only
		User 3 : with switchboard only
		User 4 : with nothing

		Test cases
		1. correct and valid cap with type
		2. correct but invalid cap with type
		3. incorrect but valid cap with type
		4. incorrect and indvalid cap with type
	*/

	otu := NewOverflowTest(t).
		setupFIND()
	otu.registerFtInRegistry().
		registerDUCInRegistry()

	initSwitchboard := func(name string) {
		otu.O.Tx(
			"initSwitchboard",
			WithSigner(name),
			WithArg("dapperAddress", "dapper"),
		)
	}

	otu.createUser(1000.0, "user1").
		createUser(1000.0, "user2").
		setProfile("user1").
		setProfile("user2")

	initSwitchboard("user1")
	initSwitchboard("user3")

	type TestCase struct {
		User         string
		OutcomePath  string
		GoToResidual bool
		Description  string
	}

	type TestFrame struct {
		FTType string
		Path   string
		Case   []TestCase
	}

	tcs := []TestFrame{
		{
			FTType: "Flow",
			Path:   "/public/flowTokenReceiver",
			Case: []TestCase{
				{
					User:         "user1",
					OutcomePath:  "/public/flowTokenReceiver",
					GoToResidual: false,
					Description:  "Should deposit to flow receiver",
				},
				{
					User:         "user2",
					OutcomePath:  "/public/flowTokenReceiver",
					GoToResidual: false,
					Description:  "Should deposit to flow receiver",
				},
				{
					User:         "user3",
					OutcomePath:  "/public/flowTokenReceiver",
					GoToResidual: false,
					Description:  "Should deposit to flow receiver",
				},
				{
					User:         "user4",
					OutcomePath:  "/public/flowTokenReceiver",
					GoToResidual: false,
					Description:  "Should deposit to flow receiver",
				},
			},
		},
		{
			FTType: "FUT",
			Path:   "/public/flowUtilityTokenReceiver",
			Case: []TestCase{
				{
					User:         "user1",
					OutcomePath:  "/public/flowUtilityTokenReceiver",
					GoToResidual: false,
					Description:  "Should deposit to FUT",
				},
				{
					User:         "user2",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: true,
					Description:  "Should deposit to residual FUT because FUT is not set up",
				},
				{
					User:         "user3",
					OutcomePath:  "/public/flowUtilityTokenReceiver",
					GoToResidual: false,
					Description:  "Should deposit to FUT",
				},
				{
					User:         "user4",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: true,
					Description:  "Should deposit to residual FUT because FUT is not set up",
				},
			},
		},
		{
			FTType: "Flow",
			Path:   "/public/findProfileReceiver",
			Case: []TestCase{
				{
					User:         "user1",
					OutcomePath:  "/public/findProfileReceiver",
					GoToResidual: false,
					Description:  "Should deposit to find profile link",
				},
				{
					User:         "user2",
					OutcomePath:  "/public/findProfileReceiver",
					GoToResidual: false,
					Description:  "Should deposit to find profile link",
				},
				{
					User:         "user3",
					OutcomePath:  "/public/flowTokenReceiver",
					GoToResidual: false,
					Description:  "Should deposit to flow receiver because profile is not set",
				},
				{
					User:         "user4",
					OutcomePath:  "/public/flowTokenReceiver",
					GoToResidual: false,
					Description:  "Should deposit to flow receiver because profile is not set",
				},
			},
		},
		{
			FTType: "USDC",
			Path:   "/public/findProfileReceiver",
			Case: []TestCase{
				{
					User:         "user1",
					OutcomePath:  "/public/findProfileReceiver",
					GoToResidual: false,
					Description:  "Should deposit to find profile link",
				},
				{
					User:         "user2",
					OutcomePath:  "/public/findProfileReceiver",
					GoToResidual: false,
					Description:  "Should deposit to find profile link",
				},
				{
					User:         "user3",
					OutcomePath:  "/public/USDCVaultReceiver",
					GoToResidual: false,
					Description:  "Should deposit to residual because USDC is not set up",
				},
				{
					User:         "user4",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: true,
					Description:  "Should deposit to residual because USDC is not set up",
				},
			},
		},
		{
			FTType: "FUT",
			Path:   "/public/GenericFTReceiver",
			Case: []TestCase{
				{
					User:         "user1",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: false,
					Description:  "Should deposit to switchboard because FT forwarder is set",
				},
				{
					User:         "user2",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: true,
					Description:  "Should deposit to residual because FUT is not set up",
				},
				{
					User:         "user3",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: false,
					Description:  "Should deposit to switchboard because FT forwarder is set",
				},
				{
					User:         "user4",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: true,
					Description:  "Should deposit to residual because FUT is not set up",
				},
			},
		},
		{
			FTType: "Flow",
			Path:   "/public/GenericFTReceiver",
			Case: []TestCase{
				{
					User:         "user1",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: false,
					Description:  "Should deposit to switchboard link",
				},
				{
					User:         "user2",
					OutcomePath:  "/public/flowTokenReceiver",
					GoToResidual: false,
					Description:  "Should deposit to flow receiver because switchboard is not set",
				},
				{
					User:         "user3",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: false,
					Description:  "Should deposit to switchboard link",
				},
				{
					User:         "user4",
					OutcomePath:  "/public/flowTokenReceiver",
					GoToResidual: false,
					Description:  "Should deposit to flow receiver because switchboard is not set",
				},
			},
		},
		{
			FTType: "USDC",
			Path:   "/public/GenericFTReceiver",
			Case: []TestCase{
				{
					User:         "user1",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: false,
					Description:  "Should deposit to switchboard link",
				},
				{
					User:         "user2",
					OutcomePath:  "/public/USDCVaultReceiver",
					GoToResidual: false,
					Description:  "Should deposit to USDC receiver because switchboard is not set",
				},
				{
					User:         "user3",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: false,
					Description:  "Should deposit to switchboard link",
				},
				{
					User:         "user4",
					OutcomePath:  "/public/GenericFTReceiver",
					GoToResidual: true,
					Description:  "Should deposit to residual because USDC is not set up",
				},
			},
		},
	}

	trx := `
		import Dev from "../contracts/Dev.cdc"
		import FindMarket from "../contracts/FindMarket.cdc"
		import FungibleToken from "../contracts/standard/FungibleToken.cdc"

		access(all) fun main(addr: Address, ftType: String, path: PublicPath, outcomeRefPath: PublicPath, goToResidual: Bool) : Bool {
			let ref = Dev.getPaymentWallet(addr: addr, ftType: ftType, path: path, panicOnFailCheck: false)
			var account = getAccount(addr)
			if goToResidual {
				account = getAccount(FindMarket.residualAddress)
			}
			let outcomeRef = account.getCapability<&{FungibleToken.Receiver}>(outcomeRefPath).borrow()!
			if ref.uuid == outcomeRef.uuid {
				return true
			}
			let msg = "The fund is expected by test go to ".concat(outcomeRef.owner!.address.toString()).concat(" ").concat(outcomeRef.getType().identifier).concat(" But the fund went to ").concat(ref.owner!.address.toString()).concat(" ").concat(ref.getType().identifier)
			panic(msg)
		}
	`

	for testFrameIndex, tf := range tcs {
		for testCaseIndex, tc := range tf.Case {
			t.Run(fmt.Sprintf("TestFrameIndex:%d,TestCaseIndex:%d,description:Fund for %s %s", testFrameIndex, testCaseIndex, tc.User, tc.Description), func(t *testing.T) {
				res, err := otu.O.Script(
					trx,
					WithArg("addr", tc.User),
					WithArg("ftType", tf.FTType),
					WithArg("path", tf.Path),
					WithArg("outcomeRefPath", tc.OutcomePath),
					WithArg("goToResidual", tc.GoToResidual),
				).
					GetAsInterface()
				status, ok := res.(bool)
				require.NoError(otu.T, err)
				assert.True(otu.T, ok)
				assert.Truef(otu.T, status, fmt.Sprintf("[TestFailed] TestFrameIndex : %d, TestCase no: %d, description: Fund for %s %s", testFrameIndex, testCaseIndex, tc.User, tc.Description))
			})
		}
	}
}
