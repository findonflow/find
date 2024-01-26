import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11

access(all) fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
    return fetchAlchemyCollectionShard2(user: user, collectionIDs: collectionIDs)
}

access(all) struct CollectionReport {
    access(all) let items : {String : [MetadataCollectionItem]}
    access(all) let collections : {String : Int} // mapping of collection to no. of ids
    access(all) let extraIDs : {String : [UInt64]}

    init(items: {String : [MetadataCollectionItem]},  collections : {String : Int}, extraIDs : {String : [UInt64]} ) {
        self.items=items
        self.collections=collections
        self.extraIDs=extraIDs
    }
}

access(all) struct MetadataCollectionItem {
    access(all) let id:UInt64
    access(all) let uuid:UInt64?
    access(all) let name: String
    access(all) let collection: String // <- This will be Alias unless they want something else
    access(all) let project: String

    access(all) let media  : String
    access(all) let mediaType : String
    access(all) let source : String

    init(id:UInt64, uuid: UInt64?, name: String, collection: String, media  : String, mediaType : String, source : String, project: String) {
        self.id=id
        self.name=name
        self.uuid=uuid
        self.collection=collection
        self.media=media
        self.mediaType=mediaType
        self.source=source
        self.project=project
    }
}

// Helper function

access(all) fun resolveAddress(user: String) : &Account? {
    let address = FIND.resolve(user)
    if address == nil {
        return nil
    }
    return getAccount(address!)
}


////////////////////////////////////////////////////////////
// Fetch Specific Collections in Shard 2
////////////////////////////////////////////////////////////
access(all) fetchAlchemyCollectionShard2(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
    let source = "getNFTDetailsShard2"
    let account = resolveAddress(user: user)
    if account == nil { return {} }
    if account!.balance == 0.0 {
        return {}
    }

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
        let returnedNFTs = AlchemyMetadataWrapperTestnetShard2.getNFTs(ownerAddress: account!.address, ids: {rename(project) : fetchingIDs[project]!})

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
                uuid: nft!.uuid,
                name: nft!.title ?? "",
                collection: nft!.contract.name,
                media: media,
                mediaType: mediaType,
                source: source ,
                project: project
            )
            collectionItems.append(item)
        }

        if collectionItems.length > 0 {
            items[project] = collectionItems
        }
    }
    return items
}

access(all) rename(_ name: String) : String {
    if name == "MintStoreItem.NBA ALL STAR " {
        return "MintStoreItem"
    }
    return name
}
