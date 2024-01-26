import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac

access(all) fun main(user: String, collections: [String]) : {String : ItemReport}  {
    return fetchAlchemyShard1(user: user, targetCollections:collections)
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

access(all) fun fetchAlchemyShard1(user: String, targetCollections: [String]) : {String : ItemReport} {
    let source = "Shard1"
    let account = resolveAddress(user: user)
    if account == nil { return {} }


    let extraIDs = AlchemyMetadataWrapperMainnetShard1.getNFTIDs(ownerAddress: account!)
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

        let contractItem = AlchemyMetadataWrapperMainnetShard1.getNFTs(ownerAddress: account!, ids: {project : [extraIDs[project]![0]]})
        if contractItem.length > 0 && contractItem[0] != nil {
            if NFTCatalogContracts.contains(contractItem[0]!.contract.name) {
                continue
            }
        }

        inventory[project] = ItemReport(length : collectionLength, extraIDs :extraIDs[project] ?? [] , shard: source, extraIDsIdentifier: project, collectionName: contractItem[0]?.contract?.name ?? project)

    }

    return inventory

}

