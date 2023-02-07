package findGo

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/stretchr/testify/assert"
)

type OverflowUtils struct {
	T *testing.T
	O *OverflowState
}

func (ot *OverflowUtils) upgradeFindDapperTenantSwitchboard() *OverflowUtils {

	o := ot.O
	findCut := 0.025
	tenantCut := 0.00
	infrastructureCut := []FindMarketCutStruct_ThresholdCut{
		{
			Name:           "dapper",
			Address:        o.Address("dapper"),
			Cut:            0.01,
			Description:    "Dapper takes 0.01% or 0.44 dollars, whichever is higher",
			PublicPath:     "dapperUtilityCoinReceiver",
			MinimumPayment: 0.44,
		},
	}

	name := "dapper"
	merchAddress := "0x01cf0e2f2f715450"
	switch o.Network {
	case "testnet":
		merchAddress = "0x4748780c8bf65e19"
		name = "find-dapper"

	case "mainnet":
		merchAddress = "0x55459409d30274ee"
		name = "find-dapper"
	}

	// setup switchboard for tenant
	res := o.Tx(
		"initSwitchboard",
		WithSigner(name),
		WithArg("dapperAddress", merchAddress),
	)
	ot.assertTrxn(res)

	// setup switchboard for find
	res = o.Tx(
		"initSwitchboard",
		WithSigner("find"),
		WithArg("dapperAddress", merchAddress),
	)
	ot.assertTrxn(res)

	res = o.Tx(
		"adminsetupSwitchboardCut",
		WithSigner("find-admin"),
		WithArg("tenant", name),
	)
	ot.assertTrxn(res)

	res = o.Tx("adminSetFindCut",
		WithSigner("find-admin"),
		WithArg("tenant", name),
		WithArg("cut", findCut),
	)
	ot.assertTrxn(res)

	wearable, err := o.QualifiedIdentifier("Wearables", "NFT")
	ot.assertErr(err)
	res = o.Tx("tenantsetMarketOptionDapper",
		WithSigner(name),
		WithArg("nftName", "Wearables"),
		WithArg("nftType", wearable),
		WithArg("cut", tenantCut),
	)
	ot.assertTrxn(res)

	lease, err := o.QualifiedIdentifier("FIND", "Lease")
	ot.assertErr(err)
	res = o.Tx("tenantsetMarketOptionDUC",
		WithSigner(name),
		WithArg("nftName", "Lease"),
		WithArg("nftType", lease),
		WithArg("cut", tenantCut),
	)
	ot.assertTrxn(res)

	dapper, err := o.QualifiedIdentifier("DapperUtilityCoin", "Vault")
	ot.assertErr(err)
	res = ot.O.Tx(
		"tenantsetExtraCut",
		WithSigner(name),
		WithArg("ftTypes", []string{dapper}),
		WithArg("category", "infrastructure"),
		WithArg("cuts", infrastructureCut),
	)
	ot.assertTrxn(res)

	return ot
}

func (ot *OverflowUtils) assertErr(err error) *OverflowUtils {
	testing := false
	if ot.T != nil {
		testing = true
	}
	if testing {
		assert.NoError(ot.T, err)
	} else {
		panic(err)
	}
	return ot
}

func (ot *OverflowUtils) assertTrxn(res *OverflowResult) *OverflowUtils {
	testing := false
	if ot.T != nil {
		testing = true
	}
	if testing {
		res.AssertSuccess(ot.T)
	} else {
		if res.Err != nil {
			panic(res.Err)
		}
	}
	return ot
}
