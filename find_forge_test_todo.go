package test_main

import (
	"context"
	"fmt"
	"os"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/onflow/cadence"
	"github.com/stretchr/testify/assert"
)

func TestFindForge(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}
	otu.buyForge("user1")
	exampleNFTForge := otu.identifier("ExampleNFT", "Forge")

	t.Run("Should be able to get Example NFT  by script", func(t *testing.T) {
		exampleNFTIdentifier := exampleNFTType(otu)

		extraIDs, err := otu.O.Script(
			`
				import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"

				access(all) main() : UInt64 {return ExampleNFT.totalSupply - 1}
			`,
		).GetAsInterface()
		assert.NoError(t, err)

		otu.O.Script("getNFTCatalogIDs",
			WithArg("user", "user1"),
			WithArg("collections", `[]`),
		).AssertWant(t,
			autogold.Want("collection", map[string]interface{}{exampleNFTIdentifier: map[string]interface{}{
				"collectionName":     "The Example Collection",
				"extraIDs":           []interface{}{extraIDs},
				"extraIDsIdentifier": exampleNFTIdentifier,
				"length":             1,
				"shard":              "NFTCatalog",
			}}),
		)
	})

	t.Run("Should be able to add allowed names to private forges", func(t *testing.T) {
		otu.O.Tx("adminRemoveForge",
			WithSigner("find-admin"),
			WithArg("type", exampleNFTForge),
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
		).AssertFailure(t, fmt.Sprintf("This forge type is not supported. type : %s", exampleNFTForge))

		otu.O.Tx("adminAddForge",
			WithSigner("find-admin"),
			WithArg("type", exampleNFTForge),
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
		).AssertFailure(t, fmt.Sprintf("This forge is not supported publicly. Forge Type : %s", exampleNFTForge))

		otu.O.Tx("adminAddForge",
			WithSigner("find-admin"),
			WithArg("type", exampleNFTForge),
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
			WithSigner("find-admin"),
			WithArg("type", exampleNFTForge),
		).AssertSuccess(t)

		otu.O.Tx("adminAddForge",
			WithSigner("find-admin"),
			WithArg("type", exampleNFTForge),
			WithArg("name", "user1"),
		).AssertSuccess(t)

		otu.O.Tx("buyAddon",
			WithSigner("user1"),
			WithArg("name", "user1"),
			WithArg("addon", "premiumForge"),
			WithArg("amount", 1000.0),
		).AssertSuccess(t).
			AssertEvent(t, otu.identifier("FIND", "AddonActivated"),
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
			WithArg("aliasOrIdentifier", exampleNFTType(otu)),
			WithArg("id", id),
			WithArg("identifier", otu.identifier("MetadataViews", "Royalties")),
		).AssertWant(t,
			autogold.Want("royalty", map[string]interface{}{"cutInfos": []interface{}{map[string]interface{}{"cut": 0.05, "description": "creator", "receiver": fmt.Sprintf("Capability<&AnyResource{%s}>(address: %s, path: /public/findProfileReceiver)", otu.identifier("FungibleToken", "Receiver"), otu.O.Address("user1"))}}}),
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
			Print().
			AssertFailure(t, "This trait does not exist ID :4")
	})

	t.Run("Should be able register traits to Example NFT and then mint", func(t *testing.T) {
		otu.O.Tx("devAddTraitsExampleNFT",
			WithSigner("find-admin"),
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
			WithSigner("find-admin"),
			WithArg("name", "testingname"),
			WithArg("addon", "premiumForge"),
		).
			AssertSuccess(t).
			AssertEvent(t, "AddonActivated", map[string]interface{}{
				"name":  "testingname",
				"addon": "premiumForge",
			})

		otu.O.Tx("adminAddForge",
			WithSigner("find-admin"),
			WithArg("type", exampleNFTForge),
			WithArg("name", "testingname"),
		).AssertSuccess(t)

		otu.O.Tx("devadminMintExampleNFT",
			WithSigner("find-admin"),
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

	type MetadataViews_NFTCollectionDisplay struct {
		Name        string
		Description string
		ExternalURL MetadataViews_ExternalURL `cadence:"externalURL"`
		SquareImage MetadataViews_Media_IPFS  `cadence:"squareImage"`
		BannerImage MetadataViews_Media_IPFS  `cadence:"bannerImage"`
		Socials     map[string]MetadataViews_ExternalURL
	}

	collectionDisplay := MetadataViews_NFTCollectionDisplay{
		Name:        "notSet",
		Description: "testing",
		ExternalURL: MetadataViews_ExternalURL{Url: "testing url"},
		SquareImage: MetadataViews_Media_IPFS{
			File: MetadataViews_IPFSFile{
				Cid:  "testing square",
				Path: nil,
			},
		},
		BannerImage: MetadataViews_Media_IPFS{
			File: MetadataViews_IPFSFile{
				Cid:  "testing banner",
				Path: nil,
			},
		},
		Socials: map[string]MetadataViews_ExternalURL{
			"twitter": {Url: "testing twitter"},
			"discord": {Url: "testing discord"},
		},
	}

	t.Run("Should be able to order Forges for contract", func(t *testing.T) {
		testingName := "foo"
		mintType := "DIM"
		otu.O.Tx("register",
			WithSigner("user1"),
			WithArg("name", testingName),
			WithArg("amount", 500.0),
		).AssertSuccess(t)

		otu.O.Tx("buyAddon",
			WithSigner("user1"),
			WithArg("name", testingName),
			WithArg("addon", "forge"),
			WithArg("amount", 50.0),
		).
			AssertSuccess(t).
			AssertEvent(t, "AddonActivated", map[string]interface{}{
				"name":  testingName,
				"addon": "forge",
			})

		otu.O.Tx("adminAddForgeMintType",
			WithSigner("find-admin"),
			WithArg("mintType", mintType),
		).
			AssertSuccess(t)

		collectionDisplay.Name = testingName

		otu.O.Tx("orderForge",
			WithSigner("user1"),
			WithArg("name", testingName),
			WithArg("mintType", mintType),
			WithArg("minterCut", 0.05),
			WithArg("collectionDisplay", collectionDisplay),
		).
			Print().
			AssertSuccess(t).
			AssertEvent(t, "ForgeOrdered", map[string]interface{}{
				"lease":    testingName,
				"mintType": mintType,
			})
	})

	t.Run("Should be able to remove order as Admin", func(t *testing.T) {
		testingName := "foo"
		mintType := "DIM"

		collectionDisplay.Name = testingName

		otu.O.Tx("adminCancelForgeOrder",
			WithSigner("find-admin"),
			WithArg("name", testingName),
			WithArg("mintType", mintType),
		).
			Print().
			AssertSuccess(t).
			AssertEvent(t, "ForgeOrderCancelled", map[string]interface{}{
				"lease":    testingName,
				"mintType": mintType,
			})
	})

	t.Run("Should be able to order as Admin", func(t *testing.T) {
		testingName := "foo"
		mintType := "DIM"

		collectionDisplay.Name = testingName

		otu.O.Tx("adminOrderForge",
			WithSigner("find-admin"),
			WithArg("name", testingName),
			WithArg("mintType", mintType),
			WithArg("minterCut", 0.05),
			WithArg("collectionDisplay", collectionDisplay),
		).
			Print().
			AssertSuccess(t).
			AssertEvent(t, "ForgeOrdered", map[string]interface{}{
				"lease":    testingName,
				"mintType": mintType,
			})
	})

	// set User4 as admin, the account as find-forge on emulator (for deploying contracts)
	otu.O.Tx("setup_fin_1_create_client", WithSigner("find-forge")).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	// link in the server in the versus client
	otu.O.Tx("setup_fin_2_register_client",
		findSigner,
		WithArg("ownerAddress", "find-forge"),
	).AssertSuccess(otu.T).AssertNoEvents(otu.T)

	t.Run("Should be able to deploy Forge recipe contract and fulfill the order", func(t *testing.T) {
		file, err := os.ReadFile("./contracts/FindFooDIM.cdc")
		assert.NoError(t, err)

		err = otu.O.AddContract(context.Background(), "find-forge", file, []cadence.Value{}, "./contracts/FindFooDIM.cdc", false)
		assert.NoError(t, err)
	})

	t.Run("Should be able to mint Foo NFT as user 1", func(t *testing.T) {
		type FindForgeStruct_FindDIM struct {
			Name          string                 `cadence:"name"`
			Description   string                 `cadence:"description"`
			ThumbnailHash string                 `cadence:"thumbnailHash"`
			ExternalURL   string                 `cadence:"externalURL"`
			Edition       uint64                 `cadence:"edition"`
			MaxEdition    uint64                 `cadence:"maxEdition"`
			Descriptions  map[string]string      `cadence:"descriptions"`
			Scalars       map[string]float64     `cadence:"scalars"`
			Boosts        map[string]float64     `cadence:"boosts"`
			BoostPercents map[string]float64     `cadence:"boostPercents"`
			Levels        map[string]float64     `cadence:"levels"`
			Traits        map[string]string      `cadence:"traits"`
			Dates         map[string]float64     `cadence:"dates"`
			Medias        map[string]string      `cadence:"medias"`
			Extras        map[string]interface{} `cadence:"extras"`
		}

		data := FindForgeStruct_FindDIM{
			Name:          "Name",
			Description:   "Description",
			ThumbnailHash: "ThumbnailHash",
			ExternalURL:   "ExternalURL",
			Edition:       1,
			MaxEdition:    2,
			Descriptions: map[string]string{
				"Descriptions": "Descriptions",
			},
			Scalars: map[string]float64{
				"Scalars": 1.0,
			},
			Boosts: map[string]float64{
				"Boosts": 1.0,
			},
			BoostPercents: map[string]float64{
				"BoostPercents": 1.0,
			},
			Levels: map[string]float64{
				"Levels": 1.0,
			},
			Traits: map[string]string{
				"Traits": "Traits",
			},
			Dates: map[string]float64{
				"Dates": 1.0,
			},
			Medias: map[string]string{
				"Traits": "Traits",
			},
			Extras: map[string]interface{}{},
		}

		otu.O.Tx("devmintFooDIMNFT",
			WithSigner("user1"),
			WithArg("name", "foo"),
			WithArg("receivers", []string{"user1"}),
			WithArg("data", []FindForgeStruct_FindDIM{
				data,
			}),
		).
			AssertSuccess(t).
			AssertEvent(t, "FindFooDIM.Minted", map[string]interface{}{
				"name":        data.Name,
				"description": data.Description,
				"edition":     data.Edition,
				"maxEdition":  data.MaxEdition,
			})
	})
}
