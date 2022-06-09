import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

/* NFTRegistry */
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"


pub fun main(user: String) : CollectionReport?{
	return fetchAlchemyCollectionShard1(user: user, collectionIDs: {"Mynft": [
            27226,
            16931,
            27271,
            13958
        ]})
	// return fetchAlchemyShard1(user: user, maxItems: 2)
}



    pub struct CollectionReport {
        pub let items : {String : [MetadataCollectionItem]} 
        pub let collections : [String] 
        pub let extraIDs : {String : [UInt64]} 

        init(items: {String : [MetadataCollectionItem]},  collections : [String], extraIDs : {String : [UInt64]} ) {
            self.items=items 
            self.collections=collections 
            self.extraIDs=extraIDs
        }
    }

    pub struct MetadataCollectionItem {
        pub let id:UInt64
        pub let uuid: UInt64?
        pub let name: String
        pub let image: String
        pub let collection: String // <- This will be Alias unless they want something else
        pub let subCollection: String? // <- This will be Alias unless they want something else
        pub let media: MetadataViews.Media? // <- This will only fetch the first media 

        // Depend on discussion outcome 
        pub let url: String
        pub let contentTypes:[String]
        pub let rarity:String
        pub let typeIdentifier: String
        //Refine later 
        pub let tag: {String : String}
        pub let scalar: {String : UFix64}

        init(id:UInt64, type: Type, uuid: UInt64?, name:String, image:String, url:String, contentTypes: [String], rarity: String, media: MetadataViews.Media?, collection: String, subCollection: String?, tag: {String : String}, scalar: {String : UFix64}) {
            self.id=id
            self.typeIdentifier = type.identifier
            self.uuid = uuid
            self.name=name
            self.url=url
            self.image=image
            self.contentTypes=contentTypes
            self.rarity=rarity
            self.media=media
            self.collection=collection
            self.subCollection=subCollection
            self.tag=tag
            self.scalar=scalar
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


    pub fun fetchAlchemyCollectionShard1(user: String, collectionIDs: {String : [UInt64]}) : CollectionReport? {

        let account = resolveAddress(user: user)
        if account == nil { return nil }

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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard1.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

            var collectionItems : [MetadataCollectionItem] = []
            for nft in returnedNFTs {
                if nft == nil {
                    continue
                }

                var url = ""
                if nft!.external_domain_view_url != nil {
                    url = nft!.external_domain_view_url!
                } else if nft!.media.length > 0 {
                    url = nft!.media[0]?.uri ?? ""
                }

                var media : MetadataViews.Media? = nil
                if nft!.media.length > 0 && nft!.media[0]?.uri != nil {
                    let m = nft!.media[0]!
                    let mediaType = m.mimetype ?? ""
                    media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: m.uri! ), mediaType: mediaType)
                }

                var contentTypes : [String] = []
                for m in nft!.media {
                    if m != nil && m!.mimetype != nil {
                        contentTypes.append(m!.mimetype!)
                    }
                }
                
                var tag : {String : String} = {}
                for d in nft!.metadata.keys {
                    if nft!.metadata[d]! != nil {
                        tag[d] = nft!.metadata[d]!
                    } else {
                        tag[d] = ""
                    }
                }

                let item = MetadataCollectionItem(
                    id: nft!.id,
                    type: nft!.getType() , // This is not useful 
                    uuid: nft!.uuid ,      // This has to be optional 
                    name: nft!.title ?? "",
                    image: url,
                    url: nft!.token_uri ?? "",
                    contentTypes: contentTypes,
                    rarity: "",
                    media: media,
                    collection: nft!.contract.name,
                    subCollection: "", 
                    tag: tag,
                    scalar: {}
                )
                collectionItems.append(item)
            }

            if collectionItems.length > 0 {
                items[project] = collectionItems
            }
        }
        return CollectionReport(items: items,  collections : [], extraIDs : {})
    }

	// pub fun getMedias(_ viewResolver: &{MetadataViews.Resolver}) : FindViews.Medias? {
	// 	if let view = viewResolver.resolveView(Type<FindViews.Medias>()) {
	// 		if let v = view as? FindViews.Medias {
	// 			return v
	// 		}
	// 	}
	// 	return nil
	// }

	// pub fun getNFTCollectionDisplay(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.NFTCollectionDisplay? {
	// 	if let view = viewResolver.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) {
	// 		if let v = view as? MetadataViews.NFTCollectionDisplay {
	// 			return v
	// 		}
	// 	}
	// 	return nil
	// }

	    pub fun fetchAlchemyShard1(user: String, maxItems: Int) : CollectionReport? {

        let account = resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard1.getNFTIDs(ownerAddress: account!.address)

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

        let collections : [String] = extraIDs.keys
        let fetchingIDs : {String : [UInt64]} = {}
        var fetchedCount : Int = 0
        for project in extraIDs.keys {
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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard1.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

            var collectionItems : [MetadataCollectionItem] = []
            for nft in returnedNFTs {
                if nft == nil {
                    continue
                }

                var url = ""
                if nft!.external_domain_view_url != nil {
                    url = nft!.external_domain_view_url!
                } else if nft!.media.length > 0 {
                    url = nft!.media[0]?.uri ?? ""
                }

                var media : MetadataViews.Media? = nil
                if nft!.media.length > 0 && nft!.media[0]?.uri != nil {
                    let m = nft!.media[0]!
                    let mediaType = m.mimetype ?? ""
                    media = MetadataViews.Media(file: MetadataViews.HTTPFile(url: m.uri! ), mediaType: mediaType)
                }

                var contentTypes : [String] = []
                for m in nft!.media {
                    if m != nil && m!.mimetype != nil {
                        contentTypes.append(m!.mimetype!)
                    }
                }
                
                var tag : {String : String} = {}
                for d in nft!.metadata.keys {
                    if nft!.metadata[d]! != nil {
                        tag[d] = nft!.metadata[d]!
                    } else {
                        tag[d] = ""
                    }
                }

                let item = MetadataCollectionItem(
                    id: nft!.id,
                    type: nft!.getType() , // This is not useful 
                    uuid: nft!.uuid ,      // This has to be optional 
                    name: nft!.title ?? "",
                    image: url,
                    url: nft!.token_uri ?? "",
                    contentTypes: contentTypes,
                    rarity: "",
                    media: media,
                    collection: nft!.contract.name,
                    subCollection: "", 
                    tag: tag,
                    scalar: {}
                )
                collectionItems.append(item)
            }

            if collectionItems.length > 0 {
                items[project] = collectionItems
            }
        }
        return CollectionReport(items: items,  collections : collections, extraIDs : extraIDs)
    }