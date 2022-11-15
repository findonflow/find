package test_main

import (
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
)

func TestFindForge(t *testing.T) {
	otu := NewOverflowTest(t)

	otu.setupFIND().
		createUser(10000.0, "user1").
		registerUser("user1").
		buyForge("user1")

	t.Run("Should be able to mint Example NFT and then get it by script", func(t *testing.T) {

		otu.O.Tx("adminAddNFTCatalog",
			WithSigner("find"),
			WithArg("collectionIdentifier", "A.f8d6e0586b0a20c7.ExampleNFT.NFT"),
			WithArg("contractName", "A.f8d6e0586b0a20c7.ExampleNFT.NFT"),
			WithArg("contractAddress", "account"),
			WithArg("addressWithNFT", "account"),
			WithArg("nftID", 0),
			WithArg("publicPathIdentifier", "exampleNFTCollection"),
		).
			AssertSuccess(t)

		otu.O.Tx("devMintExampleNFT",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("artist", "Bam"),
			WithArg("nftName", "ExampleNFT"),
			WithArg("nftDescription", "This is an ExampleNFT"),
			WithArg("nftUrl", "This is an exampleNFT url"),
			WithArg("traits", []uint64{1, 2, 3}),
			WithArg("collectionDescription", "Example NFT FIND"),
			WithArg("collectionExternalURL", "Example NFT external url"),
			WithArg("collectionSquareImage", "Example NFT square image"),
			WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertSuccess(t)

		// autogold.Equal(t, result)

		otu.O.Script("getNFTCatalogIDs",
			WithArg("user", "user1"),
			WithArg("collections", `[]`),
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
			WithSigner("find"),
			WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.Forge"),
		).AssertSuccess(t)

		otu.O.Tx("devMintExampleNFT",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("artist", "Bam"),
			WithArg("nftName", "ExampleNFT"),
			WithArg("nftDescription", "This is an ExampleNFT"),
			WithArg("nftUrl", "This is an exampleNFT url"),
			WithArg("traits", []uint64{1, 2, 3}),
			WithArg("collectionDescription", "Example NFT FIND"),
			WithArg("collectionExternalURL", "Example NFT external url"),
			WithArg("collectionSquareImage", "Example NFT square image"),
			WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertFailure(t, "This forge type is not supported. type : A.f8d6e0586b0a20c7.ExampleNFT.Forge")

		otu.O.Tx("adminAddForge",
			WithSigner("find"),
			WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.Forge"),
			WithArg("name", "user1"),
		).AssertSuccess(t)

		otu.O.Tx("devMintExampleNFT",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("artist", "Bam"),
			WithArg("nftName", "ExampleNFT"),
			WithArg("nftDescription", "This is an ExampleNFT"),
			WithArg("nftUrl", "This is an exampleNFT url"),
			WithArg("traits", []uint64{1, 2, 3}),
			WithArg("collectionDescription", "Example NFT FIND"),
			WithArg("collectionExternalURL", "Example NFT external url"),
			WithArg("collectionSquareImage", "Example NFT square image"),
			WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertSuccess(t)

		otu.createUser(10000.0, "user2").
			registerUser("user2").
			buyForge("user2")

		otu.O.Tx("devMintExampleNFT",
			WithSigner("user2"),
			WithArg("name", "user2"),
			WithArg("artist", "Bam"),
			WithArg("nftName", "ExampleNFT"),
			WithArg("nftDescription", "This is an ExampleNFT"),
			WithArg("nftUrl", "This is an exampleNFT url"),
			WithArg("traits", []uint64{1, 2, 3}),
			WithArg("collectionDescription", "Example NFT FIND"),
			WithArg("collectionExternalURL", "Example NFT external url"),
			WithArg("collectionSquareImage", "Example NFT square image"),
			WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertFailure(t, "This forge is not supported publicly. Forge Type : A.f8d6e0586b0a20c7.ExampleNFT.Forge")

		otu.O.Tx("adminAddForge",
			WithSigner("find"),
			WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.Forge"),
			WithArg("name", "user2"),
		).AssertSuccess(t)

		otu.O.Tx("devMintExampleNFT",
			WithSigner("user2"),
			WithArg("name", "user2"),
			WithArg("artist", "Bam"),
			WithArg("nftName", "ExampleNFT"),
			WithArg("nftDescription", "This is an ExampleNFT"),
			WithArg("nftUrl", "This is an exampleNFT url"),
			WithArg("traits", []uint64{1, 2, 3}),
			WithArg("collectionDescription", "Example NFT FIND"),
			WithArg("collectionExternalURL", "Example NFT external url"),
			WithArg("collectionSquareImage", "Example NFT square image"),
			WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertSuccess(t)

	})

	t.Run("Should be able to add allowed names to private forges", func(t *testing.T) {

		otu.O.Tx("adminRemoveForge",
			WithSigner("find"),
			WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.Forge"),
		).AssertSuccess(t)

		otu.O.Tx("adminAddForge",
			WithSigner("find"),
			WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.Forge"),
			WithArg("name", "user1"),
		).AssertSuccess(t)

		otu.O.Tx("buyAddon",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("addon", "premiumForge"),
			WithArg("amount", 1000.0),
		).AssertSuccess(t).
			AssertEvent(t, "A.f8d6e0586b0a20c7.FIND.AddonActivated",
				map[string]interface{}{
					"name":  "user1",
					"addon": "premiumForge",
				},
			)

		id, err := otu.O.Tx("devMintExampleNFT",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("artist", "Bam"),
			WithArg("nftName", "ExampleNFT"),
			WithArg("nftDescription", "This is an ExampleNFT"),
			WithArg("nftUrl", "This is an exampleNFT url"),
			WithArg("traits", []uint64{1, 2, 3}),
			WithArg("collectionDescription", "Example NFT FIND"),
			WithArg("collectionExternalURL", "Example NFT external url"),
			WithArg("collectionSquareImage", "Example NFT square image"),
			WithArg("collectionBannerImage", "Example NFT banner image"),
		).AssertSuccess(t).
			GetIdFromEvent("FindForge.Minted", "id")

		if err != nil {
			panic(err)
		}

		otu.O.Script("getNFTView",
			WithArg("user", "user1"),
			WithArg("aliasOrIdentifier", "A.f8d6e0586b0a20c7.ExampleNFT.NFT"),
			WithArg("id", id),
			WithArg("identifier", "A.f8d6e0586b0a20c7.MetadataViews.Royalties"),
		).AssertWant(t,
			autogold.Want("royalty", map[string]interface{}{"cutInfos": []interface{}{map[string]interface{}{"cut": 0.05, "description": "creator", "receiver": "Capability<&AnyResource{A.ee82856bf20e2aa6.FungibleToken.Receiver}>(address: 0x179b6b1cb6755e31, path: /public/findProfileReceiver)"}}}),
		)

	})

	t.Run("Should not be able to mint Example NFTs with non-exist traits", func(t *testing.T) {

		otu.O.Tx("devMintExampleNFT",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("artist", "Bam"),
			WithArg("nftName", "ExampleNFT"),
			WithArg("nftDescription", "This is an ExampleNFT"),
			WithArg("nftUrl", "This is an exampleNFT url"),
			WithArg("traits", []uint64{1, 2, 3, 4}),
			WithArg("collectionDescription", "Example NFT FIND"),
			WithArg("collectionExternalURL", "Example NFT external url"),
			WithArg("collectionSquareImage", "Example NFT square image"),
			WithArg("collectionBannerImage", "Example NFT banner image"),
		).
			AssertFailure(t, "This trait does not exist ID :4")
	})

	t.Run("Should be able register traits to Example NFT and then mint", func(t *testing.T) {

		otu.O.Tx("devAddTraitsExampleNFT",
			WithSigner("find"),
			WithArg("lease", "user1"),
		).
			AssertSuccess(t)

		otu.O.Tx("devMintExampleNFT",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("artist", "Bam"),
			WithArg("nftName", "ExampleNFT"),
			WithArg("nftDescription", "This is an ExampleNFT"),
			WithArg("nftUrl", "This is an exampleNFT url"),
			WithArg("traits", []uint64{1, 2, 3, 4}),
			WithArg("collectionDescription", "Example NFT FIND"),
			WithArg("collectionExternalURL", "Example NFT external url"),
			WithArg("collectionSquareImage", "Example NFT square image"),
			WithArg("collectionBannerImage", "Example NFT banner image"),
		).
			AssertSuccess(t)
	})

	t.Run("Should be able to add addon and mint for users as admin", func(t *testing.T) {

		otu.registerUserWithName("user1", "testingname")

		otu.O.Tx("adminAddAddon",
			WithSigner("find"),
			WithArg("name", "testingname"),
			WithArg("addon", "premiumForge"),
		).
			AssertSuccess(t).
			AssertEvent(t, "AddonActivated", map[string]interface{}{
				"name":  "testingname",
				"addon": "premiumForge",
			})

		otu.O.Tx("adminAddForge",
			WithSigner("find"),
			WithArg("type", "A.f8d6e0586b0a20c7.ExampleNFT.Forge"),
			WithArg("name", "testingname"),
		).AssertSuccess(t)

		otu.O.Tx("devadminMintExampleNFT",
			WithSigner("find"),
			WithArg("name", "testingname"),
			WithArg("artist", "Bam"),
			WithArg("nftName", "ExampleNFT"),
			WithArg("nftDescription", "This is an ExampleNFT"),
			WithArg("nftUrl", "This is an exampleNFT url"),
			WithArg("traits", []uint64{1, 2, 3, 4}),
			WithArg("collectionDescription", "Example NFT FIND"),
			WithArg("collectionExternalURL", "Example NFT external url"),
			WithArg("collectionSquareImage", "Example NFT square image"),
			WithArg("collectionBannerImage", "Example NFT banner image"),
		).
			AssertSuccess(t)
	})
}
