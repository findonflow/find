package main

import (
	"fmt"

	"github.com/bjartek/overflow"
)

func main() {

	// o := overflow.NewOverflowMainnet().Start()

	// user := "bjartek"

	// res := o.ScriptFromFile("devFactoryCollectionMainnet").Args(o.Arguments().String(user)).RunReturnsJsonString()
	// fmt.Println(res)

	o2 := overflow.NewOverflowTestnet().Start()

	res2 := o2.ScriptFromFile("getFactoryCollectionsAll").NamedArguments(map[string]string{
		"user": "christian",
	}).RunReturnsJsonString()

	//pub fun main(user: String, nftAliasOrIdentifier:String, id: UInt64, views: [String]) : NFTDetailReport?{
	// res3 := o2.ScriptFromFile("getNFTDetailsNFTCatalog").NamedArguments(map[string]string{
	// 	"user":                 "christian",
	// 	"nftAliasOrIdentifier": "Dandy",
	// 	"id":                   "97168801",
	// 	"views":                `["A.862f7bac4e02c854.FindViews.CreativeWork"]`,
	// }).RunReturnsJsonString()

	fmt.Println(res2)

}
