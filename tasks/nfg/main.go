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

	//setnup NFG
	o.Tx("createProfile", nameSigner, nameArg)
	o.Tx("testMintFusd", WithSignerServiceAccount(), WithArg("recipient", name), WithArg("amount", 1000))
	o.Tx("register", nameSigner, nameArg, WithArg("amount", 500.0))
	o.Tx("buyAddon", nameSigner, nameArg, WithArg("addon", "forge"), WithArg("amount", 50.0))

	//setup NFG forge
	//LUKE: please QA this data
	o.Tx("testSetupNFG", findSigner, nameArg,
		WithArg("minterCut", 0.025),
		WithArg("description", "NFG"),
		WithArg("externalUrl", "http://nonfungerbils.com"),
		WithArg("squareImage", "https://lukus.cc/index.php/s/TbMc5Z4qQxjoG8s"),
		WithArg("bannerImage", "https://lukus.cc/index.php/s/GaAo2HLscfFrNwy"),
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

		//LUKE: Gerbil number can be a numeric trait here easily that way in our market you could filter on them using a slider.
		WithArg("traits", map[string]string{
			"Gerbil Number": "28",              //this could be stored as a numeric trait and not text so you can compare on it
			"Scarcity":      "14",              //is this max number mitned? if it is we should not have it as trait but exposed as a Edition
			"Released":      "14 January 2022", //we could have this as a unix timestamp and mark it as a date so you can compare on it?
			"Collaboration": "@songadaymann",   //we could do a twitter display type here maybe
			"Story Author":  "@Small_Time_Bets",
		}),
		WithArg("birthday", 1653427403.0),
		WithArg("values", map[string]float64{
			"Cuddles":         66,
			"Top Wheel Speed": 31,
			"Battle Squak":    19,
			"Degen":           80,
			"Maximalism":      39,
			"Funds are Safu":  1,
		}),
	)
}
