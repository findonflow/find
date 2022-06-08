import CollectionFactory from "../contracts/CollectionFactory.cdc"

pub fun main(user: String, maxItems: Int, shard: String, ignoreItems: {String : [UInt64]}) : CollectionFactory.CollectionReport? {
    return CollectionFactory.getCollections(user: user, maxItems: maxItems, shard: shard, ignoreItems: ignoreItems)
}