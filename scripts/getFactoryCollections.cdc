import CollectionFactory from "../contracts/CollectionFactory.cdc"

pub fun main(user: String, maxItems: Int, shard: String) : CollectionFactory.CollectionReport? {
    return CollectionFactory.getCollections(user: user, maxItems: maxItems, shard: shard)
}