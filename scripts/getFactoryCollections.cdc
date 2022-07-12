import CollectionFactory from "../contracts/CollectionFactory.cdc"

pub fun main(user: String, maxItems: Int, collections:[String], shard: String) : CollectionFactory.CollectionReport? {
    return CollectionFactory.getCollections(user: user, maxItems: maxItems, collections:collections, shard: shard)
}