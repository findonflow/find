// /* Alchemy Mainnet Wrapper */
// import AlchemyMetadataWrapperMainnet from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
// import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

// /* Alchemy Testnet Wrapper */
// import AlchemyMetadataWrapperTestnetfrom 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11

/* NFTRegistry */
import NFTRegistry from "../contracts/NFTRegistry.cdc"

import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

pub contract CollectionFactory {

    pub struct CollectionReport {
        pub let items : {String : [MetadataCollectionItem]} 
        pub let collectinos : [String] 
        pub let extraIDs : {String : [UInt64]} 

        init(items: {String : [MetadataCollectionItem]},  collectinos : [String], extraIDs : {String : [UInt64]} ) {
            self.items=items 
            self.collectinos=collectinos 
            self.extraIDs=extraIDs
        }
    }

    pub struct MetadataCollectionItem {
        pub let id:UInt64
        pub let uuid: UInt64 
        pub let name: String
        pub let image: String
        pub let collection: String // <- This will be Alias unless they want something else
        pub let subCollection: String // <- This will be Alias unless they want something else
        pub let media: MetadataViews.Media // <- This will only fetch the first media 

        // Depend on discussion outcome 
        pub let url: String
        pub let contentTypes:[String]
        pub let rarity:String
        pub let typeIdentifier: String
        //Refine later 
        pub let tag: {String : String}
        pub let scalar: {String : UFix64}

        init(id:UInt64, type: Type, uuid: UInt64, name:String, image:String, url:String, contentTypes: [String], rarity: String, media: MetadataViews.Media, collection: String, subCollection: String, tag: {String : String}, scalar: {String : UFix64}) {
            self.id=id
            self.typeIdentifier = type.identifier
            self.uuid = uuid
            self.name=name
            self.url=url
            self.image=image
            self.contentTypes=contentTypes
            self.rarity=rarity
            self.media=media
            self.collection=collection
            self.subCollection=subCollection
            self.tag=tag
            self.scalar=scalar
        }
    }



    // Helper function 

    pub fun fetchNFTRegistry(user: String) : CollectionReport?{

	let resolvingAddress = FIND.resolve(user)
	if resolvingAddress == nil {
		return nil
	}
	let address = resolvingAddress!
    let account = getAccount(address)

    


        return nil
    }

}