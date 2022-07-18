package main

import (
	"fmt"

	"github.com/bjartek/overflow/overflow"
)

func main() {

	o2 := overflow.NewOverflowMainnet().Start()

	//pub fun main(user: String, nftAliasOrIdentifier:String, id: UInt64, views: [String]) : NFTDetailReport?{
	// res3 := o2.ScriptFromFile("getNFTDetails").NamedArguments(map[string]string{
	// 	"user":                 "christian",
	// 	"nftAliasOrIdentifier": "Dandy",
	// 	"id":                   "97168801",
	// 	"views":                `["A.631e88ae7f1d7c20.MetadataViews.NFTCollectionData"]`,
	// }).RunReturnsJsonString()

	res3 := o2.ScriptFromFile("mainnetGetFactoryCollectionsShard1").NamedArguments(map[string]string{
		"user":     "bjartek",
		"maxItems": "1",
	}).RunReturnsJsonString()

	fmt.Println(res3)

}
