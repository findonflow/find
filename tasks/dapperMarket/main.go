package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(WithNetwork("mainnet"), WithGlobalPrintOptions())

	name := "onefootball"
	tenantAddress := "0x30cf5dcf6ea8d379"
	adminAddress := "0xa674ac3330d7a729"

	o.Tx("setup_find_dapper_market",
		WithSigner("find-admin"),
		WithArg("adminAddress", adminAddress),
		WithArg("tenantAddress", tenantAddress),
		WithArg("name", name),
	)

}
