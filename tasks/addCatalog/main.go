package main

import (
	. "github.com/bjartek/overflow"
)

func main() {
	network := "testnet"
	o := Overflow(
		WithNetwork(network),
	)

	switch network {

	case "testnet":
		o.Tx("adminAddNFTCatalog",
			WithSigner("find-admin"),
			WithArg("collectionIdentifier", "NameVoucher"),
			WithArg("contractName", "NameVoucher"),
			WithArg("contractAddress", "0x35717efbbce11c74"),
			WithArg("addressWithNFT", "0x35717efbbce11c74"),
			WithArg("nftID", 138511757),
			WithArg("publicPathIdentifier", "nameVoucher"),
		).
			Print()

	case "mainnet":
		o.Tx("adminAddNFTCatalog",
			WithSigner("find-admin"),
			WithArg("collectionIdentifier", "Gaia"),
			WithArg("contractName", "Gaia"),
			WithArg("contractAddress", "8b148183c28ff88f"),
			WithArg("addressWithNFT", "0x886f3aeaf848c535"),
			WithArg("nftID", 8782),
			WithArg("publicPathIdentifier", "GaiaCollection001"),
		).
			Print()
	}

}
