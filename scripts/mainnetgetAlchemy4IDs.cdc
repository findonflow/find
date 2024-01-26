import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac


access(all) fun main(user: String, collections: [String]) : {String : ItemReport}  {
    return fetchAlchemyShard4(user: user, targetCollections:collections)
}

access(all) let NFTCatalogContracts : [String] = getNFTCatalogContracts()

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

access(all) fun getNFTCatalogContracts() : [String] {
    let catalogs = FINDNFTCatalog.getCatalog()
    let names : [String] = []
    for catalog in catalogs.values {
        names.append(catalog.contractName)
    }
    return names
}

access(all) fun fetchAlchemyShard4(user: String, targetCollections: [String]) : {String : ItemReport} {
    let source = "Shard4"
    let account = resolveAddress(user: user)
    if account == nil { return {} }


    let extraIDs = AlchemyMetadataWrapperMainnetShard4.getNFTIDs(ownerAddress: account!)
    let inventory : {String : ItemReport} = {}
    var fetchedCount : Int = 0

    // For by-passing bugs

    if extraIDs["MintStoreItem.NBA ALL STAR "] != nil { // who the hell put a space at the end of the string
        extraIDs["MintStoreItem"] = extraIDs.remove(key: "MintStoreItem.NBA ALL STAR ")
    }


    for project in extraIDs.keys {
        if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
            extraIDs.remove(key: project)
            continue
        }

        if project == "RCRDSHPNFT" {
            continue
        }

        let collectionLength = extraIDs[project]!.length

        // by pass if this is not the target collection
        if targetCollections.length > 0 && !targetCollections.contains(project) {
            // inventory[project] = ItemReport(items: [],  length : collectionLength, extraIDs :extraIDs[project]! , shard: source)
            continue
        }

        let contractItem = AlchemyMetadataWrapperMainnetShard4.getNFTs(ownerAddress: account!, ids: {project : [extraIDs[project]![0]]})
        if contractItem.length > 0 && contractItem[0] != nil {
            if NFTCatalogContracts.contains(contractItem[0]!.contract.name) {
                continue
            }
        }

        inventory[project] = ItemReport(length : collectionLength, extraIDs :extraIDs[project] ?? [] , shard: source, extraIDsIdentifier: project, collectionName: contractItem[0]?.contract?.name ?? project)

    }

    return inventory

}


