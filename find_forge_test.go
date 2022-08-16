package test_main

import (
	"testing"

	"github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestFindForge(t *testing.T) {
	otu := NewOverflowTest(t)

	otu.setupFIND().
		createUser(10000.0, "user1").
		registerUser("user1").
		buyForge("user1")

	t.Run("Should be able to mint Example NFT and then get it by script", func(t *testing.T) {

		otu.O.Tx("adminAddNFTCatalog" , 
			overflow.WithSigner("account") , 
			overflow.WithArg("collectionIdentifier" , "A.f8d6e0586b0a20c7.ExampleNFT.NFT") ,
			overflow.WithArg("contractName" , "A.f8d6e0586b0a20c7.ExampleNFT.NFT") ,
			overflow.WithArg("contractAddress" , "account") ,
			overflow.WithArg("addressWithNFT" , "account") ,
			overflow.WithArg("nftID" , 0) ,
			overflow.WithArg("publicPathIdentifier" , "exampleNFTCollection") ,
		). 
			AssertSuccess(t)

		otu.O.Tx("testMintExampleNFT" ,
			overflow.WithSigner("user1") ,
			overflow.WithArg("name" , "user1") ,
			overflow.WithArg("artist" , "Bam") ,
			overflow.WithArg("nftName" , "ExampleNFT") ,
			overflow.WithArg("nftDescription" , "This is an ExampleNFT") ,
			overflow.WithArg("nftUrl" , "This is an exampleNFT url") ,
			overflow.WithArg("collectionDescription" , "Example NFT FIND") ,
			overflow.WithArg("collectionExternalURL" , "Example NFT external url") ,
			overflow.WithArg("collectionSquareImage" , "Example NFT square image") ,
			overflow.WithArg("collectionBannerImage" , "Example NFT banner image") ,
		).AssertSuccess(t)


		otu.O.Script("getFactoryCollectionsNFTCatalog",
			overflow.WithArg("user", "user1"),
			overflow.WithArg("maxItems", 0),
			overflow.WithArg("collections", `[]`),
		).AssertWant(t,
			autogold.Want("collection", map[string]interface{}{"A.f8d6e0586b0a20c7.ExampleNFT.NFT": map[string]interface{}{
				"extraIDs":           []interface{}{2},
				"extraIDsIdentifier": "A.f8d6e0586b0a20c7.ExampleNFT.NFT",
				"length":             1,
				"shard":              "NFTCatalog",
			}}),
		)

	})

}
