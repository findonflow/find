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
		WithArg("nftDescription", `Gary the gerbil loved collecting, Mommy said that was the gerbil way, In the metaverse Gary started connecting, To many other gerbils who did this all day. First punks, then apes, then a fuckin' troll, Before long, his collection was out of control. He remembered his mommy and those words she had said, 'Don't spill your seed for anyone, lose them and you're dead'. Gary thought he knew better, he was a degen after all, He'd stored his seeds somewhere, he knew where, he was sure, Then winter came and when it had thawed, He looked for his seeds where he thought they were stored. Oh no, they were gone. He did not know why, Other gerbils knew Gary was NGMI.`),
		WithArg("externalURL", "https://nonfungerbils.com/ngmigerbil"),
		WithArg("nftUrl", "https://24msu6bcjhfoi4fztsmgfa4thctgmjo262jhkm3x3ciqpjv2.arweave.net/_1xkqeCJJyuRwuZyYYoOTOKZmJdr2knUzd9iRB6a-6A"),
		WithArg("maxEditions", 14),
		WithArg("scalars", map[string]float64{
			"Gerbil Number": 28.0, //this could be stored as a numeric trait and not text so you can compare on it
		}),
		//LUKE: Gerbil number can be a numeric trait here easily that way in our market you could filter on them using a slider.
		WithArg("traits", map[string]string{
			"Released":      "14 January 2022", //we could have this as a unix timestamp and mark it as a date so you can compare on it?
			"Collaboration": "@songadaymann",   //we could do a twitter display type here maybe
			"Story Author":  "@Small_Time_Bets",
		}),
		WithArg("birthday", 1653427403.0),
		WithArg("levels", map[string]float64{
			"Cuddles":         66,
			"Top Wheel Speed": 31,
			"Battle Squak":    19,
			"Degen":           80,
			"Maximalism":      39,
			"Funds are Safu":  1,
		}),
	)
}
