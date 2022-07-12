import CollectionFactory from "../contracts/CollectionFactory.cdc"

pub fun main(user: String, maxItems: Int, collections:[String], shard: String) : CollectionFactory.CollectionReport? {
    return CollectionFactory.fetchNFTRegistry(user: user, maxItems: maxItems, targetCollections:collections)
}