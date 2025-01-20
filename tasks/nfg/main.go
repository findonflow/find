package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(WithGlobalPrintOptions())

	name := "nonfungerbils"
	findSigner := WithSigner("find")
	nameSigner := WithSigner("user1")
	nameArg := WithArg("name", name)
	saSigner := WithSignerServiceAccount()

	//setup find
	o.Tx("setup_fin_1_create_client", findSigner)
	o.Tx("setup_fin_2_register_client", saSigner, WithArg("ownerAddress", "find"))
	o.Tx("setup_fin_3_create_network", findSigner)
	o.Tx("setup_find_market_1", saSigner)
	o.Tx("setup_find_market_2", findSigner, WithArg("tenantAddress", "account"))
	o.Tx("setup_find_market_1", WithSigner("user4"))
	o.Tx("setup_find_lease_market_2", WithSigner("find"), WithArg("tenantAddress", "user4"))

	//setnup NFG
	o.Tx("createProfile", nameSigner, nameArg)
	o.Tx("devMintFusd", WithSignerServiceAccount(), WithArg("recipient", "user1"), WithArg("amount", 1000.0))
	o.Tx("register", nameSigner, nameArg, WithArg("amount", 5.0))

	o.Tx("adminAddForge",
		findSigner,
		WithArg("type", "A.045a1763c93006ca.NFGv3.Forge"),
		WithArg("name", name),
	)

	o.Tx("luke", nameSigner)
	/*
		o.Tx("buyAddon", nameSigner, nameArg, WithArg("addon", "forge"), WithArg("amount", 50.0))

		o.Tx("devSetupNFG", nameSigner, nameArg,
			WithArg("minterCut", 0.075),
			WithArg("collectionDescription", "NonFunGerbils"),
			WithArg("collectionExternalURL", "http://nonfungerbils.com"),
			WithArg("collectionSquareImage", "https://find.mypinata.cloud/ipfs/QmeG1rPaLWmn4uUSjQ2Wbs7QnjxdQDyeadCGWyGwvHTB7c"),
			WithArg("collectionBannerImage", "https://find.mypinata.cloud/ipfs/QmWmDRnSrv8HK5QsiHwUNR4akK95WC8veydq6dnnFbMja1"),
			WithArg("socials", `{ "Twitter" : "https://twitter.com/NonFunGerbils" }`),
		)
		description := `#PEPEgerbil is besotted, obsessed by their precious, They cradle it, love it, perhaps it's devine.\n\nThis NFT pairs with a physical painting of mixed technique on canvas, size 24x30cm by Pepelangelo.\n\n Only the owner of the physical can see what is uniquely precious.`

		desc, err := cadence.NewString(description)
		if err != nil {
			panic(err)
		}

		//mint NFG, this is example from the file you sent me

		o.Tx("devMintNFG",
			nameSigner,
			nameArg,
			WithArg("nftName", "Pepe Gerbil"),
			WithArg("nftDescription", desc),
			WithArg("externalURL", "https://nonfungerbils.com/pepegerbil"),
			WithArg("imageHash", "QmbGVd9281kdD65wdD8QRqLzXN56KCgvBB4HySQuv24rmC"),
			WithArg("maxEditions", 6),
			WithArg("scalars", map[string]float64{
				"Gerbil Number": 29.0,
			}),
			WithArg("traits", map[string]string{
				"Released":     "9 August 2022",
				"Artist":       "@Pepelangelo",
				"Story Author": "NonFunGerbils",
			}),
			WithArg("birthday", 1653427403.0),
			WithArg("levels", map[string]float64{
				"Cuddles":         14,
				"Top Wheel Speed": 21,
				"Battle Squak":    78,
				"Degen":           92,
				"Maximalism":      64,
				"Funds are Safu":  70,
			}),
			WithArg("medias", "{}"),
		)
	*/
}
