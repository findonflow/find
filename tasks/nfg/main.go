package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	o := Overflow(WithGlobalPrintOptions())

	name := "nfg"
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
	o.Tx("testMintFusd", WithSignerServiceAccount(), WithArg("recipient", "user1"), WithArg("amount", 1000.0))
	o.Tx("register", nameSigner, nameArg, WithArg("amount", 500.0))
	o.Tx("buyAddon", nameSigner, nameArg, WithArg("addon", "forge"), WithArg("amount", 50.0))

	//setup NFG forge
	//LUKE: please QA this data

	o.Tx("testSetupNFG", nameSigner, nameArg,
		WithArg("minterCut", 0.075),
		WithArg("collectionDescription", "NonFunGerbils"),
		WithArg("collectionExternalURL", "http://nonfungerbils.com"),
		WithArg("collectionSquareImage", "https://find.mypinata.cloud/ipfs/QmeG1rPaLWmn4uUSjQ2Wbs7QnjxdQDyeadCGWyGwvHTB7c"),
		WithArg("collectionBannerImage", "https://find.mypinata.cloud/ipfs/QmWmDRnSrv8HK5QsiHwUNR4akK95WC8veydq6dnnFbMja1"),
		WithArg("socials", `{ "Twitter" : "https://twitter.com/NonFunGerbils" }`),
	)

	//mint NFG, this is example from the file you sent me
	o.Tx("testMintNFG",
		nameSigner,
		nameArg,
		WithArg("nftName", "The Gerbil Who Lost His Seeds"),
		WithArg("nftDescription", `#PEPEgerbil is besotted, obsessed by their precious, They cradle it, love it, perhaps it's devine. This NFT pairs with a physical painting of acrylic on canvas by Pepelangelo. Only the the owner of the physical can see what is uniquely precious.`),
		WithArg("externalURL", "https://nonfungerbils.com/pepegerbil"),
		WithArg("imageHash", "QmSaWfkeTdNbYcuU9sgG9SBsbqccVbvrX3Pd4omKgtdnUg"),
		WithArg("maxEditions", 6),
		WithArg("scalars", map[string]float64{
			"Gerbil Number": 29.0,
		}),
		WithArg("traits", map[string]string{
			"Released":      "9 August 2022",
			"Collaboration": "@Pepelangelo",
			"Story Author":  "NonFunGerbils",
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
	)
}
