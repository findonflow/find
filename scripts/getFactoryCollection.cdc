import CollectionFactory from "../contracts/CollectionFactory.cdc"

pub fun main(user: String, collectionIDs: {String : [UInt64]}, shard: String) : {String : [CollectionFactory.MetadataCollectionItem]} {
    return CollectionFactory.getCollection(user: user, collectionIDs: collectionIDs, shard: shard)
}