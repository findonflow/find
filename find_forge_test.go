package test_main

import (
	"os"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/hexops/autogold"
	"github.com/onflow/cadence"
	"github.com/onflow/flow-cli/pkg/flowkit/services"
	"github.com/stretchr/testify/assert"
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
			WithSigner("find"),
			WithArg("mintType", mintType),
		).
			AssertSuccess(t)

		type MetadataViews_NFTCollectionDisplay struct {
			Name        string
			Description string
			ExternalURL MetadataViews_ExternalURL `cadence:"externalURL"`
			SquareImage MetadataViews_Media_IPFS  `cadence:"squareImage"`
			BannerImage MetadataViews_Media_IPFS  `cadence:"bannerImage"`
			Socials     map[string]MetadataViews_ExternalURL
		}

		otu.O.Tx("orderForge",
			WithSigner("user1"),
			WithArg("name", testingName),
			WithArg("mintType", mintType),
			WithArg("minterCut", 0.05),
			WithArg("collectionDisplay", MetadataViews_NFTCollectionDisplay{
				Name:        testingName,
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
			}),
		).
			Print().
			AssertSuccess(t)
	})

	// set User4 as admin, the account as find-forge on emulator (for deploying contracts)
	otu.O.Tx("setup_fin_1_create_client", WithSigner("user4")).
		AssertSuccess(otu.T).AssertNoEvents(otu.T)

	//link in the server in the versus client
	otu.O.Tx("setup_fin_2_register_client",
		saSigner,
		WithArg("ownerAddress", "user4"),
	).AssertSuccess(otu.T).AssertNoEvents(otu.T)

	t.Run("Should be able to deploy Forge recipe contract and fulfill the order", func(t *testing.T) {
		file, err := os.ReadFile("./contracts/FindFooDIM.cdc")
		assert.NoError(t, err)
		contract := services.Contract{
			Name:     "FindFooDIM",
			Source:   file,
			Args:     []cadence.Value{},
			Filename: "./contracts/FindFooDIM.cdc",
			Network:  "emulator",
		}
		_, err = otu.O.Services.Accounts.AddContract(otu.O.Account("user4"), &contract, false)
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

		otu.O.Tx("mintFooDIMNFT",
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
