package main

import (
	. "github.com/bjartek/overflow"
)

func main() {
	network := "mainnet"
	o := Overflow(
		WithNetwork(network),
	)

	switch network {

	case "testnet":
		o.Tx("adminAddNFTCatalog",
			WithSigner("find-admin"),
			WithArg("collectionIdentifier", "Gaia"),
			WithArg("contractName", "Gaia"),
			WithArg("contractAddress", "0x40e47dca6a761db7"),
			WithArg("addressWithNFT", "0x8fb4a6a11757b80d"),
			WithArg("nftID", 15536),
			WithArg("publicPathIdentifier", "GaiaCollection001"),
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
