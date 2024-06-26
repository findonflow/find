import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
// /* Alchemy Mainnet Wrapper */
// import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

// /* Alchemy Testnet Wrapper */

// import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11

    pub fun main(user: String, collections: [String]) : {String : ItemReport}  {
        return fetchAlchemyShard4(user: user, targetCollections:collections)
    }

    pub let NFTCatalogContracts : [String] = getNFTCatalogContracts()

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

    // Helper function 

    pub fun resolveAddress(user: String) : Address? {
	    return FIND.resolve(user)
    }

    pub fun getNFTCatalogContracts() : [String] {
        let catalogs = FINDNFTCatalog.getCatalog()
        let names : [String] = []
        for catalog in catalogs.values {
            names.append(catalog.contractName)
        }
        return names
    }

    pub fun fetchAlchemyShard4(user: String, targetCollections: [String]) : {String : ItemReport} {
        let source = "Shard4"
        let account = resolveAddress(user: user)
        if account == nil { return {} }


        let extraIDs = AlchemyMetadataWrapperMainnetShard4.getNFTIDs(ownerAddress: account!)
        let inventory : {String : ItemReport} = {}
        var fetchedCount : Int = 0

        // For by-passing bugs

        if extraIDs["MintStoreItem.NBA ALL STAR "] != nil { // who the hell put a space at the end of the string
            extraIDs["MintStoreItem"] = extraIDs.remove(key: "MintStoreItem.NBA ALL STAR ")
        }


        for project in extraIDs.keys {
            if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
                extraIDs.remove(key: project)
                continue
            }

            if project == "RCRDSHPNFT" {
                continue
            }
            
            let collectionLength = extraIDs[project]!.length

            // by pass if this is not the target collection
            if targetCollections.length > 0 && !targetCollections.contains(project) {
                // inventory[project] = ItemReport(items: [],  length : collectionLength, extraIDs :extraIDs[project]! , shard: source)
                continue
            }

           let contractItem = AlchemyMetadataWrapperMainnetShard4.getNFTs(ownerAddress: account!, ids: {project : [extraIDs[project]![0]]})
            if contractItem.length > 0 && contractItem[0] != nil {
                if NFTCatalogContracts.contains(contractItem[0]!.contract.name) {
                    continue
                }
            }

            inventory[project] = ItemReport(length : collectionLength, extraIDs :extraIDs[project] ?? [] , shard: source, extraIDsIdentifier: project, collectionName: contractItem[0]?.contract?.name ?? project)

        }

        return inventory

    }

 