import CollectionFactory from "../contracts/CollectionFactory.cdc"

pub fun main(user: String) : CollectionFactory.CollectionReport? {
    return CollectionFactory.getCollections(user: user, maxItems: Int(UInt64.max), collections:[], shard: "NFTRegistry")
}