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

pub fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
    return {}
}

    pub struct MetadataCollectionItem {
        pub let id:UInt64
        pub let uuid:UInt64?
        pub let name: String
        pub let collection: String // <- This will be Alias unless they want something else
        pub let project: String

        pub let media  : String
        pub let mediaType : String
        pub let source : String

        init(id:UInt64, uuid: UInt64?, name: String, collection: String, media  : String, mediaType : String, source : String, project: String) {
            self.id=id
            self.name=name
			self.uuid=uuid
            self.collection=collection
            self.media=media
            self.mediaType=mediaType
            self.source=source
            self.project=project
        }
    }

