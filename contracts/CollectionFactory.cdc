/* Alchemy Mainnet Wrapper */
import AlchemyMetadataWrapperMainnet from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

// /* Alchemy Testnet Wrapper */
// import AlchemyMetadataWrapperTestnetfrom 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11

/* NFTRegistry */
import NFTRegistry from "../contracts/NFTRegistry.cdc"

import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"

pub contract CollectionFactory {

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

    //////////////////////////////////////////////////////////////
    // Get all collections with ignoreItems that can be sent in
    //////////////////////////////////////////////////////////////
    pub fun getCollections(user: String, maxItems: Int, shard: String, ignoreItems: {String : [UInt64]}) : CollectionReport? {
        switch shard {
            case "Alchemy-shard1": 
                return self.fetchAlchemyShard1(user: user, maxItems: maxItems, ignoreItems: ignoreItems)
            case "Alchemy-shard2": 
                return self.fetchAlchemyShard2(user: user, maxItems: maxItems, ignoreItems: ignoreItems)
            case "Alchemy-shard3": 
                return self.fetchAlchemyShard3(user: user, maxItems: maxItems, ignoreItems: ignoreItems)
            case "Alchemy-shard4": 
                return self.fetchAlchemyShard4(user: user, maxItems: maxItems, ignoreItems: ignoreItems)
            case "NFTRegistry": 
                return self.fetchNFTRegistry(user: user, maxItems: maxItems, ignoreItems: ignoreItems)


        }
            panic("Shard should only be : Alchemy-shard1, Alchemy-shard2,Alchemy-shard3,Alchemy-shard4 or NFTRegistry")
    }

    //////////////////////////////////////////////////////////////
    // Get specific collections 
    //////////////////////////////////////////////////////////////
    pub fun getCollection(user: String, maxItems: Int, shard: String, collection: [String]) : CollectionReport? {
        switch shard {
            case "Alchemy-shard1": 
                return self.fetchAlchemyCollectionShard1(user: user, maxItems: maxItems, collection: collection)
            case "Alchemy-shard2": 
                return self.fetchAlchemyCollectionShard2(user: user, maxItems: maxItems, collection: collection)
            case "Alchemy-shard3": 
                return self.fetchAlchemyCollectionShard3(user: user, maxItems: maxItems, collection: collection)
            case "Alchemy-shard4": 
                return self.fetchAlchemyCollectionShard4(user: user, maxItems: maxItems, collection: collection)
            case "NFTRegistry": 
                return self.fetchNFTRegistryCollection(user: user, maxItems: maxItems, collection: collection)


        }
            panic("Shard should only be : Alchemy-shard1, Alchemy-shard2,Alchemy-shard3,Alchemy-shard4 or NFTRegistry")
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
    // Fetch All Collections in NFTRegistry
    //////////////////////////////////////////////////////////////
    pub fun fetchNFTRegistry(user: String, maxItems: Int, ignoreItems: {String : [UInt64]}) : CollectionReport? {

        let account = self.resolveAddress(user: user)
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

            var ignoreItem = false
            if ignoreItems.containsKey(nftInfo.alias) {
                ignoreItem = true
            }

            if !fetchItem {
                extraIDs[nftInfo.alias] = collectionRef.getIDs()
                continue
            }

            let collectionItems : [MetadataCollectionItem] = []
            let collectionExtraIDs : [UInt64] = []

            for id in collectionRef.getIDs() { 

                if ignoreItem {
                    if ignoreItems[nftInfo.alias]!.contains(id) {
                        continue
                    }
                }

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
                if let s= FindViews.getScalar(nft) {
                    scalar=s.getScalar()
                }			

                var media : MetadataViews.Media? = nil
                let contentTypes : [String] = []
                if let m= FindViews.getMedias(nft) {
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

    //////////////////////////////////////////////////////////////
    // Fetch All Collections in Shard 1
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyShard1(user: String, maxItems: Int, ignoreItems: {String : [UInt64]}) : CollectionReport? {

        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard1.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
            if ignoreItems.containsKey(project) {
                var i = 0 
                while i < extraIDs[project]!.length {
                    if ignoreItems[project]!.contains(extraIDs[project]![i]) {
                        extraIDs[project]!.remove(at: i)
                        continue
                    }
                    i = i + 1
                }
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

    //////////////////////////////////////////////////////////////
    // Fetch All Collections in Shard 2
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyShard2(user: String, maxItems: Int, ignoreItems: {String : [UInt64]}) : CollectionReport? {

        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard2.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
            if ignoreItems.containsKey(project) {
                var i = 0 
                while i < extraIDs[project]!.length {
                    if ignoreItems[project]!.contains(extraIDs[project]![i]) {
                        extraIDs[project]!.remove(at: i)
                        continue
                    }
                    i = i + 1
                }
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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard2.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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

    //////////////////////////////////////////////////////////////
    // Fetch All Collections in Shard 3
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyShard3(user: String, maxItems: Int, ignoreItems: {String : [UInt64]}) : CollectionReport? {

        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard3.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
            if ignoreItems.containsKey(project) {
                var i = 0 
                while i < extraIDs[project]!.length {
                    if ignoreItems[project]!.contains(extraIDs[project]![i]) {
                        extraIDs[project]!.remove(at: i)
                        continue
                    }
                    i = i + 1
                }
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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard3.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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

    //////////////////////////////////////////////////////////////
    // Fetch All Collections in Shard 4
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyShard4(user: String, maxItems: Int, ignoreItems: {String : [UInt64]}) : CollectionReport? {

        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard4.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
            if ignoreItems.containsKey(project) {
                var i = 0 
                while i < extraIDs[project]!.length {
                    if ignoreItems[project]!.contains(extraIDs[project]![i]) {
                        extraIDs[project]!.remove(at: i)
                        continue
                    }
                    i = i + 1
                }
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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard4.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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



    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in NFTRegistry
    //////////////////////////////////////////////////////////////
    pub fun fetchNFTRegistryCollection(user: String, maxItems: Int, collection: [String]) : CollectionReport? {

        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        var counter = 0
        var fetchItem : Bool = true

        let items : {String : [MetadataCollectionItem]} = {}
        let collections : [String] = []
        let extraIDs : {String : [UInt64]} = {}

	    for nftInfo in NFTRegistry.getNFTInfoAll().values {

            if !collection.contains(nftInfo.alias) {
                continue
            }

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
                if let s= FindViews.getScalar(nft) {
                    scalar=s.getScalar()
                }			

                var media : MetadataViews.Media? = nil
                let contentTypes : [String] = []
                if let m= FindViews.getMedias(nft) {
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

    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 1
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard1(user: String, maxItems: Int, collection: [String]) : CollectionReport? {

        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard1.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
            if !collection.contains(project) {
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

    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 2
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard2(user: String, maxItems: Int, collection: [String]) : CollectionReport? {

        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard2.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
            if !collection.contains(project) {
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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard2.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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

    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 3
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard3(user: String, maxItems: Int, collection: [String]) : CollectionReport? {

        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard3.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
            if !collection.contains(project) {
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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard3.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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

    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 4
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard4(user: String, maxItems: Int, collection: [String]) : CollectionReport? {

        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard4.getNFTIDs(ownerAddress: account!.address)

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
            }
            if !collection.contains(project) {
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
            let returnedNFTs = AlchemyMetadataWrapperMainnetShard4.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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
}
