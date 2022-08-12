# How to add rich metadata to your NFT on .Find

Implementing [MetadataViews](./contracts/standard/MetadataViews.cdc) correctly in NFT smart contracts enables DApps on flow to extract rich NFT metadata and display them on [.Find](find.xyz). With MetadataViews, data such as display thumbnail, name, description, traits, collection information can be showcased in the exact way it is expected. 

We advice anybody that is integrating to contact us in [discord in the technical channel](https://discord.gg/8a27XMx8Zp) 


## Implementing `MetadataViews.Display`
For .Find to display an asset, the smart contract MUST implement `MetadataViews.Display`
.Find gets the display information through resolving Display View. 
Let's take a closer look on code implementation. 

```cadence

pub fun resolveView(_ type: Type): AnyStruct? {
	switch type {

		// Example for Display 
		case Type<MetadataViews.Display>() : 

			return MetadataViews.Display(
				name: NFT name, // Type<String>
				description: NFT description, // Type<String>
				thumbnail: NFT thumbnail // Type<{MetadataViews.File}>
			)

	}
}

```

If the thumbnail is a HTTP resource 
```cadence 
thumbnail : MetadataViews.HTTPFile(url: *Please put your url here)
```

If the thumbnail is an IPFS resource
```cadence 
//
thumbnail : MetadataViews.IPFSFile(
	cid: thumbnail cid, // Type <String>
	path: ipfs path // Type <String?> if it is not a directory, please put *nil*
)
```


![MetadataViews.Display](/images/display.png "Display")

| Param      | Description |
| ----------- | ----------- |
| name   | Name of the NFT        |
| description      | Human readable description of the NFT      |
| thumbnail      | A small thumbnail representation of the object       |

## Implementing `MetadataViews.CollectionDisplay`

.Find will resolve this MetadataViews struct for marketplace collection display from NFT Catalog. A rich and appropriata collection display will improve in UX when user browse your collection. 

To enable a decent collection display, the specific NFT that implements MetadataViews.CollectionDisplay should be submitted to [NFT-Catalog](https://nft-catalog.vercel.app/catalog/mainnet) for approval. 

```cadence

pub fun resolveView(_ type: Type): AnyStruct? {
	switch type {

		// Example for NFTCollectionDisplay 
		case Type<MetadataViews.NFTCollectionDisplay>() : 

			return MetadataViews.NFTCollectionDisplay(
            name: collection name,  // Type<String>
            description: collection description,  // Type<String>
            externalURL: External url of the collection,  // Type<MetadataViews.ExternalURL>
            squareImage: square image,  // Type<MetadataViews.ExternalURL>
            bannerImage: banner image,  // Type<MetadataViews.ExternalURL>
            socials: { 
				"Twitter" : ExternalURL ,
				"Discord" : ExternalURL ,
				"Instagram" : ExternalURL ,
				"Facebook" : ExternalURL ,
				"TikTok" : ExternalURL ,
				"LinkedIn" : ExternalURL 
			}                           // Type<{String : MetadataViews.ExternalURL}>
			)

	}
}

```


![MetadataViews.CollectionDisplay](/images/collectionDisplay.png "CollectionDisplay")

| Param      | Description |
| ----------- | ----------- |
| name   | Name of the NFT Collection        |
| description      | Human readable description of the NFT Collection      |
| externalURL      | The external url to the NFT Collection       |
| squareImage      | A square image that represent the NFT Collection    |
| bannerImage      | A 2 : 1 banner image that represent the NFT Collection  |
| socials      | Social links to your media       |
