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

	res3 := o2.ScriptFromFile("testnetGetAdditionalFactoryCollectionItemsRegistry").NamedArguments(map[string]string{
		"user": "christian",
		"collectionIDs": `{"Dandy" : [
            98375394,
            98375410,
            98375417,
            98375408,
            98375403,
            98375411,
            98375402,
            98375421,
            98375395,
            98375409,
            98375416,
            98375399,
            98375393,
            98375398,
            98375412,
            98375407,
            98375405,
            98375418,
            98375415,
            98375406,
            98375396,
            98375397,
            98375404,
            98375400,
            98375413
        ]}`,
	}).RunReturnsJsonString()

	fmt.Println(res3)

}
