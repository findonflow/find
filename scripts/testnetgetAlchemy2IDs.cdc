import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11

access(all) fun main(user: String, collections: [String]) : {String : ItemReport} {
    return fetchAlchemyShard2(user: user, targetCollections:collections)
}

access(all) struct ItemReport {
    access(all) let length : Int // mapping of collection to no. of ids 
    access(all) let extraIDs : [UInt64]
    access(all) let shard : String 
    access(all) let extraIDsIdentifier : String 
    access(all) let collectionName: String

    init(length : Int, extraIDs :[UInt64] , shard: String, extraIDsIdentifier: String, collectionName: String) {
        self.length=length 
        self.extraIDs=extraIDs
        self.shard=shard
        self.extraIDsIdentifier=extraIDsIdentifier
        self.collectionName=collectionName
    }
}

// Helper function 

access(all) fun resolveAddress(user: String) : Address? {
    return FIND.resolve(user)
}


access(all) fun fetchAlchemyShard2(user: String, targetCollections: [String]) : {String : ItemReport} {
    let source = "Shard2"
    let account = resolveAddress(user: user)
    if account == nil { return {} }


    let extraIDs = AlchemyMetadataWrapperTestnetShard2.getNFTIDs(ownerAddress: account!)
    let inventory : {String : ItemReport} = {}
    var fetchedCount : Int = 0

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

        inventory[project] = ItemReport(length : collectionLength, extraIDs :extraIDs[project] ?? [] , shard: source, extraIDsIdentifier: project, collectionName: project)

    }

    return inventory
}

access(all) fun rename(_ name: String) : String {
    if name == "MintStoreItem.NBA ALL STAR " {
        return "MintStoreItem"
    }
    return name
}
