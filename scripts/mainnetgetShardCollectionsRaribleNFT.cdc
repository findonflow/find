import FIND from "../contracts/FIND.cdc"
import RaribleNFT from 0x01ab36aaf654a13e

pub fun main(user: String) : {String : CollectionLength} {

	if let address = FIND.resolve(user) {

		return getNFTIDs_RaribleNFT(ownerAddress: address, cacheCollections: {})

	}
	return {}

}

pub let FlowverseSocksIds : [UInt64] = [14813, 15013, 14946, 14808, 14899, 14792, 15016, 14961, 14816, 14796, 14992, 14977, 14815, 14863, 14817, 14814, 14875, 14960, 14985, 14850, 14849, 14966, 14826, 14972, 14795, 15021, 14950, 14847, 14970, 14833, 14786, 15010, 14953, 14799, 14883, 14947, 14844, 14801, 14886, 15015, 15023, 15027, 15029, 14802, 14810, 14948, 14955, 14957, 14988, 15007, 15009, 14837, 15024, 14803, 14973, 14969, 15002, 15017, 14797, 14894, 14881, 15025, 14791, 14979, 14789, 14993, 14873, 14939, 15005, 15006, 14869, 14889, 15004, 15008, 15026, 14990, 14998, 14898, 14819, 14840, 14974, 15019, 14856, 14838, 14787, 14876, 14996, 14798, 14855, 14824, 14843, 14959, 15020, 14862, 14822, 14897, 14830, 14790, 14867, 14878, 14991, 14835, 14818, 14892, 14800, 15000, 14857, 14986, 14805, 14812, 14962]
pub struct CollectionLength {
	pub let shard : String 
	pub let length : Int 
	init(shard : String, length : Int ) {
		self.shard=shard 
		self.length=length
	}
}

// Helper function 

pub fun resolveAddress(user: String) : Address? {
	return FIND.resolve(user)
}

pub fun getNFTIDs_RaribleNFT(ownerAddress: Address, cacheCollections: {String:CollectionLength}) : {String : CollectionLength} {

	let account = getAuthAccount(ownerAddress)

	let tempPathStr = "RaribleNFT"
	let tempPublicPath = PublicPath(identifier: tempPathStr)!
	account.link<&RaribleNFT.Collection>(tempPublicPath, target: RaribleNFT.collectionStoragePath)
	let cap= account.getCapability<&RaribleNFT.Collection>(tempPublicPath)
	if cap.check(){
			// let rarible : [UInt64] = []
		var socks = 0 
		for id in cap.borrow()!.getIDs() {
			if FlowverseSocksIds.contains(id) {
				socks = socks + 1
			// } else {
			// 	rarible.append(id)
			}
		}
		if socks == 0 {
			return cacheCollections
		}
		// inventory["RaribleNFT"] = rarible
		cacheCollections["FlowverseSocks"] = CollectionLength(shard: "RaribleNFT", length: socks)

	}
	
	return cacheCollections
}


