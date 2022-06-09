import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11

/* NFTRegistry */
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"


pub fun main(user: String) : CollectionReport?{
	return fetchNFTRegistryCollection(user: user, collectionIDs: {"Dandy": [
            // 96939388,
            // 96953249,
            // 96939382,
            // 96968935,
            // 96953256,
            // 96953259,
            // 96939373,
            // 96953255,
            // 96968791,
            96968792,
            96968790
        ]})
	// return fetchNFTRegistry(user: user, maxItems: 2)
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


    pub fun fetchNFTRegistryCollection(user: String, collectionIDs: {String : [UInt64]}) : CollectionReport? {

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
                let display= FindViews.getDisplay(nft) 
                if display == nil { continue }

                var externalUrl=nftInfo!.externalFixedUrl
                if let externalUrlViw=FindViews.getExternalURL(nft) { 
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

                let item = MetadataCollectionItem(
                    id: id,
                    type: nft.getType() ,
                    uuid: nft.uuid ,
                    name: display!.name,
                    image: display!.thumbnail.uri(),
                    url: externalUrl,
                    contentTypes: contentTypes,
                    rarity: rarity,
                    media: media,
                    collection: nftInfo!.alias,
                    subCollection: nftInfo!.alias, 
                    tag: tag,
                    scalar: scalar
                )
                collectionItems.append(item)

            }

            if collectionItems.length > 0 {
                items[nftInfo!.alias] = collectionItems 
            }
        }
        return CollectionReport(items: items,  collections : [], extraIDs : {})
    }

	pub fun getMedias(_ viewResolver: &{MetadataViews.Resolver}) : FindViews.Medias? {
		if let view = viewResolver.resolveView(Type<FindViews.Medias>()) {
			if let v = view as? FindViews.Medias {
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

    pub fun fetchNFTRegistry(user: String, maxItems: Int) : CollectionReport? {

        let account = resolveAddress(user: user)
        if account == nil { return nil }

        var counter = 0
        var fetchItem : Bool = true

        let items : {String : [MetadataCollectionItem]} = {}
        let collections : [String] = []
        let extraIDs : {String : [UInt64]} = {}

	    for nftInfo in NFTRegistry.getNFTInfoAll().values {
	    	let resolverCollectionCap= account!.getCapability<&{MetadataViews.ResolverCollection}>(nftInfo.publicPath)
            if !resolverCollectionCap.check() { continue }
            
            let collectionRef = resolverCollectionCap.borrow()!

            collections.append(nftInfo.alias)

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
                let display= FindViews.getDisplay(nft) 
                if display == nil { continue }

                var externalUrl=nftInfo.externalFixedUrl
                if let externalUrlViw=FindViews.getExternalURL(nft) { 
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
                if let sc= FindViews.getNFTCollectionDisplay(nft) {
                    subCollection=sc.name
                }	

                let item = MetadataCollectionItem(
                    id: id,
                    type: nft.getType() ,
                    uuid: nft.uuid ,
                    name: display!.name,
                    image: display!.thumbnail.uri(),
                    url: externalUrl,
                    contentTypes: contentTypes,
                    rarity: rarity,
                    media: media,
                    collection: nftInfo.alias,
                    subCollection: nftInfo.alias, 
                    tag: tag,
                    scalar: scalar
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