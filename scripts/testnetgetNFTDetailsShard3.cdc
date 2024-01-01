import FIND from "../contracts/FIND.cdc"
// import AlchemyMetadataWrapperTestnetShard1 from 0x5ff2c7b4c40de11
// import AlchemyMetadataWrapperTestnetShard2 from 0x5ff2c7b4c40de11
import AlchemyMetadataWrapperTestnetShard3 from 0x5ff2c7b4c40de11

access(all) fun main(user: String , project: String, id: UInt64, views: [String]) : AlchemyMetadataWrapperTestnetShard3.NFTData? {

	if let address = FIND.resolve(user) {
		let ids : {String:[UInt64]} = {project : [id]}
		let res = AlchemyMetadataWrapperTestnetShard3.getNFTs(ownerAddress: address, ids: ids)
		if res.length == 0 || res[0] == nil {
			return nil
		}
		return res[0]!
	}
	return nil

}