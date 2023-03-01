package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(WithNetwork("testnet"), WithGlobalPrintOptions())

	// ot := findGo.OverflowUtils{
	// 	O: o,
	// }

	// ot.UpgradeFindDapperTenantSwitchboard()
	// 100256682

	list := map[string]string{
		"Dandy":    "A.35717efbbce11c74.Dandy.NFT",
		"Beam":     "A.6085ae87e78e1433.Beam.NFT",
		"FLovatar": "A.9392a4a7c3f49a0b.Flovatar.NFT",
		"Bl0x":     "A.e8124d8428980aa6.Bl0x.NFT",
		"Versus":   "A.99ca04281098b33d.Art.NFT",
	}

	for key, val := range list {

		o.Tx(
			"tenantsetMarketOption",
			WithSigner("find"),
			WithArg("nftName", key),
			WithArg("nftTypes", []string{val}),
			WithArg("cut", 0.0),
		)
	}

}
