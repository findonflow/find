package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(WithNetwork("mainnet"), WithGlobalPrintOptions())

	name := "find-dapper"
	// merchAddress := "0x55459409d30274ee"

	o.Tx("adminSendFlow",
		WithSigner("find"),
		WithArg("receiver", "find-dapper"),
		WithArg("amount", 0.1),
	)

	o.Tx("createProfile",
		WithSigner(name),
		WithArg("name", "find-dapper"),
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

	// o.Tx("adminSetSellLeaseDapper",
	// 	WithSigner(name),
	// 	WithArg("market", "Sale"),
	// 	WithArg("merchAddress", merchAddress),
	// )

	// o.Tx("adminRemoveSetSellDapperDUC",
	// 	WithSigner(name),
	// 	WithArg("market", "Sale"),
	// )

	// o.Tx("adminSetSellDapperFUT",
	// 	WithSigner(name),
	// 	WithArg("market", "Sale"),
	// 	WithArg("merchAddress", merchAddress),
	// )

}
