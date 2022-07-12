package main

import (
	"fmt"

	"github.com/bjartek/overflow/overflow"
)

func main() {

	o2 := overflow.NewOverflowTestnet().Start()

	//pub fun main(user: String, nftAliasOrIdentifier:String, id: UInt64, views: [String]) : NFTDetailReport?{
	// res3 := o2.ScriptFromFile("getNFTDetails").NamedArguments(map[string]string{
	// 	"user":                 "christian",
	// 	"nftAliasOrIdentifier": "Dandy",
	// 	"id":                   "97168801",
	// 	"views":                `["A.631e88ae7f1d7c20.MetadataViews.NFTCollectionData"]`,
	// }).RunReturnsJsonString()

	res3 := o2.ScriptFromFile("getFactoryCollections").NamedArguments(map[string]string{
		"user":        "0xe409a7e8a52812a9",
		"maxItems":    "1000",
		"collections": `[]`,
		"shard":       "NFTRegistry",
	}).RunReturnsJsonString()

	fmt.Println(res3)

}
