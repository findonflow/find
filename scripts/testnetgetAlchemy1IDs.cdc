import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
// /* Alchemy Mainnet Wrapper */
// import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

// /* Alchemy Testnet Wrapper */

import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11




    pub fun main(user: String, collections: [String]) : {String : ItemReport}  {
        return fetchAlchemyShard1(user: user, targetCollections:collections)
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

    // Helper function 

    pub fun resolveAddress(user: String) : Address? {
	    return FIND.resolve(user)
    }


    pub fun fetchAlchemyShard1(user: String, targetCollections: [String]) : {String : ItemReport} {
        let source = "Shard1"
        let account = resolveAddress(user: user)
        if account == nil { return {} }


        let extraIDs = AlchemyMetadataWrapperTestnetShard1.getNFTIDs(ownerAddress: account!)
        let inventory : {String : ItemReport} = {}
        var fetchedCount : Int = 0

        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
                continue
            }
            
            let collectionLength = extraIDs[project]!.length

            // by pass if this is not the target collection
            if targetCollections.length > 0 && !targetCollections.contains(project) {
                // inventory[project] = ItemReport(items: [],  length : collectionLength, extraIDs :extraIDs[project]! , shard: source)
                continue
            }

            inventory[project] = ItemReport(length : collectionLength, extraIDs :extraIDs[project] ?? [] , shard: source, extraIDsIdentifier: project)

        }

        return inventory

    }

