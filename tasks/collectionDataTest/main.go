package main

import (
	"fmt"

	"github.com/bjartek/overflow"
)

func main() {

	o2 := overflow.NewOverflowMainnet().Start()

	//pub fun main(user: String, nftAliasOrIdentifier:String, id: UInt64, views: [String]) : NFTDetailReport?{
	// res3 := o2.ScriptFromFile("getNFTDetailsNFTCatalog").NamedArguments(map[string]string{
	// 	"user":                 "christian",
	// 	"nftAliasOrIdentifier": "Dandy",
	// 	"id":                   "97168801",
	// 	"views":                `["A.631e88ae7f1d7c20.MetadataViews.NFTCollectionData"]`,
	// }).RunReturnsJsonString()

	res3 := o2.ScriptFromFile("mainnetgetFactoryCollectionsRaribleNFT").NamedArguments(map[string]string{
		"user":        "alxo",
		"maxItems":    "0",
		"collections": `[]`,
	}).RunReturnsJsonString()

	fmt.Println(res3)

	res4 := o2.ScriptFromFile("mainnetgetAdditionalFactoryCollectionItemsRaribleNFT").NamedArguments(map[string]string{
		"user": "alxo",
		"collectionIDs": `{
			"FlowverseSocks": [
					14948]
				}`,
	}).RunReturnsJsonString()

	fmt.Println(res4)

}
