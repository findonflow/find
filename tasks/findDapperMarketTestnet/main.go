package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(WithNetwork("testnet"), WithGlobalPrintOptions())

	coin := "FUT"
	findCut := 0.025
	tenantCut := 0.01

	name := "dapper"
	merchAddress := "0x01cf0e2f2f715450"
	switch o.Network {
	case "testnet":
		merchAddress = "0x4748780c8bf65e19"
		name = "find-dapper"

		o.Tx(
			"remove_find_market_1",
			WithSigner("find-admin"),
			WithArg("tenant", name),
		)

		o.Tx(
			"remove_find_market_2",
			WithSigner(name),
		)

	case "mainnet":
		merchAddress = "0x55459409d30274ee"
		name = "find-dapper"
	}

	o.Tx("adminSendFlow",
		WithSigner("find"),
		WithArg("receiver", name),
		WithArg("amount", 0.1),
	)

	o.Tx("createProfile",
		WithSigner(name),
		WithArg("name", name),
	)

	o.Tx("setup_find_market_1",
		WithSigner(name),
	)

	o.Tx("setup_find_dapper_market",
		WithSigner("find-admin"),
		WithArg("adminAddress", name),
		WithArg("tenantAddress", name),
		WithArg("name", "find_dapper"),
	)

	o.Tx("adminAddFindCutDapper",
		WithSigner("find-admin"),
		WithArg("tenant", name),
		WithArg("merchAddress", merchAddress),
		WithArg("findCut", findCut),
	)

	if coin == "DUC" {
		o.Tx("adminSetSellDapperDUC",
			WithSigner(name),
			WithArg("market", "Sale"),
			WithArg("merchAddress", merchAddress),
			WithArg("tenantCut", tenantCut),
		)
	}
	if coin == "FUT" {
		o.Tx("adminSetSellDapperFUT",
			WithSigner(name),
			WithArg("market", "Sale"),
			WithArg("merchAddress", merchAddress),
			WithArg("tenantCut", tenantCut),
		)
	}

}
