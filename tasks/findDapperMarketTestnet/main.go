package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(WithNetwork("testnet"), WithGlobalPrintOptions())

	name := "find-dapper"
	// tenantAddress := "695502f4d2ccd475"
	merchAddress := "0x4748780c8bf65e19"

	// o.Tx("adminSendFlow",
	// 	WithSigner("account"),
	// 	WithArg("receiver", "find-dapper"),
	// 	WithArg("amount", 10.0),
	// )

	// o.Tx("setup_find_market_1",
	// 	WithSigner(name),
	// )

	// o.Tx("setup_find_dapper_market",
	// 	WithSigner("find-admin"),
	// 	WithArg("adminAddress", tenantAddress),
	// 	WithArg("tenantAddress", tenantAddress),
	// 	WithArg("name", "find_dapper"),
	// )

	// o.Tx("adminSetSellLeaseDapper",
	// 	WithSigner(name),
	// 	WithArg("market", "Sale"),
	// 	WithArg("merchAddress", merchAddress),
	// )

	// o.Tx("adminRemoveSetSellDapperDUC",
	// 	WithSigner(name),
	// 	WithArg("market", "Sale"),
	// )

	o.Tx("adminSetSellDapperFUT",
		WithSigner(name),
		WithArg("market", "Sale"),
		WithArg("merchAddress", merchAddress),
	)

}
