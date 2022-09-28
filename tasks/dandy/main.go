package main

import (
	"fmt"

	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(WithGlobalPrintOptions(), WithExistingEmulator(), WithNetwork("mainnet"))

	adminSigner := WithSigner("find-admin")
	// nameArg := WithArg("name", "find")

	//should these two join together?

	/*
			o.Tx("adminSetAddonPrice", WithSigner("find-admin"), WithArg("addon", "forge"), WithArg("price", 50.0))
			o.Tx("buyAddon", findSigner, nameArg, WithArg("addon", "forge"), WithArg("amount", 50.0))

			o.Tx("setupDandy", findSigner, nameArg,
				WithArg("minterCut", 0.025),
				WithArg("description", ".find and dandy nfts"),
				WithArg("externalUrl", "http://find.xyz/find"),
				WithArg("squareImage", "https://pbs.twimg.com/profile_images/1467546091780550658/R1uc6dcq_400x400.jpg"),
				WithArg("bannerImage", "https://pbs.twimg.com/profile_banners/1448245049666510848/1652452073/1500x500"),
				WithArg("socials", `{ "Twitter" : "https://twitter.com/findonflow" , "Discord" : "https://discord.gg/findonflow" }`),
			)


		//delete all dandies in .finds collection

		id, err := o.Tx("adminMintFindDandy",
			findSigner,
			nameArg,
			WithArg("maxEdition", 100),
			WithArg("nftName", "Find OG Mint"),
			WithArg("nftDescription", "A collection of 100 find mints to commemorate the first ever minted NFT on the .find platform"),
			WithArg("folderHash", "QmanniNEwbfEd4eA4CiiWZR9dQkZ5wJ5WokvUfYGpTd73s"),
		).GetIdFromEvent(
			"FindForge.Minted", "id",
		)

		if err != nil {
			panic(err)
		}
	*/
	// Remove old Dandy from FIND NFT Catalog
	//panic: the interaction 'adminRemoveNFTCatalog' has the following extra arguments [addressWithNFT nftID publicPathIdentifier contractName contractAddress]

	// Add Dandy to FIND NFT Catalog
	o.Tx("adminRemoveNFTCatalog",
		adminSigner,
		WithArg("collectionIdentifier", "A.097bafa4e0b48eef.Dandy.NFT"),
	)

	o.Tx("adminAddNFTCatalog",
		adminSigner,
		WithArg("collectionIdentifier", "A.097bafa4e0b48eef.Dandy.NFT"),
		WithArg("contractName", "Dandy"),
		WithArg("contractAddress", "find"),
		WithArg("addressWithNFT", "find"),
		WithArg("nftID", 412333931),
		WithArg("publicPathIdentifier", "findDandy"),
	)

	fmt.Println("Added to NFTCatalog")
}
