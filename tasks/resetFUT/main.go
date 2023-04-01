package main

import (
	. "github.com/bjartek/overflow"
)

func main() {
	network := "mainnet"
	o := Overflow(
		WithNetwork(network),
	)

	o.Tx("adminRemoveFTInfoByAlias",
		WithSigner("find-admin"),
		WithArg("alias", "FUT"),
	).
		Print()

	o.Tx("adminSetFTInfo_fut",
		WithSigner("find-admin"),
	).
		Print()

}
