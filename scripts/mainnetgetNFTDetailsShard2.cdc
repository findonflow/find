import FIND from "../contracts/FIND.cdc"
import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac

access(all) fun main(user: String , project: String, id: UInt64, views: [String]) : AlchemyMetadataWrapperMainnetShard2.NFTData? {

	if let address = FIND.resolve(user) {
		let ids : {String:[UInt64]} = {project : [id]}
		let res = AlchemyMetadataWrapperMainnetShard2.getNFTs(ownerAddress: address, ids: ids)
		if res.length == 0 || res[0] == nil {
			return nil
		}
		return res[0]!
	}
	return nil

}