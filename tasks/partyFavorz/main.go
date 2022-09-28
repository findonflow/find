package main

import (
	. "github.com/bjartek/overflow"
	"github.com/onflow/cadence"
)

func main() {

	o := Overflow(WithGlobalPrintOptions())

	name := "partyfavorz"
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

	//setup Party Favorz
	o.Tx("createProfile", nameSigner, nameArg)
	o.Tx("testMintFusd", WithSignerServiceAccount(), WithArg("recipient", "user1"), WithArg("amount", 1000.0))
	o.Tx("register", nameSigner, nameArg, WithArg("amount", 5.0))

	o.Tx("adminAddForge",
		findSigner,
		WithArg("type", "A.045a1763c93006ca.PartyFavorz.Forge"),
		WithArg("name", name),
	)

	o.Tx("buyAddon", nameSigner, nameArg, WithArg("addon", "forge"), WithArg("amount", 50.0))

	o.Tx("testSetupPartyFavorz", nameSigner, nameArg,
		WithArg("minterCut", 0.075),
		WithArg("collectionDescription", "Party Favorz are born to celebrate the first ever official NFTDay by Dapper on Sept 20, 2022, there are totall of 1000. 3 types of arts and each with 333 editions. So YES, there will be a 1 of 1 germ in it :P"),
		WithArg("collectionExternalURL", "http://find.xyz/"),
		WithArg("collectionSquareImage", "test"),
		WithArg("collectionBannerImage", "test"),
		WithArg("socials", `{ 
			"Twitter" : "https://twitter.com/findonflow" ,
			"Discord" : "https://discord.gg/8F49VKJpz3" 
			}`),
	)
	description := `Party Favorz are born to celebrate the first ever official NFTDay by Dapper on Sept 20, 2022`

	desc, err := cadence.NewString(description)
	if err != nil {
		panic(err)
	}

	//mint PartyFavorz

	id, err := o.Tx("testMintPartyFavorz",
		nameSigner,
		nameArg,
		WithArg("nftName", "Party Favorz"),
		WithArg("nftDescription", desc),
		WithArg("imageHash", "QmbGVd9281kdD65wdD8QRqLzXN56KCgvBB4HySQuv24rmC"),
		WithArg("maxEditions", 6),
	).
		GetIdFromEvent("Minted", "id")

	if err != nil {
		panic(err)
	}

	o.Tx("adminAddNFTCatalog",
		WithSigner("find"),
		WithArg("collectionIdentifier", "PartyFavorz"),
		WithArg("contractName", "PartyFavorz"),
		WithArg("contractAddress", "user4"),
		WithArg("addressWithNFT", "user1"),
		WithArg("nftID", id),
		WithArg("publicPathIdentifier", "PartyFavorzCollection"),
	)

	o.Script("getNFTDetailsNFTCatalog",
		WithArg("user", name),
		WithArg("project", "A.045a1763c93006ca.PartyFavorz.NFT"),
		WithArg("id", id),
		WithArg("views", "[]"),
	)

}
