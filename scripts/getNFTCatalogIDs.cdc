import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import ViewResolver from "../contracts/standard/ViewResolver.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

access(all) fun main(user: String, collections: [String]) : {String : ItemReport} {
    return fetchNFTCatalog(user: user, targetCollections:collections)
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

access(all) struct NFTView {
    access(all) let id: UInt64
    access(all) let display: MetadataViews.Display?
    access(all) let editions: MetadataViews.Editions?
    access(all) let collectionDisplay: MetadataViews.NFTCollectionDisplay?
    access(all) let nftType: Type

    init(
        id : UInt64,
        display : MetadataViews.Display?,
        editions : MetadataViews.Editions?,
        collectionDisplay: MetadataViews.NFTCollectionDisplay?,
        nftType: Type
    ) {
        self.id = id
        self.display = display
        self.editions = editions
        self.collectionDisplay = collectionDisplay
        self.nftType = nftType
    }
}

access(all) struct NFTIDs {
    access(all) let ids: [UInt64]
    access(all) let collectionName: String 

    init(ids: [UInt64], collectionName: String ) {
        self.ids = ids
        self.collectionName = collectionName
    }
}

// Helper function 

access(all) fun resolveAddress(user: String) : Address? {
    return FIND.resolve(user)
}

access(all) fun getNFTIDs(ownerAddress: Address) : {String : NFTIDs} {

    let account = getAuthAccount<auth(BorrowValue) &Account>(ownerAddress)

    if account.balance == 0.0 {
        return {}
    }

    let inventory : {String:NFTIDs}={}
    let types = FINDNFTCatalog.getCatalogTypeData()
    for nftType in types.keys {

        let typeData=types[nftType]!
        let collectionKey=typeData.keys[0]
        let catalogEntry = FINDNFTCatalog.getCatalogEntry(collectionIdentifier:collectionKey)!

        var collectionName = collectionKey
        if typeData.length == 1 {
            collectionName = catalogEntry.collectionDisplay.name
        }

        let storagePath = catalogEntry.collectionData.storagePath
        let ref= account.storage.borrow<&{ViewResolver.ResolverCollection}>(from: storagePath)
        if ref != nil {
            inventory[collectionKey] = NFTIDs(ids: ref!.getIDs(), collectionName: collectionName)
        }

    }
    return inventory
}

access(all) fun fetchNFTCatalog(user: String, targetCollections: [String]) : {String : ItemReport} {
    let source = "NFTCatalog"
    let account = resolveAddress(user: user)
    if account == nil { return {} }


    let extraIDs = getNFTIDs(ownerAddress: account!)
    let inventory : {String : ItemReport} = {}
    var fetchedCount : Int = 0

    for project in extraIDs.keys {

        let catalogEntry = FINDNFTCatalog.getCatalogEntry(collectionIdentifier:project)!
        let projectName = catalogEntry.contractName

        if extraIDs[project]! == nil || extraIDs[project]!.ids.length < 1{
            extraIDs.remove(key: project)
            continue
        }

        let collectionLength = extraIDs[project]!.ids.length

        // by pass if this is not the target collection
        if targetCollections.length > 0 && !targetCollections.contains(project) {
            // inventory[project] = ItemReport(length : collectionLength, extraIDs :extraIDs[project]! , shard: source)
            continue
        }

        inventory[catalogEntry.contractName] = ItemReport(length : collectionLength, extraIDs :extraIDs[project]?.ids ?? [] , shard: source, extraIDsIdentifier: project, collectionName: extraIDs[project]!.collectionName)

    }

    return inventory

}

