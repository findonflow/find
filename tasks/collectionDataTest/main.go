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

	network := "testnet"

	o := Overflow(
		WithNetwork(network),
	)

	suffix := network

	script := "getFactoryCollections"

	prefix := "RaribleNFT"
	o.Script(suffix+script+prefix,
		WithArg("user", "christian"),
		WithArg("maxItems", "0"),
		WithArg("collections", "[]"),
	)

	prefix = "Shard1"
	o.Script(suffix+script+prefix,
		WithArg("user", "christian"),
		WithArg("maxItems", "0"),
		WithArg("collections", "[]"),
	)

	prefix = "Shard2"
	o.Script(suffix+script+prefix,
		WithArg("user", "christian"),
		WithArg("maxItems", "0"),
		WithArg("collections", "[]"),
	)

	prefix = "Shard3"
	o.Script(suffix+script+prefix,
		WithArg("user", "christian"),
		WithArg("maxItems", "0"),
		WithArg("collections", "[]"),
	)

	prefix = "Shard4"
	o.Script(suffix+script+prefix,
		WithArg("user", "christian"),
		WithArg("maxItems", "0"),
		WithArg("collections", "[]"),
	)

	prefix = "NFTCatalog"
	o.Script(script+prefix,
		WithArg("user", "christian"),
		WithArg("maxItems", "0"),
		WithArg("collections", "[]"),
	)

}
