import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11

/* NFTRegistry */
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"


pub fun main(user: String) : CollectionReport?{
	// return fetchNFTRegistryCollection(user: user, collectionIDs: {"Dandy": [
    //         // 96939388,
    //         // 96953249,
    //         // 96939382,
    //         // 96968935,
    //         // 96953256,
    //         // 96953259,
    //         // 96939373,
    //         // 96953255,
    //         // 96968791,
    //         96968792,
    //         96968790
    //     ]})
	return fetchNFTRegistry(user: user, maxItems: 2, targetCollections:[])
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

        init(id:UInt64, name: String, collection: String, subCollection: String, media  : String, mediaType : String, source : String ,extra: {String : AnyStruct}) {
            self.id=id
            self.name=name 
            self.collection=collection 
            self.subCollection=subCollection 
            self.media=media 
            self.mediaType=mediaType 
            self.source=source 
            self.extra=extra
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


    pub fun fetchNFTRegistryCollection(user: String, collectionIDs: {String : [UInt64]}) : CollectionReport? {
        let source = "NFTRegistry"
        let account = resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}

	    for project in collectionIDs.keys {

            let nftInfo = NFTRegistry.getNFTInfo(project)

            if nftInfo == nil {
                continue
            }

            let collectionItems : [MetadataCollectionItem] = []

	    	let resolverCollectionCap= account!.getCapability<&{MetadataViews.ResolverCollection}>(nftInfo!.publicPath)
            if !resolverCollectionCap.check() { continue }
            
            let collectionRef = resolverCollectionCap.borrow()!

            for id in collectionRef.getIDs() { 

                if !collectionIDs[project]!.contains(id) {
                    continue
                }

                let nft = collectionRef.borrowViewResolver(id: id) 
                let display= MetadataViews.getDisplay(nft) 
                if display == nil { continue }

                var externalUrl=nftInfo!.externalFixedUrl
                if let externalUrlViw=MetadataViews.getExternalURL(nft) { 
                    externalUrl=externalUrlViw.url
                }

                var rarity=""
                if let r = FindViews.getRarity(nft) {
                    rarity=r.rarityName
                }

                var tag : {String : String}={}
                if let t= FindViews.getTags(nft) {
                    tag=t.getTag()
                }			

                var scalar : {String : UFix64}={}
                if let s= getScalar(nft) {
                    scalar=s.getScalar()
                }			

                var media : MetadataViews.Media? = nil
                let contentTypes : [String] = []
                if let m= getMedias(nft) {
                    media=m.items[0]
                    for item in m.items {
                        contentTypes.append(item.mediaType)
                    }
                }	

                var subCollection : String? = nil
                if let sc= getNFTCollectionDisplay(nft) {
                    subCollection=sc.name
                }	

                let extra : {String : AnyStruct} = {}
                extra["type"] = nft.getType() 
                extra["uuid"] = nft.uuid
                extra["url"] = externalUrl
                extra["contentTypes"] = contentTypes
                extra["rarity"] = rarity
                extra["media"] = media
                extra["tag"] = tag
                extra["scalar"] = scalar


                let item = MetadataCollectionItem(
                    id: id,
                    name: display!.name,
                    collection: nftInfo!.alias,
                    subCollection: nftInfo!.alias, 
                    media: display!.thumbnail.uri(),
                    mediaType: "image",
                    source: source , 
                    extra: extra 

                )
                collectionItems.append(item)

            }

            if collectionItems.length > 0 {
                items[nftInfo!.alias] = collectionItems 
            }
        }
        return CollectionReport(items: items,  collections : {}, extraIDs : {})
    }

	pub fun getMedias(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.Medias? {
		if let view = viewResolver.resolveView(Type<MetadataViews.Medias>()) {
			if let v = view as? MetadataViews.Medias {
				return v
			}
		}
		return nil
	}

	pub fun getNFTCollectionDisplay(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.NFTCollectionDisplay? {
		if let view = viewResolver.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) {
			if let v = view as? MetadataViews.NFTCollectionDisplay {
				return v
			}
		}
		return nil
	}

    pub fun getScalar(_ viewResolver: &{MetadataViews.Resolver}) : FindViews.Scalar? {
		if let view = viewResolver.resolveView(Type<FindViews.Scalar>()) {
			if let v = view as? FindViews.Scalar {
				return v
			}
		}
		return nil
	}

    pub fun fetchNFTRegistry(user: String, maxItems: Int, targetCollections:[String]) : CollectionReport? {
        let source = "NFTRegistry"
        let account = resolveAddress(user: user)
        if account == nil { return nil }

        var counter = 0
        var fetchItem : Bool = true

        let items : {String : [MetadataCollectionItem]} = {}
        let collections : {String : Int} = {}
        let extraIDs : {String : [UInt64]} = {}

	    for nftInfo in NFTRegistry.getNFTInfoAll().values {
	    	let resolverCollectionCap= account!.getCapability<&{MetadataViews.ResolverCollection}>(nftInfo.publicPath)
            if !resolverCollectionCap.check() { continue }
            
            let collectionRef = resolverCollectionCap.borrow()!

            // by pass if this is not the target collection
            if targetCollections.length >0 && !targetCollections.contains(nftInfo.alias) {
                collections.insert(key: nftInfo.alias, collectionRef.getIDs().length)
                extraIDs[nftInfo.alias] = collectionRef.getIDs()
                continue
            }

            // insert collection
            collections.insert(key: nftInfo.alias, collectionRef.getIDs().length)

            // if max items reached, will not fetch more items 

            if !fetchItem {
                extraIDs[nftInfo.alias] = collectionRef.getIDs()
                continue
            }

            let collectionItems : [MetadataCollectionItem] = []
            let collectionExtraIDs : [UInt64] = []

            for id in collectionRef.getIDs() { 

                if !fetchItem {
                    collectionExtraIDs.append(id)
                    continue
                }

                let nft = collectionRef.borrowViewResolver(id: id) 
                let display= MetadataViews.getDisplay(nft) 
                if display == nil { continue }

                var externalUrl=nftInfo.externalFixedUrl
                if let externalUrlViw=MetadataViews.getExternalURL(nft) { 
                    externalUrl=externalUrlViw.url
                }

                var rarity=""
                if let r = FindViews.getRarity(nft) {
                    rarity=r.rarityName
                }

                var tag : {String : String}={}
                if let t= FindViews.getTags(nft) {
                    tag=t.getTag()
                }			

                var scalar : {String : UFix64}={}
                if let s= getScalar(nft) {
                    scalar=s.getScalar()
                }			

                var media : MetadataViews.Media? = nil
                let contentTypes : [String] = []
                if let m= getMedias(nft) {
                    media=m.items[0]
                    for item in m.items {
                        contentTypes.append(item.mediaType)
                    }
                }	

                var subCollection : String? = nil
                if let sc= MetadataViews.getNFTCollectionDisplay(nft) {
                    subCollection=sc.name
                }	

                let extra : {String : AnyStruct} = {}
                extra["type"] = nft.getType() 
                extra["uuid"] = nft.uuid
                extra["url"] = externalUrl
                extra["contentTypes"] = contentTypes
                extra["rarity"] = rarity
                extra["media"] = media
                extra["tag"] = tag
                extra["scalar"] = scalar


                let item = MetadataCollectionItem(
                    id: id,
                    name: display!.name,
                    collection: nftInfo!.alias,
                    subCollection: nftInfo!.alias, 
                    media: display!.thumbnail.uri(),
                    mediaType: "image",
                    source: source , 
                    extra: extra 

                )
                collectionItems.append(item)

                counter = counter + 1
                if counter >= maxItems {
                    fetchItem = false
                }
            }
            if collectionExtraIDs.length > 0 {
                extraIDs[nftInfo.alias] = collectionExtraIDs 
            }

            if collectionItems.length > 0 {
                items[nftInfo.alias] = collectionItems 
            }
        }
        return CollectionReport(items: items,  collections : collections, extraIDs : extraIDs)
    }