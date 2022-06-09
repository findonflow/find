import CollectionFactory from "../contracts/CollectionFactory.cdc"

pub fun main(user: String, collectionIDs: {String : [UInt64]}, shard: String) : CollectionFactory.CollectionReport? {
    return CollectionFactory.getCollection(user: user, collectionIDs: collectionIDs, shard: shard)
}