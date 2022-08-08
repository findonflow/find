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

	//mainnet script test

	network := "mainnet"

	o := Overflow(
		WithNetwork(network),
	)

	suffix := network

	script := "getFactoryCollections"

	prefix := "RaribleNFT"
	o.Script(suffix+script+prefix,
		WithArg("user", "bjartek"),
		WithArg("maxItems", "2"),
		WithArg("collections", "[]"),
	)

	o.Script(suffix+"getAdditionalFactoryCollectionItems"+prefix,
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"FlowverseSocks" : [14939]}`),
	)

	prefix = "Shard1"
	o.Script(suffix+script+prefix,
		WithArg("user", "bjartek"),
		WithArg("maxItems", "2"),
		WithArg("collections", "[]"),
	)

	o.Script(suffix+"getAdditionalFactoryCollectionItems"+prefix,
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"TuneGO" : [328]}`),
	)

	prefix = "Shard2"
	o.Script(suffix+script+prefix,
		WithArg("user", "bjartek"),
		WithArg("maxItems", "2"),
		WithArg("collections", "[]"),
	)

	o.Script(suffix+"getAdditionalFactoryCollectionItems"+prefix,
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"Xtingles" : [1281]}`),
	)

	prefix = "Shard3"
	o.Script(suffix+script+prefix,
		WithArg("user", "bjartek"),
		WithArg("maxItems", "2"),
		WithArg("collections", "[]"),
	)

	o.Script(suffix+"getAdditionalFactoryCollectionItems"+prefix,
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"SomePlaceCollectible" : [164769803]}`),
	)

	prefix = "Shard4"
	o.Script(suffix+script+prefix,
		WithArg("user", "bjartek"),
		WithArg("maxItems", "10"),
		WithArg("collections", "[]"),
	)

	o.Script(suffix+"getAdditionalFactoryCollectionItems"+prefix,
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"PartyMansionDrinksContract" : [836]}`),
	)

	prefix = "NFTCatalog"
	o.Script(script+prefix,
		WithArg("user", "bjartek"),
		WithArg("maxItems", "10000"),
		WithArg("collections", `[]`),
	)

	o.Script("getAdditionalFactoryCollectionItemsNFTCatalog",
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"schmoes_prelaunch_token" : [9]}`),
	)

	// get NFTDetail script
	script = "getNFTDetails"

	prefix = "RaribleNFT"
	o.Script(suffix+script+prefix,
		WithArg("user", "bjartek"),
		WithArg("project", "Flowverse Socks"),
		WithArg("id", 14939),
		WithArg("views", "[]"),
	)

	prefix = "Shard1"
	o.Script(suffix+script+prefix,
		WithArg("user", "bjartek"),
		WithArg("project", "TuneGO"),
		WithArg("id", 382),
		WithArg("views", "[]"),
	)

	prefix = "Shard2"
	o.Script(suffix+script+prefix,
		WithArg("user", "bjartek"),
		WithArg("project", "GeniaceNFT"),
		WithArg("id", 2083),
		WithArg("views", "[]"),
	)

	prefix = "Shard3"
	o.Script(suffix+script+prefix,
		WithArg("user", "bjartek"),
		WithArg("project", "BlindBoxRedeemVoucher"),
		WithArg("id", 38477),
		WithArg("views", "[]"),
	)

	prefix = "Shard4"
	o.Script(suffix+script+prefix,
		WithArg("user", "bjartek"),
		WithArg("project", "PartyMansionDrinksContract"),
		WithArg("id", 4034),
		WithArg("views", "[]"),
	)

	prefix = "NFTCatalog"
	o.Script(script+prefix,
		WithArg("user", "bjartek"),
		WithArg("project", "A.921ea449dffec68a.Flovatar.NFT"),
		WithArg("id", 2271),
		WithArg("views", "[]"),
	)

}
