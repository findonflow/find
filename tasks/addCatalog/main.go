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
			WithArg("collectionIdentifier", "GeneratedExperiences"),
			WithArg("contractName", "GeneratedExperiences"),
			WithArg("contractAddress", "0x123cb666996b8432"),
			WithArg("addressWithNFT", "0x09a86f2493ce2e9d"),
			WithArg("nftID", 1011239371),
			WithArg("publicPathIdentifier", "GeneratedExperiences"),
		).
			Print()
	}

}
