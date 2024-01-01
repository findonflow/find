import FIND from "../contracts/FIND.cdc"
import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac

access(all) fun main(user: String , project: String, id: UInt64, views: [String]) : AlchemyMetadataWrapperMainnetShard3.NFTData? {

	if let address = FIND.resolve(user) {
		let ids : {String:[UInt64]} = {project : [id]}
		let res = AlchemyMetadataWrapperMainnetShard3.getNFTs(ownerAddress: address, ids: ids)
		if res.length == 0 || res[0] == nil {
			return nil
		}
		return res[0]!
	}
	return nil

}