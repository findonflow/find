import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
// /* Alchemy Mainnet Wrapper */
// import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

// /* Alchemy Testnet Wrapper */

// import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11




    pub fun main(user: String, maxItems: Int, collections: [String]) : {String : ItemReport}  {
        return fetchAlchemyShard4(user: user, maxItems: maxItems, targetCollections:collections)
    }


    pub struct ItemReport {
        pub let items : [MetadataCollectionItem]
        pub let length : Int // mapping of collection to no. of ids 
        pub let extraIDs : [UInt64]
        pub let shard : String 

        init(items: [MetadataCollectionItem],  length : Int, extraIDs :[UInt64] , shard: String) {
            self.items=items 
            self.length=length 
            self.extraIDs=extraIDs
            self.shard=shard
        }
    }

    pub struct MetadataCollectionItem {
        pub let id:UInt64
        pub let name: String
        pub let collection: String // <- This will be Alias unless they want something else
        pub let subCollection: String? // <- This will be Alias unless they want something else
        pub let nftDetailIdentifier: String

        pub let media  : String
        pub let mediaType : String 
        pub let source : String 

        init(id:UInt64, name: String, collection: String, subCollection: String?, media  : String, mediaType : String, source : String, nftDetailIdentifier: String) {
            self.id=id
            self.name=name 
            self.collection=collection 
            self.subCollection=subCollection 
            self.media=media 
            self.mediaType=mediaType 
            self.source=source
            self.nftDetailIdentifier=nftDetailIdentifier
        }
    }

    // Helper function 

    pub fun resolveAddress(user: String) : Address? {
	    return FIND.resolve(user)
    }


    pub fun fetchAlchemyShard4(user: String, maxItems: Int, targetCollections: [String]) : {String : ItemReport} {
        let source = "Shard4"
        let account = resolveAddress(user: user)
        if account == nil { return {} }


        let extraIDs = AlchemyMetadataWrapperMainnetShard4.getNFTIDs(ownerAddress: account!)
        let inventory : {String : ItemReport} = {}
        var fetchedCount : Int = 0

        // For by-passing bugs

        if extraIDs["MintStoreItem.NBA ALL STAR "] != nil { // who the hell put a space at the end of the string
            extraIDs["MintStoreItem"] = extraIDs.remove(key: "MintStoreItem.NBA ALL STAR ")
        }


        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
                continue
            }
            
            let collectionLength = extraIDs[project]!.length

            // by pass if this is not the target collection
            if targetCollections.length > 0 && !targetCollections.contains(project) {
                // inventory[project] = ItemReport(items: [],  length : collectionLength, extraIDs :extraIDs[project]! , shard: source)
                continue
            }

            
            if fetchedCount >= maxItems {
                inventory[project] = ItemReport(items: [],  length : collectionLength, extraIDs :extraIDs[project]! , shard: source)
                continue
            }

            var fetchArray : [UInt64] = []
            if extraIDs[project]!.length + fetchedCount > maxItems {
                while fetchedCount < maxItems {
                    fetchArray.append(extraIDs[project]!.remove(at: 0))
                    fetchedCount = fetchedCount + 1
                }
            }else {
                fetchArray = extraIDs.remove(key: project)! 
                fetchedCount = fetchedCount + fetchArray.length
            }

            let returnedNFTs = AlchemyMetadataWrapperMainnetShard4.getNFTs(ownerAddress: account!, ids: {project : fetchArray})

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
                    collection: project,
                    subCollection: nil, 
                    media: media,
                    mediaType: mediaType,
                    source: source ,
                    nftDetailIdentifier: project
                )
                collectionItems.append(item)

            }
            inventory[project] = ItemReport(items: collectionItems,  length : collectionLength, extraIDs :extraIDs[project] ?? [] , shard: source)

        }

        return inventory

    }

