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
	// 	"collections": `[]`,
	// }).RunReturnsJsonString()

	// fmt.Println(res3)

	//mainnet script test

	network := "mainnet"

	o := Overflow(
		WithNetwork(network),
	)

	prefix := network + "get"

	IdSuffix := "IDs"
	ItemSuffix := "Items"

	script := "Socks"
	o.Script(prefix+script+IdSuffix,
		WithArg("user", "bjartek"),
		WithArg("collections", "[]"),
	)

	o.Script(prefix+script+ItemSuffix,
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"FlowverseSocks" : [14939]}`),
	)

	script = "Alchemy1"
	o.Script(prefix+script+IdSuffix,
		WithArg("user", "bjartek"),
		WithArg("collections", "[]"),
	)

	o.Script(prefix+script+ItemSuffix,
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"TuneGO" : [328]}`),
	)

	script = "Alchemy2"
	o.Script(prefix+script+IdSuffix,
		WithArg("user", "bjartek"),
		WithArg("collections", "[]"),
	)

	o.Script(prefix+script+ItemSuffix,
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"Xtingles" : [1281]}`),
	)

	script = "Alchemy3"
	o.Script(prefix+script+IdSuffix,
		WithArg("user", "bjartek"),
		WithArg("collections", "[]"),
	)

	o.Script(prefix+script+ItemSuffix,
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"SomePlaceCollectible" : [164769803]}`),
	)

	script = "Alchemy4"
	o.Script(prefix+script+IdSuffix,
		WithArg("user", "bjartek"),
		WithArg("collections", "[]"),
	)

	o.Script(prefix+script+ItemSuffix,
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"PartyMansionDrinksContract" : [836]}`),
	)

	script = "NFTCatalog"
	o.Script("get"+script+IdSuffix,
		WithArg("user", "bjartek"),
		WithArg("collections", `[]`),
	)

	o.Script("get"+script+ItemSuffix,
		WithArg("user", "bjartek"),
		WithArg("collectionIDs", `{"schmoes_prelaunch_token" : [9]}`),
	)

	// get NFTDetail script
	script = "NFTDetails"

	suffix := "Socks"
	o.Script(prefix+script+suffix,
		WithArg("user", "bjartek"),
		WithArg("project", "Flowverse Socks"),
		WithArg("id", 14939),
		WithArg("views", "[]"),
	)

	suffix = "Shard1"
	o.Script(prefix+script+suffix,
		WithArg("user", "bjartek"),
		WithArg("project", "TuneGO"),
		WithArg("id", 382),
		WithArg("views", "[]"),
	)

	suffix = "Shard2"
	o.Script(prefix+script+suffix,
		WithArg("user", "bjartek"),
		WithArg("project", "GeniaceNFT"),
		WithArg("id", 2083),
		WithArg("views", "[]"),
	)

	suffix = "Shard3"
	o.Script(prefix+script+suffix,
		WithArg("user", "bjartek"),
		WithArg("project", "BlindBoxRedeemVoucher"),
		WithArg("id", 38477),
		WithArg("views", "[]"),
	)

	suffix = "Shard4"
	o.Script(prefix+script+suffix,
		WithArg("user", "bjartek"),
		WithArg("project", "PartyMansionDrinksContract"),
		WithArg("id", 4034),
		WithArg("views", "[]"),
	)

	suffix = "NFTCatalog"
	o.Script("get"+script+suffix,
		WithArg("user", "bjartek"),
		WithArg("project", "A.921ea449dffec68a.Flovatar.NFT"),
		WithArg("id", 2271),
		WithArg("views", "[]"),
	)

	// if that item is soul bounded , it will not show on allow listing
	o.Script("get"+script+suffix,
		WithArg("user", "bjartek"),
		WithArg("project", "FLOAT"),
		WithArg("id", 277927096),
		WithArg("views", "[]"),
	)

}
