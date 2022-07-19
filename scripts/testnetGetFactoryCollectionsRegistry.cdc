import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"

pub fun main(user: String, maxItems: Int) : CollectionReport? {
    return fetchNFTRegistry(user: user, maxItems: maxItems, targetCollections:[])
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

                var subCollection : String? = nil
                if let sc= MetadataViews.getNFTCollectionDisplay(nft) {
                    subCollection=sc.name
                }	

                let item = MetadataCollectionItem(
                    id: id,
                    name: display!.name,
                    collection: nftInfo.alias,
                    subCollection: nftInfo.alias, 
                    media: display!.thumbnail.uri(),
                    mediaType: "image",
                    source: source
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