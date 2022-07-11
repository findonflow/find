// /* Alchemy Mainnet Wrapper */
// import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

// /* Alchemy Testnet Wrapper */

import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11


/* NFTRegistry */
/* In order to deploy this contract on testnet/mainet you have to comment out the code above for the relevant network */
/* Note that if this is changed there are code in tasks/collectionFactoryTest that also must be changed */
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"

pub contract CollectionFactory {

    pub let FlowverseSocksIds : [UInt64]

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
    pub fun getCollections(user: String, maxItems: Int, collections: [String], shard: String) : CollectionReport? {
        switch shard {
					
            case "Alchemy-shard1": 
                return self.fetchAlchemyShard1(user: user, maxItems: maxItems, targetCollections:collections)
            case "Alchemy-shard2": 
                return self.fetchAlchemyShard2(user: user, maxItems: maxItems, targetCollections:collections)
            case "Alchemy-shard3": 
                return self.fetchAlchemyShard3(user: user, maxItems: maxItems)
								
    //        case "Alchemy-shard4": 
    //           return self.fetchAlchemyShard4(user: user, maxItems: maxItems)
            case "NFTRegistry": 
                return self.fetchNFTRegistry(user: user, maxItems: maxItems, targetCollections:collections)
        }
            panic("Shard should only be : Alchemy-shard1, Alchemy-shard2,Alchemy-shard3 or NFTRegistry")
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
								
     //       case "Alchemy-shard4": 
     //           return self.fetchAlchemyCollectionShard4(user: user, collectionIDs: collectionIDs)
            case "NFTRegistry": 
                return self.fetchNFTRegistryCollection(user: user, collectionIDs: collectionIDs)


        }
            panic("Shard should only be : Alchemy-shard1, Alchemy-shard2,Alchemy-shard3 or NFTRegistry")
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
    pub fun fetchNFTRegistry(user: String, maxItems: Int, targetCollections:[String]) : CollectionReport? {
        let source = "NFTRegistry"
        let account = self.resolveAddress(user: user)
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

                // Just for Rarible Flowverse Socks, can be moved to Alchemy Shard functions if needed
                if nftInfo.alias == "RaribleNFT" {
                    if CollectionFactory.FlowverseSocksIds.contains(id) {
                        if !collections.containsKey("Flowverse Socks"){
                            var j = 0
                            let raribleIDs = collectionRef.getIDs()
                            for sockID in CollectionFactory.FlowverseSocksIds {
                                if raribleIDs.contains(sockID) {
                                    j = j + 1
                                }
                            }
                            collections.insert(key: "Flowverse Socks", counter)
                        }

                        let image = "https://img.rarible.com/prod/video/upload/t_video_big/prod-itemAnimations/FLOW-A.01ab36aaf654a13e.RaribleNFT:15029/b1cedf3"
                        let item = MetadataCollectionItem(
                            id: id,
                            name: "Flowverse socks",
                            collection: "Rarible",
                            subCollection: "Flowverse socks", 
                            media: image,
                            mediaType: "video",
                            source: source
                        )
                        collectionItems.append(item)

                        counter = counter + 1
                        if counter >= maxItems {
                            fetchItem = false
                        }
                    }
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

		
    //////////////////////////////////////////////////////////////
    // Fetch All Collections in Shard 1
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyShard1(user: String, maxItems: Int, targetCollections: [String]) : CollectionReport? {
        let source = "Alchemy-shard1"
        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperTestnetShard1.getNFTIDs(ownerAddress: account!.address)

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
            let returnedNFTs = AlchemyMetadataWrapperTestnetShard1.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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

    //////////////////////////////////////////////////////////////
    // Fetch All Collections in Shard 2
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyShard2(user: String, maxItems: Int, targetCollections: [String]) : CollectionReport? {
        let source = "Alchemy-shard2"
        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperTestnetShard2.getNFTIDs(ownerAddress: account!.address)

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
            let returnedNFTs = AlchemyMetadataWrapperTestnetShard2.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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

    //////////////////////////////////////////////////////////////
    // Fetch All Collections in Shard 3
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyShard3(user: String, maxItems: Int, targetCollections: [String]) : CollectionReport? {
        let source = "Alchemy-shard3"
        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperTestnetShard3.getNFTIDs(ownerAddress: account!.address)

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
            let returnedNFTs = AlchemyMetadataWrapperTestnetShard3.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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
		

		/*
    //////////////////////////////////////////////////////////////
    // Fetch All Collections in Shard 4
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyShard4(user: String, maxItems: Int, targetCollections: [String]) : CollectionReport? {
        let source = "Alchemy-shard4"
        let account = self.resolveAddress(user: user)
        if account == nil { return nil }

        let items : {String : [MetadataCollectionItem]} = {}
        
        let extraIDs = AlchemyMetadataWrapperTestnetShard4.getNFTIDs(ownerAddress: account!.address)

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
            let returnedNFTs = AlchemyMetadataWrapperTestnetShard4.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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
		*/



    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in NFTRegistry
    //////////////////////////////////////////////////////////////
    pub fun fetchNFTRegistryCollection(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
        let source = "NFTRegistry"
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

                // Just for Rarible Flowverse Socks, can be moved to Alchemy Shard functions if needed
                if nftInfo!.alias == "RaribleNFT" {
                    if CollectionFactory.FlowverseSocksIds.contains(id) {

                        let image = "https://img.rarible.com/prod/video/upload/t_video_big/prod-itemAnimations/FLOW-A.01ab36aaf654a13e.RaribleNFT:15029/b1cedf3"
                        let item = MetadataCollectionItem(
                            id: id,
                            name: "Flowverse socks",
                            collection: "Rarible",
                            subCollection: "Flowverse socks", 
                            media: image,
                            mediaType: "video",
                            source: source
                        )
                        collectionItems.append(item)

                    }
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

		
    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 1
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard1(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
        let source = "Alchemy-shard1"
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
            let returnedNFTs = AlchemyMetadataWrapperTestnetShard1.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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
        return items
    }

    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 2
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard2(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
        let source = "Alchemy-shard2"
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
            let returnedNFTs = AlchemyMetadataWrapperTestnetShard2.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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
        return items
    }

    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 3
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard3(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
        let source = "Alchemy-shard3"
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
            let returnedNFTs = AlchemyMetadataWrapperTestnetShard3.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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
        return items
    }
		

		/*
    //////////////////////////////////////////////////////////////
    // Fetch Specific Collections in Shard 4
    //////////////////////////////////////////////////////////////
    pub fun fetchAlchemyCollectionShard4(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
        let source = "Alchemy-shard4"
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
            let returnedNFTs = AlchemyMetadataWrapperTestnetShard4.getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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
        return items
    }
		*/

    init() {
        self.FlowverseSocksIds = [14813, 15013, 14946, 14808, 14899, 14792, 15016, 14961, 14816, 14796, 14992, 14977, 14815, 14863, 14817, 14814, 14875, 14960, 14985, 14850, 14849, 14966, 14826, 14972, 14795, 15021, 14950, 14847, 14970, 14833, 14786, 15010, 14953, 14799, 14883, 14947, 14844, 14801, 14886, 15015, 15023, 15027, 15029, 14802, 14810, 14948, 14955, 14957, 14988, 15007, 15009, 14837, 15024, 14803, 14973, 14969, 15002, 15017, 14797, 14894, 14881, 15025, 14791, 14979, 14789, 14993, 14873, 14939, 15005, 15006, 14869, 14889, 15004, 15008, 15026, 14990, 14998, 14898, 14819, 14840, 14974, 15019, 14856, 14838, 14787, 14876, 14996, 14798, 14855, 14824, 14843, 14959, 15020, 14862, 14822, 14897, 14830, 14790, 14867, 14878, 14991, 14835, 14818, 14892, 14800, 15000, 14857, 14986, 14805, 14812, 14962]
    }
    
}
