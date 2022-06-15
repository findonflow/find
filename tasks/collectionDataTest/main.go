package main

import (
	"fmt"

	"github.com/bjartek/overflow/overflow"
)

func main() {

	o2 := overflow.NewOverflowTestnet().Start()

	//pub fun main(user: String, nftAliasOrIdentifier:String, id: UInt64, views: [String]) : NFTDetailReport?{
	res3 := o2.ScriptFromFile("getNFTDetails").NamedArguments(map[string]string{
		"user":                 "christian",
		"nftAliasOrIdentifier": "Dandy",
		"id":                   "97168801",
		"views":                `["A.631e88ae7f1d7c20.MetadataViews.NFTCollectionData"]`,
	}).RunReturnsJsonString()

	fmt.Println(res3)

}
