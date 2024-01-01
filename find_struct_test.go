package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/findonflow/find/findGo"
)

func TestFindStruct(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	ot.Run(t, "Should be able to pass in Royalty Struct", func(t *testing.T) {
		otu.O.Tx(
			`
				import FindPack from "../contracts/FindPack.cdc"

				transaction(i: FindPack.Royalty) {}
			`,
			WithSigner("find-admin"),
			WithArg("i", findGo.FindPack_Royalty{
				Recipient:   otu.O.Address("find-admin"),
				Cut:         0.01,
				Description: "",
				Extra:       map[string]interface{}{},
			}),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should be able to pass in Verifier Struct", func(t *testing.T) {
		otu.O.Tx(
			`
			import FindVerifier from "../contracts/FindVerifier.cdc"

			transaction(i: {FindVerifier.Verifier}) {}
			`,
			WithSigner("find-admin"),
			WithArg("i", findGo.FindVerifier_HasOneFLOAT{
				FloatEventIds: []uint64{},
				Description:   "",
			}),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should be able to pass in PackRegisterSaleInfo Struct", func(t *testing.T) {
		otu.O.Tx(
			`
			import FindPack from "../contracts/FindPack.cdc"

			transaction(i: FindPack.PackRegisterSaleInfo) {}
			`,
			WithSigner("find-admin"),
			WithArg("i", findGo.FindPack_PackRegisterSaleInfo{
				Name:      "feownfew",
				StartTime: 0.01,
				Price:     0.01,
				Verifiers: []findGo.FindVerifier_HasOneFLOAT{
					{
						FloatEventIds: []uint64{},
						Description:   "",
					},
				},
			}),
		).
			AssertSuccess(t)
	})

	ot.Run(t, "Should be able to pass in PackRegisterInfo Struct", func(t *testing.T) {
		otu.O.Tx(
			`
			import FindPack from "../contracts/FindPack.cdc"

			transaction(i: FindPack.PackRegisterInfo) {}
			`,
			WithSigner("find-admin"),
			WithArg("i", findGo.FindPack_PackRegisterInfo{
				Name: "feownfew",
			}),
		).
			AssertSuccess(t)
	})
}
