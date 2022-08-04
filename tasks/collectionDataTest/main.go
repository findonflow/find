package main

import (
	. "github.com/bjartek/overflow"
)

func main() {

	// o2 := overflow.NewOverflowMainnet().Start()

	//pub fun main(user: String, nftAliasOrIdentifier:String, id: UInt64, views: [String]) : NFTDetailReport?{
	// res3 := o2.ScriptFromFile("getNFTDetailsNFTCatalog").NamedArguments(map[string]string{
	// 	"user":                 "christian",
	// 	"nftAliasOrIdentifier": "Dandy",
	// 	"id":                   "97168801",
	// 	"views":                `["A.631e88ae7f1d7c20.MetadataViews.NFTCollectionData"]`,
	// }).RunReturnsJsonString()

	// res3 := o2.ScriptFromFile("getFactoryCollectionsNFTCatalog").NamedArguments(map[string]string{
	// 	"user":        "bjartek",
	// 	"maxItems":    "5",
	// 	"collections": `[]`,
	// }).RunReturnsJsonString()

	// fmt.Println(res3)

	network := "mainnet"

	o := Overflow(
		WithNetwork(network),
	)

	// name: String, id: UInt64, nftAliasOrIdentifier: String, viewIdentifier: String

	o.Script("getCheckRoyalty",
		WithArg("name", "alxo"),
		WithArg("id", "2"),
		WithArg("nftAliasOrIdentifier", "A.d796ff17107bbff6.Art.NFT"),
		WithArg("viewIdentifier", "A.1d7e57aa55817448.MetadataViews.Royalties"),
	)

	// Starly flow
	// Momentables flow

	// 	a := `{"A.5b82f21c0edf76e3.StarlyCard.NFT": {"Starly": true},
	// "A.d796ff17107bbff6.Art.NFT": {"Versus": true},
	// "A.7c8995e83c4b1843.Collector.NFT": {"CuveeCollectiveCollector": true},
	// "A.766b859539a6679b.StoreFront.NFT": {"StoreFrontTR": true},
	// "A.807c3d470888cc48.Backpack.NFT": {"Backpack": true},
	// "A.33f44e504a396ba7.SkyharborNFT.NFT": {"TheSkyharborCollection": true},
	// "A.9d21537544d9123d.Momentables.NFT": {"Momentables": true},
	// "A.097bafa4e0b48eef.Dandy.NFT": {"A.097bafa4e0b48eef.Dandy.NFT": true},
	// "A.921ea449dffec68a.FlovatarComponent.NFT": {"FlovatarComponent": true},
	// "A.097bafa4e0b48eef.CharityNFT.NFT": {"NeoCharity2021": true},
	// "A.6c4fe48768523577.SchmoesPreLaunchToken.NFT": {"schmoes_prelaunch_token": true},
	// "A.7620acf6d7f2468a.Bl0x.NFT": {"bl0x": true},
	// "A.f2af175e411dfff8.MetaPanda.NFT": {"MetaPanda": true},
	// "A.921ea449dffec68a.Flovatar.NFT": {"Flovatar": true}}`

	// suffix := network

	// script := "getFactoryCollections"

	// prefix := "RaribleNFT"
	// o.Script(suffix+script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("maxItems", "2"),
	// 	WithArg("collections", "[]"),
	// )

	// prefix = "Shard1"
	// o.Script(suffix+script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("maxItems", "2"),
	// 	WithArg("collections", "[]"),
	// )

	// prefix = "Shard2"
	// o.Script(suffix+script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("maxItems", "2"),
	// 	WithArg("collections", "[]"),
	// )

	// prefix = "Shard3"
	// o.Script(suffix+script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("maxItems", "2"),
	// 	WithArg("collections", "[]"),
	// )

	// prefix = "Shard4"
	// o.Script(suffix+script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("maxItems", "10"),
	// 	WithArg("collections", "[]"),
	// )

	// prefix = "NFTCatalog"
	// o.Script(script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("maxItems", "2"),
	// 	WithArg("collections", "[]"),
	// )

	// // get NFTDetail script
	// script = "getNFTDetails"

	// prefix = "RaribleNFT"
	// o.Script(suffix+script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("project", "Flowverse Socks"),
	// 	WithArg("id", 14939),
	// 	WithArg("views", "[]"),
	// )

	// prefix = "Shard1"
	// o.Script(suffix+script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("project", "TuneGO"),
	// 	WithArg("id", 382),
	// 	WithArg("views", "[]"),
	// )

	// prefix = "Shard2"
	// o.Script(suffix+script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("project", "GeniaceNFT"),
	// 	WithArg("id", 2083),
	// 	WithArg("views", "[]"),
	// )

	// prefix = "Shard3"
	// o.Script(suffix+script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("project", "BlindBoxRedeemVoucher"),
	// 	WithArg("id", 38477),
	// 	WithArg("views", "[]"),
	// )

	// prefix = "Shard4"
	// o.Script(suffix+script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("project", "PartyMansionDrinksContract"),
	// 	WithArg("id", 4034),
	// 	WithArg("views", "[]"),
	// )

	// prefix = "NFTCatalog"
	// o.Script(script+prefix,
	// 	WithArg("user", "bjartek"),
	// 	WithArg("project", "A.921ea449dffec68a.Flovatar.NFT"),
	// 	WithArg("id", 2271),
	// 	WithArg("views", "[]"),
	// )

}
