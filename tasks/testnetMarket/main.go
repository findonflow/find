package main

import (
	. "github.com/bjartek/overflow"
)

func main() {
	adminSigner := WithSigner("find")

	o := Overflow(
		WithNetwork("testnet"),
		WithGlobalPrintOptions(),
	)

	id, err := o.QualifiedIdentifier("FIND", "Lease")
	if err != nil {
		panic(err)
	}

	upsertItem := o.TxFN(
		adminSigner,
		WithArg("cut", 0.0),
	)
	upsertItem(
		"tenantsetLeaseOptionMarket",
		WithArg("nftName", "Lease"), // primary key
		WithArg("nftType", id),
	)
}
