package test_main

import (
	"testing"

	. "github.com/bjartek/overflow/v2"
	"github.com/findonflow/find/findGo"
	"github.com/hexops/autogold"
)


func TestGeneratedExperiences(t *testing.T) {
	otu := &OverflowTestUtils{T: t, O: ot.O}

	ot.Run(t, "Should be able to add season", func(t *testing.T) {
		season := []findGo.GeneratedExperiences_CollectionInfo{
			{
				Season: 2,
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
				"season":      2,
				"squareImage": "ipfs://square",
				"bannerImage": "ipfs://banner",
			})
	})

	ot.Run(t, "Should be able to add mint token", func(t *testing.T) {
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

		result := otu.O.Tx("devAdminMintGeneratedExperiences",
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

		ids := result.GetIdsFromEvent("Minted", "id")
		geIdentifier, _ := otu.O.QualifiedIdentifier("GeneratedExperiences", "NFT")

		otu.O.Tx("devaddNFTCatalog",
			WithSigner("account"),
			WithArg("collectionIdentifier", geIdentifier),
			WithArg("contractName", geIdentifier),
			WithArg("contractAddress", "find-forge"),
			WithArg("addressWithNFT", "find-admin"),
			WithArg("nftID", ids[0]),
			WithArg("publicPathIdentifier", "GeneratedExperiences"),
		).AssertSuccess(t)

		otu.O.Script("getNFTViewsForAddress",
			WithArg("address", "find-admin"),
			WithArg("aliasOrIdentifier", geIdentifier),
			WithArg("id", ids[0]),
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
  "A.f3fcd2c1a78f5eee.FindPack.PackRevealData",
}`))

		tcs := map[string]autogold.Value{
			"A.f8d6e0586b0a20c7.MetadataViews.Display": autogold.Want("Display", map[string]interface{}{"description": "Description", "name": "Name", "thumbnail": map[string]interface{}{"cid": "thumbnail"}}),
			"A.f8d6e0586b0a20c7.MetadataViews.Royalties": autogold.Want("Royalties", map[string]interface{}{"cutInfos": []interface{}{map[string]interface{}{"cut": 0.1, "description": "Royalty", "receiver": map[string]interface{}{
				"address":    "0x192440c99cb17282",
				"borrowType": "&{A.ee82856bf20e2aa6.FungibleToken.Receiver}",
				"id":         10,
			}}}}),
			"A.f8d6e0586b0a20c7.MetadataViews.Editions": autogold.Want("Editions", map[string]interface{}{"infoList": []interface{}{map[string]interface{}{"max": 2, "name": "generatedexperiences", "number": 1}}}),
			"A.f8d6e0586b0a20c7.MetadataViews.Traits":   autogold.Want("Traits", map[string]interface{}{"traits": []interface{}{map[string]interface{}{"displayType": "String", "name": "Artist", "value": "Artist"}}}),
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
			"A.f8d6e0586b0a20c7.MetadataViews.Rarity":    autogold.Want("Rarity", map[string]interface{}{"description": "Common"}),
			"A.179b6b1cb6755e31.FindPack.PackRevealData": autogold.Want("PackRevealData", nil),
		}

		for view, val := range tcs {
			otu.O.Script("getNFTViewForAddress",
				WithArg("aliasOrIdentifier", geIdentifier),
				WithArg("id", ids[0]),
				WithArg("address", "find-admin"),
				WithArg("view", view),
			).
				AssertWant(t, val)
		}
	})
}
