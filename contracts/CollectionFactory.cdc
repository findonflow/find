// /* Alchemy Mainnet Wrapper */
// import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

// /* Alchemy Testnet Wrapper */
// import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11

/* NFTRegistry */
/* In order to deploy this contract on testnet/mainet you have to comment out the code above for the relevant network */
/* Note that if this is changed there are code in tasks/collectionFactoryTest that also must be changed */
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

    /* 
    Raw Response from Alchemy getNFTs()

    [
    {
        "contract": {
            "address": "0xf6fcbef550d97aa5",
            "external_domain": "",
            "name": "Mynft",
            "public_collection_name": "Mynft.MynftCollectionPublic",
            "public_path": "Mynft.CollectionPublicPath",
            "storage_path": "Mynft.CollectionStoragePath"
        },
        "description": "\"Congratulations, you have won the S level Painting \\u{300c}Lightning\\u{300d}! You will be able to apply the painting to your own car after the game launch. This painting series is specifically designed for Flow Fest Mystery Pack event and no other copies will be made ever again. The owners of these NFTs will be regarded as the earliest supporters of the Racing Time. \"",
        "external_domain_view_url": "",
        "id": "27226",
        "media": [
            {
                "mimetype": "image/jpeg",
                "uri": "https://bafybeiacezpbfkmspzkvtrim6ucdczqerzi4miectybtuhaskflov7gipq.ipfs.dweb.link/"
            }
        ],
        "metadata": {
            "MD5Hash": "",
            "arLink": "",
            "artist": "",
            "description": "\"Congratulations, you have won the S level Painting \\u{300c}Lightning\\u{300d}! You will be able to apply the painting to your own car after the game launch. This painting series is specifically designed for Flow Fest Mystery Pack event and no other copies will be made ever again. The owners of these NFTs will be regarded as the earliest supporters of the Racing Time. \"",
            "ipfsLink": "https://bafybeiacezpbfkmspzkvtrim6ucdczqerzi4miectybtuhaskflov7gipq.ipfs.dweb.link/",
            "name": "Lightning",
            "type": "image/jpeg"
        },
        "title": "Lightning",
        "token_uri": "",
        "uuid": "60581263"
    },
    {
        "contract": {
            "address": "0xf6fcbef550d97aa5",
            "external_domain": "",
            "name": "Mynft",
            "public_collection_name": "Mynft.MynftCollectionPublic",
            "public_path": "Mynft.CollectionPublicPath",
            "storage_path": "Mynft.CollectionStoragePath"
        },
        "description": "Mynft is a Flow-based NFT platform designed to connect east and west market, and Mynft specifically launched Chinese Four Symbols themes NFT for Flow Festival. Vermilion Bird is a red bird with a five-colored plumage and is perpetually covered in flames, represents the fire-element, the direction south, and the season summer correspondingly.",
        "external_domain_view_url": "",
        "id": "13958",
        "media": [
            {
                "mimetype": "image/jpg",
                "uri": ""
            }
        ],
        "metadata": {
            "MD5Hash": "19e229e53893e156d6eb901ab75cb78b",
            "arLink": "-MJ1l-82OrTWbye3HWJRAS8Y4UKQV9B6u4T73F4x51c",
            "artist": "",
            "description": "Mynft is a Flow-based NFT platform designed to connect east and west market, and Mynft specifically launched Chinese Four Symbols themes NFT for Flow Festival. Vermilion Bird is a red bird with a five-colored plumage and is perpetually covered in flames, represents the fire-element, the direction south, and the season summer correspondingly.",
            "ipfsLink": "",
            "name": "Vermilion Bird #114",
            "type": "image/jpg"
        },
        "title": "Vermilion Bird #114",
        "token_uri": "",
        "uuid": "60194724"
    }
]
     */

    //////////////////////////////////////////////////////////////
    // Get all collections 
    //////////////////////////////////////////////////////////////
    pub fun getCollections(user: String, maxItems: Int, shard: String) : CollectionReport? {
        switch shard {
            case "Alchemy-shard1": 
                return self.fetchAlchemyShard1(user: user, maxItems: maxItems)
            case "Alchemy-shard2": 
                return self.fetchAlchemyShard2(user: user, maxItems: maxItems)
            case "Alchemy-shard3": 
                return self.fetchAlchemyShard3(user: user, maxItems: maxItems)
            case "Alchemy-shard4": 
                return self.fetchAlchemyShard4(user: user, maxItems: maxItems)
            case "NFTRegistry": 
                return self.fetchNFTRegistry(user: user, maxItems: maxItems)


        }
            panic("Shard should only be : Alchemy-shard1, Alchemy-shard2,Alchemy-shard3,Alchemy-shard4 or NFTRegistry")
    }

    //////////////////////////////////////////////////////////////
    // Get specific collections 
    //////////////////////////////////////////////////////////////
    pub fun getCollection(user: String, collectionIDs: {String : [UInt64]}, shard: String) : {String : [MetadataCollectionItem]} {
        switch shard {
            case "Alchemy-shard1": 
                return self.fetchAlchemyCollectionShard1(user: user, collectionIDs: collectionIDs)
            case "Alchemy-shard2": 
                return self.fetchAlchemyCollectionShard2(user: user, collectionIDs: collectionIDs)
            case "Alchemy-shard3": 
                return self.fetchAlchemyCollectionShard3(user: user, collectionIDs: collectionIDs)
            case "Alchemy-shard4": 
                return self.fetchAlchemyCollectionShard4(user: user, collectionIDs: collectionIDs)
            case "NFTRegistry": 
                return self.fetchNFTRegistryCollection(user: user, collectionIDs: collectionIDs)


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
    pub fun fetchNFTRegistry(user: String, maxItems: Int) : CollectionReport? {

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
    // Fetch All Collections in Shard 1
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyShard1(user: String, maxItems: Int) : CollectionReport? {

        let account = self.resolveAddress(user: user)
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
    pub fun fetchAlchemyShard2(user: String, maxItems: Int) : CollectionReport? {

        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard2.getNFTIDs(ownerAddress: account!.address)

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
    pub fun fetchAlchemyShard3(user: String, maxItems: Int) : CollectionReport? {

        let account = self.resolveAddress(user: user)
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
    pub fun fetchAlchemyShard4(user: String, maxItems: Int) : CollectionReport? {

        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperMainnetShard4.getNFTIDs(ownerAddress: account!.address)

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
    pub fun fetchNFTRegistryCollection(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {

        let account = self.resolveAddress(user: user)
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
        return items
    }

    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 1
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard1(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {

        let account = self.resolveAddress(user: user)
        if account == nil { return {} }

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
        return items
    }

    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 2
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard2(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {

        let account = self.resolveAddress(user: user)
        if account == nil { return {} }

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
        return items
    }

    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 3
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard3(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {

        let account = self.resolveAddress(user: user)
        if account == nil { return {} }

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

                var url = ""
                if nft!.external_domain_view_url != nil {
                    url = nft!.external_domain_view_url!
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
        return items
    }

    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 4
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard4(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {

        let account = self.resolveAddress(user: user)
        if account == nil { return {} }

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
        return items
    }
}
