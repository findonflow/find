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
	dandy, _ := o.QualifiedIdentifier("Dandy", "NFT")
	o.Tx(
		"listNFTForSale",
		WithSigner("user1"),
		WithArg("marketplace", "find"),
		WithArg("nftAliasOrIdentifier", dandy),
		WithArg("id", 100256682),
		WithArg("ftAliasOrIdentifier", "Flow"),
		WithArg("directSellPrice", 0.1),
		WithArg("validUntil", "nil"),
	)

	o.Tx(
		"buyNFTForSale",
		WithSigner("find"),
		WithArg("marketplace", "find"),
		WithArg("user", o.Address("user1")),
		WithArg("id", 100256682),
		WithArg("amount", 0.1),
	)

	// o.Script(
	// 	"getNFTCatalogIDs",
	// 	WithArg("user", "user1"),
	// 	WithArg("collections", []string{}),
	// ).
	// 	Print()

	// o.Script(
	// 	"getNFTDetailsNFTCatalog",
	// 	WithArg("user", "user1"),
	// 	WithArg("project", "dandy"),
	// 	WithArg("id", 100256682),
	// 	WithArg("views", "[]"),
	// )
}
