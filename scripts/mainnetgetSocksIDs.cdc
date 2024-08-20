import "NonFungibleToken"
import "MetadataViews"
import "FIND"
import RaribleNFT from 0x01ab36aaf654a13e

access(all) fun main(user: String, collections: [String]) : {String : ItemReport} {
    return fetchRaribleNFT(user: user, targetCollections: collections)
}

access(all) let FlowverseSocksIds : [UInt64] = [14813, 15013, 14946, 14808, 14899, 14792, 15016, 14961, 14816, 14796, 14992, 14977, 14815, 14863, 14817, 14814, 14875, 14960, 14985, 14850, 14849, 14966, 14826, 14972, 14795, 15021, 14950, 14847, 14970, 14833, 14786, 15010, 14953, 14799, 14883, 14947, 14844, 14801, 14886, 15015, 15023, 15027, 15029, 14802, 14810, 14948, 14955, 14957, 14988, 15007, 15009, 14837, 15024, 14803, 14973, 14969, 15002, 15017, 14797, 14894, 14881, 15025, 14791, 14979, 14789, 14993, 14873, 14939, 15005, 15006, 14869, 14889, 15004, 15008, 15026, 14990, 14998, 14898, 14819, 14840, 14974, 15019, 14856, 14838, 14787, 14876, 14996, 14798, 14855, 14824, 14843, 14959, 15020, 14862, 14822, 14897, 14830, 14790, 14867, 14878, 14991, 14835, 14818, 14892, 14800, 15000, 14857, 14986, 14805, 14812, 14962]

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

access(all) fun getNFTIDs(ownerAddress: Address) : {String:[UInt64]} {

    let account = getAuthAccount<&Account>(ownerAddress)

    let inventory : {String:[UInt64]}={}

    let tempPathStr = "RaribleNFT"
    let tempPublicPath = PublicPath(identifier: tempPathStr)!
    //TODO: delete this
    let cap = account.capabilities.storage.issue<&RaribleNFT.Collection>(RaribleNFT.collectionStoragePath)

    if cap.check(){
        // let rarible : [UInt64] = []
        let socks : [UInt64] = []
        for id in cap.borrow()!.getIDs() {
            if FlowverseSocksIds.contains(id) {
                socks.append(id)
                // } else {
                // 	rarible.append(id)
            }
        }

        // inventory["RaribleNFT"] = rarible
        inventory["FlowverseSocks"] = socks

    }

    return inventory
}

access(all) fun fetchRaribleNFT(user: String, targetCollections: [String]) : {String : ItemReport} {
    let source = "RaribleNFT"
    let account = resolveAddress(user: user)
    if account == nil { return {} }


    let extraIDs = getNFTIDs(ownerAddress: account!)
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

        inventory[project] = ItemReport(length : collectionLength, extraIDs :extraIDs[project] ?? [] , shard: source, extraIDsIdentifier: project, collectionName: "Flowverse Socks V1")

    }

    return inventory

}
