import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"


pub fun main(user: String, collections: [String]) : {String : ItemReport} {
	return {}
}


    pub struct ItemReport {
        pub let length : Int // mapping of collection to no. of ids 
        pub let extraIDs : [UInt64]
        pub let shard : String 
        pub let extraIDsIdentifier : String 

        init(length : Int, extraIDs :[UInt64] , shard: String, extraIDsIdentifier: String) {
            self.length=length 
            self.extraIDs=extraIDs
            self.shard=shard
            self.extraIDsIdentifier=extraIDsIdentifier
        }
    }

