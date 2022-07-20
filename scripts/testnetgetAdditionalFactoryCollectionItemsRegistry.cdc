import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"

pub fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
    return fetchNFTRegistryCollection(user: user, collectionIDs: collectionIDs)
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
    // Fetch Specific Collections in NFTRegistry
    //////////////////////////////////////////////////////////////
    pub fun fetchNFTRegistryCollection(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
        let source = "NFTRegistry"
        let account = resolveAddress(user: user)
        if account == nil { return {} }

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

                var subCollection : String? = nil
                if let sc= MetadataViews.getNFTCollectionDisplay(nft) {
                    subCollection=sc.name
                }	

                let item = MetadataCollectionItem(
                    id: id,
                    name: display!.name,
                    collection: nftInfo!.alias,
                    subCollection: subCollection, 
                    media: display!.thumbnail.uri(),
                    mediaType: "image",
                    source: source
                )
                collectionItems.append(item)

            }

            if collectionItems.length > 0 {
                items[nftInfo!.alias] = collectionItems 
            }
        }
        return items
    }