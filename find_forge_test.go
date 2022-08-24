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

		otu.O.TransactionFromFile("adminAddNFTCatalog").
			SignProposeAndPayAs("account").
			Args(otu.O.Arguments().
				String("A.f8d6e0586b0a20c7.ExampleNFT.NFT").
				String("A.f8d6e0586b0a20c7.ExampleNFT.NFT").
				Account("account").
				Account("account").
				UInt64(0).
				String("exampleNFTCollection")).
			Test(otu.T).
			AssertSuccess()

		otu.O.Tx("testMintExampleNFT",
			overflow.WithSigner("user1"),
			overflow.WithArg("name", "user1"),
			overflow.WithArg("artist", "Bam"),
			overflow.WithArg("nftName", "ExampleNFT"),
			overflow.WithArg("nftDescription", "This is an ExampleNFT"),
			overflow.WithArg("nftUrl", "This is an exampleNFT url"),
			overflow.WithArg("collectionDescription", "Example NFT FIND"),
			overflow.WithArg("collectionExternalURL", "Example NFT external url"),
			overflow.WithArg("collectionSquareImage", "Example NFT square image"),
			overflow.WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertSuccess(t)

		// autogold.Equal(t, result)

		otu.O.Script("getNFTCatalogIDs",
			overflow.WithArg("user", "user1"),
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

	t.Run("Should be able to add allowed names to private forges", func(t *testing.T) {
		otu.O.Tx("adminRemoveForge",
			overflow.WithSigner("find"),
			overflow.WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.Forge"),
		).AssertSuccess(t)

		otu.O.Tx("testMintExampleNFT",
			overflow.WithSigner("user1"),
			overflow.WithArg("name", "user1"),
			overflow.WithArg("artist", "Bam"),
			overflow.WithArg("nftName", "ExampleNFT"),
			overflow.WithArg("nftDescription", "This is an ExampleNFT"),
			overflow.WithArg("nftUrl", "This is an exampleNFT url"),
			overflow.WithArg("collectionDescription", "Example NFT FIND"),
			overflow.WithArg("collectionExternalURL", "Example NFT external url"),
			overflow.WithArg("collectionSquareImage", "Example NFT square image"),
			overflow.WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertFailure(t, "This forge type is not supported. type : A.f8d6e0586b0a20c7.ExampleNFT.Forge")

		otu.O.Tx("adminAddForge",
			overflow.WithSigner("find"),
			overflow.WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.Forge"),
			overflow.WithArg("name", "user1"),
		).AssertSuccess(t)

		otu.O.Tx("testMintExampleNFT",
			overflow.WithSigner("user1"),
			overflow.WithArg("name", "user1"),
			overflow.WithArg("artist", "Bam"),
			overflow.WithArg("nftName", "ExampleNFT"),
			overflow.WithArg("nftDescription", "This is an ExampleNFT"),
			overflow.WithArg("nftUrl", "This is an exampleNFT url"),
			overflow.WithArg("collectionDescription", "Example NFT FIND"),
			overflow.WithArg("collectionExternalURL", "Example NFT external url"),
			overflow.WithArg("collectionSquareImage", "Example NFT square image"),
			overflow.WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertSuccess(t)

		otu.createUser(10000.0, "user2").
			registerUser("user2").
			buyForge("user2")

		otu.O.Tx("testMintExampleNFT",
			overflow.WithSigner("user2"),
			overflow.WithArg("name", "user2"),
			overflow.WithArg("artist", "Bam"),
			overflow.WithArg("nftName", "ExampleNFT"),
			overflow.WithArg("nftDescription", "This is an ExampleNFT"),
			overflow.WithArg("nftUrl", "This is an exampleNFT url"),
			overflow.WithArg("collectionDescription", "Example NFT FIND"),
			overflow.WithArg("collectionExternalURL", "Example NFT external url"),
			overflow.WithArg("collectionSquareImage", "Example NFT square image"),
			overflow.WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertFailure(t, "This forge is not supported publicly. Forge Type : A.f8d6e0586b0a20c7.ExampleNFT.Forge")

		otu.O.Tx("adminAddForge",
			overflow.WithSigner("find"),
			overflow.WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.Forge"),
			overflow.WithArg("name", "user2"),
		).AssertSuccess(t)

		otu.O.Tx("testMintExampleNFT",
			overflow.WithSigner("user2"),
			overflow.WithArg("name", "user2"),
			overflow.WithArg("artist", "Bam"),
			overflow.WithArg("nftName", "ExampleNFT"),
			overflow.WithArg("nftDescription", "This is an ExampleNFT"),
			overflow.WithArg("nftUrl", "This is an exampleNFT url"),
			overflow.WithArg("collectionDescription", "Example NFT FIND"),
			overflow.WithArg("collectionExternalURL", "Example NFT external url"),
			overflow.WithArg("collectionSquareImage", "Example NFT square image"),
			overflow.WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertSuccess(t)

	})

	t.Run("Should be able to add allowed names to private forges", func(t *testing.T) {

		otu.O.Tx("adminRemoveForge",
			overflow.WithSigner("find"),
			overflow.WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.Forge"),
		).AssertSuccess(t)

		otu.O.Tx("adminAddForge",
			overflow.WithSigner("find"),
			overflow.WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.Forge"),
			overflow.WithArg("name", "user1"),
		).AssertSuccess(t)

		otu.O.Tx("buyAddon",
			overflow.WithSigner("user1"),
			overflow.WithArg("name", "user1"),
			overflow.WithArg("addon", "premiumForge"),
			overflow.WithArg("amount", 1000.0),
		).AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FIND.AddonActivated",
				map[string]interface{}{
					"name":  "user1",
					"addon": "premiumForge",
				},
			)

		id, err := otu.O.Tx("testMintExampleNFT",
			overflow.WithSigner("user1"),
			overflow.WithArg("name", "user1"),
			overflow.WithArg("artist", "Bam"),
			overflow.WithArg("nftName", "ExampleNFT"),
			overflow.WithArg("nftDescription", "This is an ExampleNFT"),
			overflow.WithArg("nftUrl", "This is an exampleNFT url"),
			overflow.WithArg("collectionDescription", "Example NFT FIND"),
			overflow.WithArg("collectionExternalURL", "Example NFT external url"),
			overflow.WithArg("collectionSquareImage", "Example NFT square image"),
			overflow.WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertSuccess(t).
			GetIdFromEvent("FindForge.Minted", "id")

		if err != nil {
			panic(err)
		}

		otu.O.Script("getNFTView",
			overflow.WithArg("user", "user1"),
			overflow.WithArg("aliasOrIdentifier", "A.f8d6e0586b0a20c7.ExampleNFT.NFT"),
			overflow.WithArg("id", id),
			overflow.WithArg("identifier", "A.f8d6e0586b0a20c7.MetadataViews.Royalties"),
		).AssertWant(t,
			autogold.Want("royalty", map[string]interface{}{"cutInfos": []interface{}{map[string]interface{}{"cut": 0.05, "description": "creator", "receiver": "Capability<&AnyResource{A.ee82856bf20e2aa6.FungibleToken.Receiver}>(address: 0x179b6b1cb6755e31, path: /public/findProfileReceiver)"}}}),
		)

	})
}
