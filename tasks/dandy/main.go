package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(WithNetwork("mainnet"), WithGlobalPrintOptions())

	findSigner := WithSigner("find")
	nameArg := WithArg("name", "find")

	//should these two join together?
	o.Tx("buyAddon", findSigner, nameArg, WithArg("addon", "forge"), WithArg("amount", 50.0))
	o.Tx("setupDandy", findSigner, nameArg,
		WithArg("minterCut", 0.025),
		WithArg("description", ".find and dandy nfts"),
		WithArg("externalURL", "http://find.xyz/find"),
		WithArg("squareImage", "https://pbs.twimg.com/profile_images/1467546091780550658/R1uc6dcq_400x400.jpg"),
		WithArg("bannerImage", "https://pbs.twimg.com/profile_banners/1448245049666510848/1652452073/1500x500"),
		WithArg("socials", `{ "Twitter" : "https://twitter.com/findonflow" , "Discord" : "https://discord.gg/95P274mayM" }`),
	)

	id, err := o.Tx("adminMintFindDandy",
		findSigner,
		nameArg,
		WithArg("maxEdition", 100),
		WithArg("nftName", "Find OG Mint"),
		WithArg("nftDescription", "A collection of 100 find mints to commemorate the first ever minted NFT on the .find platform"),
		WithArg("nftImage", "https://cdn.discordapp.com/attachments/870316419521335356/1004130351020523560/find1500.jpg"),
	).GetIdFromEvent(
		"Minted", "id",
	)

	if err != nil {
		panic(err)
	}

	// Add Dandy to FIND NFT Catalog
	o.Tx("adminAddNFTCatalog",
		findSigner,
		WithArg("collectionIdentifier", "A.35717efbbce11c74.Dandy.NFT"),
		WithArg("contractName", "Dandy"),
		WithArg("contractAddress", "find"),
		WithArg("addressWithNFT", "find"),
		WithArg("nftID", id),
		WithArg("publicPathIdentifier", "findDandy"),
	)

}

/*
				//first step create the adminClient as the fin user
				g.TransactionFromFile("setup_fin_1_create_client").
					SignProposeAndPayAs("find-admin").
					RunPrintEventsFull()

			//link in the server in the versus client
			o.TransactionFromFile("setup_fin_2_register_client").
				SignProposeAndPayAs("find").
				Args(o.Arguments().Account("find-admin")).
				RunPrintEventsFull()

					//set up fin network as the fin user
					g.TransactionFromFile("setup_fin_3_create_network").
						SignProposeAndPayAs("find-admin").
						RunPrintEventsFull()

			o.TransactionFromFile("createProfile").
				SignProposeAndPayAs("find").
				Args(o.Arguments().String("find")).
				RunPrintEventsFull()

			findLinks := cadence.NewArray([]cadence.Value{
				cadence.NewDictionary([]cadence.KeyValuePair{
					{Key: NewCadenceSting("title"), Value: NewCadenceSting("twitter")},
					{Key: NewCadenceSting("type"), Value: NewCadenceSting("twitter")},
					{Key: NewCadenceSting("url"), Value: NewCadenceSting("https://twitter.com/findonflow")},
				})})

			o.TransactionFromFile("createProfile").
				SignProposeAndPayAs("find-admin").
				Args(o.Arguments().String("ReservedNames")).
				RunPrintEventsFull()

			o.TransactionFromFile("editProfile").
				SignProposeAndPayAs("find-admin").
				Args(o.Arguments().
					String("ReservedFindNames").
					String(`The names owned by this profile are reservd by .find. In order to aquire a name here you have to:

		Prices:
		 - 3 letter name  500 FUSD
		 - 4 letter name  100 FUSD
		 - 5+ letter name   5 FUSD

		1. make an offer for that name with the correct price (see above)
		2. go into the find discord and let the mods know you have made the bid

		`).
					String("https://find.xyz/find.png").
					StringArray("find").
					Boolean(false).
					Argument(findLinks)).
				RunPrintEventsFull()

			o.TransactionFromFile("editProfile").
				SignProposeAndPayAs("find").
				Args(o.Arguments().
					String("find").
					String(`.find will allow you to find people and NFTS on flow!`).
					String("https://find.xyz/find.png").
					StringArray("find").
					Boolean(true).
					Argument(findLinks)).
				RunPrintEventsFull()

			o.TransactionFromFile("registerAdmin").
				SignProposeAndPayAs("find-admin").
				Args(o.Arguments().StringArray("find").Account("find")).
				RunPrintEventsFull()

			o.TransactionFromFile("registerAdmin").
				SignProposeAndPayAs("find-admin").
				Args(o.Arguments().StringArray("reserved-names").Account("find-admin")).
				RunPrintEventsFull()

}
*/
