import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

// /* Alchemy Mainnet Wrapper */
// import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

// /* Alchemy Testnet Wrapper */

// import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11

pub fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
    return fetchAlchemyCollectionShard3(user: user, collectionIDs: collectionIDs)
}

    pub struct CollectionReport {
        pub let items : {String : [MetadataCollectionItem]}
        pub let collections : {String : Int} // mapping of collection to no. of ids
        pub let extraIDs : {String : [UInt64]}

        init(items: {String : [MetadataCollectionItem]},  collections : {String : Int}, extraIDs : {String : [UInt64]} ) {
            self.items=items
            self.collections=collections
            self.extraIDs=extraIDs
        }
    }

    pub struct MetadataCollectionItem {
        pub let id:UInt64
        pub let uuid:UInt64?
        pub let name: String
        pub let collection: String // <- This will be Alias unless they want something else
        pub let project: String

        pub let media  : String
        pub let mediaType : String
        pub let source : String

        init(id:UInt64, uuid: UInt64?, name: String, collection: String, media  : String, mediaType : String, source : String, project: String) {
            self.id=id
            self.name=name
			self.uuid=uuid
            self.collection=collection
            self.media=media
            self.mediaType=mediaType
            self.source=source
            self.project=project
        }
    }

    // Helper function

    pub fun resolveAddress(user: String) : PublicAccount? {
	    let address = FIND.resolve(user)
	    if address == nil {
	    	return nil
	    }
        return getAccount(address!)
    }


    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 3
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard3(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
        let source = "getNFTDetailsShard3"
        let account = resolveAddress(user: user)
        if account == nil { return {} }
        if account!.balance == 0.0 {
		    return {}
	    }

        let items : {String : [MetadataCollectionItem]} = {}

        let fetchingIDs = collectionIDs

        for project in fetchingIDs.keys {
            // For passing bugs
            if project == "Xtingles_NFT" {
                fetchingIDs["Xtingles"] = fetchingIDs.remove(key: project)
            }

            if project == "RCRDSHPNFT" {
                fetchingIDs.remove(key: project)
            }
        }

        for project in fetchingIDs.keys {
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard3.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

            var collectionItems : [MetadataCollectionItem] = []
            for nft in returnedNFTs {
                if nft == nil {
                    continue
                }

                var media = ""
                var mediaType = ""
                if nft!.media.length > 0 && nft!.media[0]?.uri != nil {
                    let m = nft!.media[0]!
                    mediaType = m.mimetype ?? ""
                    media = m.uri!
                }

                let item = MetadataCollectionItem(
                    id: nft!.id,
					uuid: nft!.uuid,
                    name: nft!.title ?? "",
                    collection: project,
                    media: media,
                    mediaType: mediaType,
                    source: source,
                    project: project
                )
                collectionItems.append(item)
            }

            if collectionItems.length > 0 {
                items[project] = collectionItems
            }
        }
        return items
    }

