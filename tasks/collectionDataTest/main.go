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

	res3 := o2.ScriptFromFile("mainnetGetShardCollections").NamedArguments(map[string]string{
		"user": "alxo",
		// "maxItems":    "0",
		// "collections": `[]`,
	}).RunReturnsJsonString()

	fmt.Println(res3)

	// pub fun main(user: String, nftAliasOrIdentifier:String, id: UInt64, views: [String]) : NFTDetailReport?{
	// res3 := o2.ScriptFromFile("getAdditionalFactoryCollectionItems").NamedArguments(map[string]string{
	// 	"user": "0x0785f86201867f4e",
	// 	"collectionIDs": `{
	// 		"Bl0x": [
	// //         90505762,
	// //         90505737,
	//         90505183,
	// //         90504770,
	// //         90505501,
	// //         90505113,
	// //         90505268,
	// //         90504712,
	// //         90506550,
	//         // 90505354
	//     ]
	// // 	// ,
	// // 	// "Dandy": [
	// //     //     98375420,
	// //     //     98375410,
	// //     //     98375417,
	// //     //     98375408,
	// //     //     98375403,
	// //     //     98375411,
	// //     //     98375402,
	// //     //     98375421,
	// //     //     98375395,
	// //     //     98375409,
	// //     //     98375416,
	// //     //     98375399,
	// //     //     98375393,
	// //     //     98375398,
	// //     //     98375412,
	// //     //     98375407,
	// //     //     98375405,
	// //     //     98375418,
	// //     //     98375415,
	// //     //     98375406,
	// //     //     98375396,
	// //     //     98375397,
	// //     //     98375404,
	// //     //     98375400,
	// //     //     98375413
	// //     // ]
	// 	}`,
	// 	"shard": "NFTRegistry",
	// }).RunReturnsJsonString()

	// fmt.Println(res3)

}
