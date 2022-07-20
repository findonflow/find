import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import NFTCatalog from 0x49a7cda3a1eecc29
import RaribleNFT from 0x01ab36aaf654a13e
import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard2 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard3 from 0xeb8cb4c3157d5dac
import AlchemyMetadataWrapperMainnetShard4 from 0xeb8cb4c3157d5dac

pub fun main(user: String) : {String : CollectionLength} {

	if let address = FIND.resolve(user) {

		var result = getNFTIDs_Catalog(ownerAddress: address, cacheCollections: {})
		result = getNFTIDs_Shard1(ownerAddress: address, cacheCollections: result)
		result = getNFTIDs_Shard2(ownerAddress: address, cacheCollections: result)
		result = getNFTIDs_Shard3(ownerAddress: address, cacheCollections: result)
		result = getNFTIDs_Shard4(ownerAddress: address, cacheCollections: result)
		result = getNFTIDs_RaribleNFT(ownerAddress: address, cacheCollections: result)
		return result

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

pub fun getNFTIDs_Catalog(ownerAddress: Address, cacheCollections: {String:CollectionLength}) : {String:CollectionLength} {

	let account = getAuthAccount(ownerAddress)

	let types = NFTCatalog.getCatalogTypeData()
	for nftType in types.keys {

		let typeData=types[nftType]!
		let collectionKey=typeData.keys[0]
		let catalogEntry = NFTCatalog.getCatalogEntry(collectionIdentifier:collectionKey)!
		let tempPathStr = "catalog".concat(collectionKey)
		let tempPublicPath = PublicPath(identifier: tempPathStr)!
		account.link<&NonFungibleToken.Collection>(tempPublicPath, target: catalogEntry.collectionData.storagePath)
		let cap= account.getCapability<&NonFungibleToken.Collection>(tempPublicPath)
		if cap.check(){
			let collection = cap.borrow()!
			let length = collection.ownedNFTs.length
			if length == 0 {
				continue
			}
			cacheCollections[collectionKey] = CollectionLength(shard: "NFTCatalog", length: length)
		}
	}
	return cacheCollections
}

pub fun getNFTIDs_Shard1(ownerAddress: Address, cacheCollections: {String:CollectionLength}) : {String : CollectionLength} {
	let nfts = AlchemyMetadataWrapperMainnetShard1.getNFTIDs(ownerAddress: ownerAddress) 
	for nft in nfts.keys {
		let length = nfts[nft]!.length
		if length == 0 {
			continue
		}
		cacheCollections[nft] = CollectionLength(shard: "Shard1", length: length)
	} 
	return cacheCollections
}

pub fun getNFTIDs_Shard2(ownerAddress: Address, cacheCollections: {String:CollectionLength}) : {String : CollectionLength} {
	let nfts = AlchemyMetadataWrapperMainnetShard2.getNFTIDs(ownerAddress: ownerAddress) 
	for nft in nfts.keys {
		let length = nfts[nft]!.length
		if length == 0 {
			continue
		}
		cacheCollections[nft] = CollectionLength(shard: "Shard2", length: length)
	} 
	return cacheCollections
}

pub fun getNFTIDs_Shard3(ownerAddress: Address, cacheCollections: {String:CollectionLength}) : {String : CollectionLength} {
	let nfts = AlchemyMetadataWrapperMainnetShard3.getNFTIDs(ownerAddress: ownerAddress) 
	for nft in nfts.keys {
		let length = nfts[nft]!.length
		if length == 0 {
			continue
		}
		cacheCollections[nft] = CollectionLength(shard: "Shard3", length: length)
	} 
	return cacheCollections
}

pub fun getNFTIDs_Shard4(ownerAddress: Address, cacheCollections: {String:CollectionLength}) : {String : CollectionLength} {
	let nfts = AlchemyMetadataWrapperMainnetShard4.getNFTIDs(ownerAddress: ownerAddress) 
	for nft in nfts.keys {
		let length = nfts[nft]!.length
		if length == 0 {
			continue
		}
		cacheCollections[nft] = CollectionLength(shard: "Shard4", length: length)
	} 
	return cacheCollections
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


