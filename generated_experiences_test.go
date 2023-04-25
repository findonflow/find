package test_main

import (
	"fmt"
	"testing"

	. "github.com/bjartek/overflow"
	"github.com/findonflow/find/findGo"
	"github.com/hexops/autogold"
)

var forge = "user1"

func TestGeneratedExperiences(t *testing.T) {

	otu := NewOverflowTest(t).
		setupFIND().
		createUser(10000.0, "user1").
		registerUserWithName("user1", forge).
		buyForgeForName("user1", forge)

	generatedExpForge := otu.identifier("GeneratedExperiences", "Forge")

	otu.O.Tx("adminAddForge",
		WithSigner("find-admin"),
		WithArg("type", generatedExpForge),
		WithArg("name", forge),
	).AssertSuccess(t)

	t.Run("Should be able to add season", func(t *testing.T) {

		season := []findGo.GeneratedExperiences_CollectionInfo{
			{
				Season: 1,
				RoyaltiesInput: []findGo.FindPack_Royalty{
					{
						Recipient:   otu.O.Address("user1"),
						Cut:         0.1,
						Description: "Royalty",
					},
				},
				SquareImage: MetadataViews_Media_IPFS{
					File: MetadataViews_IPFSFile{
						Cid: "square",
					},
					MediaType: "png",
				},
				BannerImage: MetadataViews_Media_IPFS{
					File: MetadataViews_IPFSFile{
						Cid: "banner",
					},
					MediaType: "png",
				},
				Description: "Description",
				Socials: map[string]string{
					"twitter": "twitter",
					"discord": "discord",
				},
			},
		}

		otu.O.Tx("devAdminAddSeasonGeneratedExperiences",
			WithSigner("find-admin"),
			WithArg("name", "user1"),
			WithArg("season", season),
		).
			AssertSuccess(t).
			AssertEvent(t, "SeasonAdded", map[string]interface{}{
				"season":      1,
				"squareImage": "ipfs://square",
				"bannerImage": "ipfs://banner",
			})

	})

	t.Run("Should be able to add mint token", func(t *testing.T) {

		info := []findGo.GeneratedExperiences_Info{
			{
				Season:      1,
				Description: "Description",
				Name:        "Name",
				Thumbnail: MetadataViews_IPFSFile{
					Cid: "thumbnail",
				},
				Fullsize: MetadataViews_IPFSFile{
					Cid: "fullsize",
				},
				Edition:    1,
				MaxEdition: 2,
				Artist:     "Artist",
				Rarity:     "Common",
			},
			{
				Season:      1,
				Description: "Description",
				Name:        "Name",
				Thumbnail: MetadataViews_IPFSFile{
					Cid: "thumbnail",
				},
				Fullsize: MetadataViews_IPFSFile{
					Cid: "fullsize",
				},
				Edition:    2,
				MaxEdition: 2,
				Artist:     "Artist",
				Rarity:     "Rare",
			},
		}

		otu.O.Tx("devAdminMintGeneratedExperiences",
			WithSigner("find-admin"),
			WithArg("name", "user1"),
			WithArg("info", info),
		).
			AssertSuccess(t).
			AssertEvent(t, "Minted", map[string]interface{}{
				"season":     1,
				"name":       "Name",
				"thumbnail":  "ipfs://thumbnail",
				"fullsize":   "ipfs://fullsize",
				"artist":     "Artist",
				"rarity":     "Common",
				"edition":    1,
				"maxEdition": 2,
			}).
			AssertEvent(t, "Minted", map[string]interface{}{
				"season":     1,
				"name":       "Name",
				"thumbnail":  "ipfs://thumbnail",
				"fullsize":   "ipfs://fullsize",
				"artist":     "Artist",
				"rarity":     "Rare",
				"edition":    2,
				"maxEdition": 2,
			})

	})

	t.Run("Ensure views are returned correctly", func(t *testing.T) {

		viewscript := `
		import GeneratedExperiences from "../contracts/GeneratedExperiences.cdc"
		import MetadataViews from "../contracts/standard/MetadataViews.cdc"

		pub fun main(user: Address): AnyStruct {
			let acct = getAccount(user)
			let collectionRef = acct.getCapability(GeneratedExperiences.CollectionPublicPath)
				.borrow<&{MetadataViews.ResolverCollection}>()
				?? panic("Could not borrow capability from public collection")

			let resolver = collectionRef.borrowViewResolver(id: collectionRef.getIDs()[0])
			return resolver.getViews()
		}
	`

		otu.O.Script(viewscript,
			WithArg("user", "find-admin"),
		).
			AssertWant(t, autogold.Want("views", `[]interface {}{
  "A.f8d6e0586b0a20c7.MetadataViews.Display",
  "A.f8d6e0586b0a20c7.MetadataViews.Royalties",
  "A.f8d6e0586b0a20c7.MetadataViews.Editions",
  "A.f8d6e0586b0a20c7.MetadataViews.Traits",
  "A.f8d6e0586b0a20c7.MetadataViews.ExternalURL",
  "A.f8d6e0586b0a20c7.MetadataViews.NFTCollectionData",
  "A.f8d6e0586b0a20c7.MetadataViews.NFTCollectionDisplay",
  "A.f8d6e0586b0a20c7.MetadataViews.Medias",
  "A.f8d6e0586b0a20c7.MetadataViews.Rarity",
  "A.179b6b1cb6755e31.FindPack.PackRevealData",
}`))
	})

	tcs := map[string]autogold.Value{
		"A.f8d6e0586b0a20c7.MetadataViews.Display":     autogold.Want("Display", map[string]interface{}{"description": "Description", "name": "Name", "thumbnail": map[string]interface{}{"cid": "thumbnail"}}),
		"A.f8d6e0586b0a20c7.MetadataViews.Royalties":   autogold.Want("Royalties", map[string]interface{}{"cutInfos": []interface{}{map[string]interface{}{"cut": 0.1, "description": "Royalty", "receiver": "Capability<&AnyResource{A.ee82856bf20e2aa6.FungibleToken.Receiver}>(address: 0xf669cb8d41ce0c74, path: /public/findProfileReceiver)"}}}),
		"A.f8d6e0586b0a20c7.MetadataViews.Editions":    autogold.Want("Editions", map[string]interface{}{"infoList": []interface{}{map[string]interface{}{"max": 2, "name": "generatedexperiences", "number": 2}}}),
		"A.f8d6e0586b0a20c7.MetadataViews.Traits":      autogold.Want("Traits", map[string]interface{}{"traits": []interface{}{map[string]interface{}{"displayType": "String", "name": "Artist", "value": "Artist"}}}),
		"A.f8d6e0586b0a20c7.MetadataViews.ExternalURL": autogold.Want("ExternalURL", map[string]interface{}{"url": "https://find.xyz/0xf3fcd2c1a78f5eee/collection/main/GeneratedExperiences/332"}),
		"A.f8d6e0586b0a20c7.MetadataViews.NFTCollectionDisplay": autogold.Want("NFTCollectionDisplay", map[string]interface{}{
			"bannerImage": map[string]interface{}{"file": map[string]interface{}{"cid": "banner"}, "mediaType": "png"}, "description": "Description",
			"externalURL": map[string]interface{}{"url": "https://find.xyz/mp/GeneratedExperiences"},
			"name":        "GeneratedExperiences",
			"socials": map[string]interface{}{
				"discord": map[string]interface{}{"url": "discord"},
				"twitter": map[string]interface{}{"url": "twitter"},
			},
			"squareImage": map[string]interface{}{
				"file":      map[string]interface{}{"cid": "square"},
				"mediaType": "png",
			},
		}),
		"A.f8d6e0586b0a20c7.MetadataViews.Medias": autogold.Want("Medias", map[string]interface{}{"items": []interface{}{map[string]interface{}{"file": map[string]interface{}{"cid": "thumbnail"}, "mediaType": "image"}, map[string]interface{}{
			"file":      map[string]interface{}{"cid": "fullsize"},
			"mediaType": "image",
		}}}),
		"A.f8d6e0586b0a20c7.MetadataViews.Rarity":    autogold.Want("Rarity", map[string]interface{}{"description": "Rare"}),
		"A.179b6b1cb6755e31.FindPack.PackRevealData": autogold.Want("PackRevealData", map[string]interface{}{"data": map[string]interface{}{"nftImage": "ipfs://thumbnail", "nftName": "Name", "packType": "GeneratedExperiences"}}),
	}

	script := `
	import GeneratedExperiences from "../contracts/GeneratedExperiences.cdc"
	import MetadataViews from "../contracts/standard/MetadataViews.cdc"

	pub fun main(user: Address, view: String): AnyStruct {
		let acct = getAccount(user)
		let collectionRef = acct.getCapability(GeneratedExperiences.CollectionPublicPath)
			.borrow<&{MetadataViews.ResolverCollection}>()
			?? panic("Could not borrow capability from public collection")

		let resolver = collectionRef.borrowViewResolver(id: collectionRef.getIDs()[1])
		return resolver.resolveView(CompositeType(view)!)
	}
`

	for view, val := range tcs {
		t.Run(fmt.Sprintf("Ensure view : %s returned correctly", view), func(t *testing.T) {

			otu.O.Script(script,
				WithArg("user", "find-admin"),
				WithArg("view", view),
			).
				AssertWant(t, val)
		})
	}

}
