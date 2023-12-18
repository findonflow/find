import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
// /* Alchemy Mainnet Wrapper */
// import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

// /* Alchemy Testnet Wrapper */

// import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11

    access(all) main(user: String, collections: [String]) : {String : ItemReport}  {
        return {}
    }


    pub struct ItemReport {
        pub let length : Int // mapping of collection to no. of ids 
        pub let extraIDs : [UInt64]
        pub let shard : String 
        pub let extraIDsIdentifier : String 
	    pub let collectionName: String

        init(length : Int, extraIDs :[UInt64] , shard: String, extraIDsIdentifier: String, collectionName: String) {
            self.length=length 
            self.extraIDs=extraIDs
            self.shard=shard
            self.extraIDsIdentifier=extraIDsIdentifier
            self.collectionName=collectionName
        }
    }
