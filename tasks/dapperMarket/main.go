package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(WithNetwork("testnet"), WithGlobalPrintOptions())

	name := "onefootball"
	tenantAddress := "0x46625f59708ec2f8"
	adminAddress := "0xa92fd41dadf1bc0e"

	o.Tx("setup_find_dapper_market",
		WithSigner("find-admin"),
		WithArg("adminAddress", adminAddress),
		WithArg("tenantAddress", tenantAddress),
		WithArg("name", name),
	)

}
