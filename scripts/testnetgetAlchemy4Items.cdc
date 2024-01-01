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

access(all) fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
    return {}
}

    access(all) struct MetadataCollectionItem {
        access(all) let id:UInt64
        access(all) let uuid:UInt64?
        access(all) let name: String
        access(all) let collection: String // <- This will be Alias unless they want something else
        access(all) let project: String

        access(all) let media  : String
        access(all) let mediaType : String
        access(all) let source : String

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

