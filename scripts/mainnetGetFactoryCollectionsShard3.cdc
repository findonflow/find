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




pub fun main(user: String, maxItems: Int) : CollectionReport? {
    return fetchAlchemyShard3(user: user, maxItems: maxItems, targetCollections:[])
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
        pub let name: String
        pub let collection: String // <- This will be Alias unless they want something else
        pub let subCollection: String? // <- This will be Alias unless they want something else

        pub let media  : String
        pub let mediaType : String 
        pub let source : String 

        init(id:UInt64, name: String, collection: String, subCollection: String?, media  : String, mediaType : String, source : String) {
            self.id=id
            self.name=name 
            self.collection=collection 
            self.subCollection=subCollection 
            self.media=media 
            self.mediaType=mediaType 
            self.source=source
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
    // Fetch All Collections in Shard 3
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyShard3(user: String, maxItems: Int, targetCollections: [String]) : CollectionReport? {
        let source = "Alchemy-shard3"
        let account = resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard3.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
        }

        for project in extraIDs.keys {
            // For passing bugs
            if project == "Xtingles_NFT" {
                extraIDs["Xtingles"] = extraIDs.remove(key: project)
            }

            if project == "RCRDSHPNFT" {
                extraIDs.remove(key: project)
            }
        }

        let collections : {String : Int} = {}
        for key in extraIDs.keys {
            collections[key] = extraIDs[key]!.length
        }
        let fetchingIDs : {String : [UInt64]} = {}
        var fetchedCount : Int = 0
        for project in extraIDs.keys {

            // by pass if this is not the target collection
            if targetCollections.length > 0 && !targetCollections.contains(project) {
                continue
            }

            if extraIDs[project]!.length + fetchedCount > maxItems {
                let array : [UInt64] = []
                while fetchedCount < maxItems {
                    array.append(extraIDs[project]!.remove(at: 0))
                    fetchedCount = fetchedCount + 1
                }
                if array.length > 0 {
                    fetchingIDs[project] = array
                }
                break
            }

            let array = extraIDs.remove(key: project)! 
            fetchedCount = fetchedCount + array.length
            fetchingIDs[project] = array
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
                    name: nft!.title ?? "",
                    collection: nft!.contract.name,
                    subCollection: "", 
                    media: media,
                    mediaType: mediaType,
                    source: source
                )
                collectionItems.append(item)
            }

            if collectionItems.length > 0 {
                items[project] = collectionItems
            }
        }
        return CollectionReport(items: items,  collections : collections, extraIDs : extraIDs)
    }
		
