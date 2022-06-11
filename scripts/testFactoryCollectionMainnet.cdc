import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

/* NFTRegistry */
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"


pub fun main(user: String) : AnyStruct {
    // let ids : {String : [UInt64]} = {"Mynft": [
    //         27226,
    //         13958
    //     ]}

	// return fetchAlchemyCollectionShard1(user: user, collectionIDs: ids)
	return fetchAlchemyShard1(user: user, maxItems: 2, targetCollections: ["TuneGO"])
    // let account = resolveAddress(user: user)
    // if account == nil { return nil }
    // let a1 = fetchAlchemyShard1(user: user, maxItems: 200)
    // let a2 = fetchAlchemyShard2(user: user, maxItems: 200)
    // let a3 = fetchAlchemyShard3(user: user, maxItems: 200)
    // let a4 = fetchAlchemyShard4(user: user, maxItems: 200)

    // for project in a2!.items.keys {
    //     a1!.items.insert(key: project, a2!.items.remove(key: project)!) 
    // }

    // for project in a3!.items.keys {
    //     a1!.items.insert(key: project, a3!.items.remove(key: project)!) 
    // }

    // for project in a4!.items.keys {
    //     a1!.items.insert(key: project, a4!.items.remove(key: project)!) 
    // }

    // return a1
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
        pub let subCollection: String // <- This will be Alias unless they want something else

        pub let media  : String
        pub let mediaType : String 
        pub let source : String 

        // Depend on discussion outcome 
        // pub let url: String
        // pub let contentTypes:[String]
        // pub let rarity:String
        //Refine later 
        pub let extra: {String : AnyStruct}
        // pub let scalar: {String : UFix64}
        pub let alchemy: AnyStruct
        init(id:UInt64, name: String, collection: String, subCollection: String, media  : String, mediaType : String, source : String ,extra: {String : AnyStruct}, alchemy: AnyStruct) {
            self.id=id
            self.name=name 
            self.collection=collection 
            self.subCollection=subCollection 
            self.media=media 
            self.mediaType=mediaType 
            self.source=source 
            self.extra=extra
            self.alchemy=alchemy
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

    pub fun byPassBug(_ fetchingIDs: {String : [UInt64]}) : {String : [UInt64]} {
        for project in fetchingIDs.keys {
            // For passing bugs
            if project == "Xtingles_NFT" {
                fetchingIDs["Xtingles"] = fetchingIDs.remove(key: project)
            }

            if project == "RCRDSHPNFT" {
                fetchingIDs.remove(key: project)
            }

            if project.length > "MintStoreItem".length && project.slice(from: 0, upTo: "MintStoreItem".length) == "MintStoreItem" {
                fetchingIDs["MintStoreItem"] = fetchingIDs.remove(key: project)
            }
        }
        return fetchingIDs
    }

    pub fun fetchAlchemyCollectionShard1(user: String, collectionIDs: {String : [UInt64]}) : CollectionReport? {
        let source = "Alchemy-shard1"
        let account = resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let fetchingIDs = byPassBug(collectionIDs)

        

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
                } 

                var medias : MetadataViews.Media? = nil
                var media = ""
                if nft!.media.length > 0 && nft!.media[0]?.uri != nil {
                    let m = nft!.media[0]!
                    let mediaType = m.mimetype ?? ""
                    medias = MetadataViews.Media(file: MetadataViews.HTTPFile(url: m.uri! ), mediaType: mediaType)
                    media = m.uri!
                }

                var contentType = ""
                for m in nft!.media {
                    if m != nil && m!.mimetype != nil {
                        contentType= m!.mimetype!
                        break
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

                let extra : {String : AnyStruct} = {}
                extra["uuid"] = nft!.uuid
                extra["url"] = nft!.token_uri ?? ""
                extra["medias"] = medias
                extra["metadata"] = tag

                let item = MetadataCollectionItem(
                    id: nft!.id,
                    name: nft!.title ?? "",
                    collection: nft!.contract.name,
                    subCollection: "", 
                    media: media,
                    mediaType: contentType,
                    source: source,
                    extra: extra, 
                    alchemy: nft
                )
                collectionItems.append(item)
            }

            if collectionItems.length > 0 {
                items[project] = collectionItems
            }
        }
        return CollectionReport(items: items,  collections : {}, extraIDs : {})
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

    pub fun fetchAlchemyShard1(user: String, maxItems: Int, targetCollections: [String]) : CollectionReport? {
        let source = "Alchemy-shard1"
        let account = resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        var extraIDs = AlchemyMetadataWrapperMainnetShard1.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
        }

        extraIDs = byPassBug(extraIDs)

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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard1.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

            var collectionItems : [MetadataCollectionItem] = []
            for nft in returnedNFTs {
                if nft == nil {
                    continue
                }

                var url = ""
                if nft!.external_domain_view_url != nil {
                    url = nft!.external_domain_view_url!
                } 

                var medias : MetadataViews.Media? = nil
                var media = ""
                if nft!.media.length > 0 && nft!.media[0]?.uri != nil {
                    let m = nft!.media[0]!
                    let mediaType = m.mimetype ?? ""
                    medias = MetadataViews.Media(file: MetadataViews.HTTPFile(url: m.uri! ), mediaType: mediaType)
                    media = m.uri!
                }

                var contentType = ""
                for m in nft!.media {
                    if m != nil && m!.mimetype != nil {
                        contentType= m!.mimetype!
                        break
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

                let extra : {String : AnyStruct} = {}
                extra["uuid"] = nft!.uuid
                extra["url"] = nft!.token_uri ?? ""
                extra["medias"] = medias
                extra["metadata"] = tag

                let item = MetadataCollectionItem(
                    id: nft!.id,
                    name: nft!.title ?? "",
                    collection: nft!.contract.name,
                    subCollection: "", 
                    media: media,
                    mediaType: contentType,
                    source: source,
                    extra: extra, 
                    alchemy: nft
                )
                collectionItems.append(item)
            }

            if collectionItems.length > 0 {
                items[project] = collectionItems
            }
        }
        return CollectionReport(items: items,  collections : collections, extraIDs : extraIDs)
    }
/* 
    pub fun fetchAlchemyShard2(user: String, maxItems: Int) : CollectionReport? {
        let source = "Alchemy-shard2"

        let account = resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        var extraIDs = AlchemyMetadataWrapperMainnetShard2.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
        }

        extraIDs = byPassBug(extraIDs)

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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard2.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

            var collectionItems : [MetadataCollectionItem] = []
            for nft in returnedNFTs {
                if nft == nil {
                    continue
                }

                var url = ""
                if nft!.external_domain_view_url != nil {
                    url = nft!.external_domain_view_url!
                } 

                var medias : MetadataViews.Media? = nil
                var media = ""
                if nft!.media.length > 0 && nft!.media[0]?.uri != nil {
                    let m = nft!.media[0]!
                    let mediaType = m.mimetype ?? ""
                    medias = MetadataViews.Media(file: MetadataViews.HTTPFile(url: m.uri! ), mediaType: mediaType)
                    media = m.uri!
                }

                var contentType = ""
                for m in nft!.media {
                    if m != nil && m!.mimetype != nil {
                        contentType= m!.mimetype!
                        break
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

                let extra : {String : AnyStruct} = {}
                extra["uuid"] = nft!.uuid
                extra["url"] = nft!.token_uri ?? ""
                extra["medias"] = medias
                extra["metadata"] = tag

                let item = MetadataCollectionItem(
                    id: nft!.id,
                    name: nft!.title ?? "",
                    collection: nft!.contract.name,
                    subCollection: "", 
                    media: media,
                    mediaType: contentType,
                    source: source,
                    extra: extra, 
                    alchemy: nft
                )
                collectionItems.append(item)
                collectionItems.append(item)
            }

            if collectionItems.length > 0 {
                items[project] = collectionItems
            }
        }
        return CollectionReport(items: items,  collections : collections, extraIDs : extraIDs)
    }

    pub fun fetchAlchemyShard3(user: String, maxItems: Int) : CollectionReport? {
        let source = "Alchemy-shard3"

        let account = resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        var extraIDs = AlchemyMetadataWrapperMainnetShard3.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
        }

        extraIDs = byPassBug(extraIDs)

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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard3.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

            var collectionItems : [MetadataCollectionItem] = []
            for nft in returnedNFTs {
                if nft == nil {
                    continue
                }

                var url = ""
                if nft!.external_domain_view_url != nil {
                    url = nft!.external_domain_view_url!
                } 

                var medias : MetadataViews.Media? = nil
                var media = ""
                if nft!.media.length > 0 && nft!.media[0]?.uri != nil {
                    let m = nft!.media[0]!
                    let mediaType = m.mimetype ?? ""
                    medias = MetadataViews.Media(file: MetadataViews.HTTPFile(url: m.uri! ), mediaType: mediaType)
                    media = m.uri!
                }

                var contentType = ""
                for m in nft!.media {
                    if m != nil && m!.mimetype != nil {
                        contentType= m!.mimetype!
                        break
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

                let extra : {String : AnyStruct} = {}
                extra["uuid"] = nft!.uuid
                extra["url"] = nft!.token_uri ?? ""
                extra["medias"] = medias
                extra["metadata"] = tag

                let item = MetadataCollectionItem(
                    id: nft!.id,
                    name: nft!.title ?? "",
                    collection: nft!.contract.name,
                    subCollection: "", 
                    media: media,
                    mediaType: contentType,
                    source: source,
                    extra: extra, 
                    alchemy: nft
                )
                collectionItems.append(item)
            }

            if collectionItems.length > 0 {
                items[project] = collectionItems
            }
        }
        return CollectionReport(items: items,  collections : collections, extraIDs : extraIDs)
    }

    pub fun fetchAlchemyShard4(user: String, maxItems: Int) : CollectionReport? {
        let source = "Alchemy-shard4"

        let account = resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        var extraIDs = AlchemyMetadataWrapperMainnetShard4.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
        }

        extraIDs = byPassBug(extraIDs)

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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard4.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

            var collectionItems : [MetadataCollectionItem] = []
            for nft in returnedNFTs {
                if nft == nil {
                    continue
                }

                var url = ""
                if nft!.external_domain_view_url != nil {
                    url = nft!.external_domain_view_url!
                } 

                var medias : MetadataViews.Media? = nil
                var media = ""
                if nft!.media.length > 0 && nft!.media[0]?.uri != nil {
                    let m = nft!.media[0]!
                    let mediaType = m.mimetype ?? ""
                    medias = MetadataViews.Media(file: MetadataViews.HTTPFile(url: m.uri! ), mediaType: mediaType)
                    media = m.uri!
                }

                var contentType = ""
                for m in nft!.media {
                    if m != nil && m!.mimetype != nil {
                        contentType= m!.mimetype!
                        break
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

                let extra : {String : AnyStruct} = {}
                extra["uuid"] = nft!.uuid
                extra["url"] = nft!.token_uri ?? ""
                extra["medias"] = medias
                extra["metadata"] = tag

                let item = MetadataCollectionItem(
                    id: nft!.id,
                    name: nft!.title ?? "",
                    collection: nft!.contract.name,
                    subCollection: "", 
                    media: media,
                    mediaType: contentType,
                    source: source,
                    extra: extra, 
                    alchemy: nft
                )
                collectionItems.append(item)
            }

            if collectionItems.length > 0 {
                items[project] = collectionItems
            }
        }
        return CollectionReport(items: items,  collections : collections, extraIDs : extraIDs)
    }
    */