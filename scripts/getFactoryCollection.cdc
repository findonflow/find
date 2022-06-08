import CollectionFactory from "../contracts/CollectionFactory.cdc"

pub fun main(user: String, maxItems: Int, shard: String, collection: [String]) : CollectionFactory.CollectionReport? {
    return CollectionFactory.getCollection(user: user, maxItems: maxItems, shard: shard, collection: collection)
}