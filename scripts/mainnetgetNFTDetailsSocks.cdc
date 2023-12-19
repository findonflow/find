import FIND from "../contracts/FIND.cdc"
import RaribleNFT from 0x01ab36aaf654a13e

access(all) main(user: String , project: String, id: UInt64, views: [String]) : NFTData? {

	if let address = FIND.resolve(user) {
		if let uuid = getSocks(ownerAddress: address, id: id) {

			let contract = NFTContractData(
				name: "RaribleNFT",
				address: 0x01ab36aaf654a13e,
				storage_path: "/storage/RaribleNFTCollection",
				public_path: "/public/RaribleNFTCollection",
				public_collection_name: "CollectionPublic",
				external_domain: "https://rarible.com/"
			)

			return NFTData(
				contract: contract,
				id: id,
				uuid: uuid,
				title: "Flowverse socks",
				description: "Socks by Flowverse NFTs were designed by NYC-based metaverse artist Jenny Jiang. The 111 Socks were then distributed to some of the earliest, most committed and most engaged Flowverse community members for Christmas 2021.",
				external_domain_view_url: nil,
				token_uri: nil,
				media: [
					NFTMedia(uri: "https://img.rarible.com/prod/video/upload/t_video_big/prod-itemAnimations/FLOW-A.01ab36aaf654a13e.RaribleNFT:15029/b1cedf3", mimetype: "video")
				],
				metadata: {}
			)
		}
	}
	return nil

}

access(all) getSocks(ownerAddress: Address, id: UInt64) : UInt64? {

	let account = getAuthAccount(ownerAddress)
	let ref = account.borrow<&RaribleNFT.Collection>(from: RaribleNFT.collectionStoragePath)
	if ref != nil {
		let nfts = ref!
		if nfts.ownedNFTs.containsKey(id) {
			return ref!.borrowNFT(id: id).uuid
		}
	}
	
	return nil
}

access(all) let FlowverseSocksIds : [UInt64] = [14813, 15013, 14946, 14808, 14899, 14792, 15016, 14961, 14816, 14796, 14992, 14977, 14815, 14863, 14817, 14814, 14875, 14960, 14985, 14850, 14849, 14966, 14826, 14972, 14795, 15021, 14950, 14847, 14970, 14833, 14786, 15010, 14953, 14799, 14883, 14947, 14844, 14801, 14886, 15015, 15023, 15027, 15029, 14802, 14810, 14948, 14955, 14957, 14988, 15007, 15009, 14837, 15024, 14803, 14973, 14969, 15002, 15017, 14797, 14894, 14881, 15025, 14791, 14979, 14789, 14993, 14873, 14939, 15005, 15006, 14869, 14889, 15004, 15008, 15026, 14990, 14998, 14898, 14819, 14840, 14974, 15019, 14856, 14838, 14787, 14876, 14996, 14798, 14855, 14824, 14843, 14959, 15020, 14862, 14822, 14897, 14830, 14790, 14867, 14878, 14991, 14835, 14818, 14892, 14800, 15000, 14857, 14986, 14805, 14812, 14962]

access(all) struct NFTData {
	access(all) let contract: NFTContractData
	access(all) let id: UInt64
	access(all) let uuid: UInt64?
	access(all) let title: String?
	access(all) let description: String?
	access(all) let external_domain_view_url: String?
	access(all) let token_uri: String?
	access(all) let media: [NFTMedia?]
	access(all) let metadata: {String: String?}

	init(
		contract: NFTContractData,
		id: UInt64,
		uuid: UInt64?,
		title: String?,
		description: String?,
		external_domain_view_url: String?,
		token_uri: String?,
		media: [NFTMedia?],
		metadata: {String: String?}
	) {
		self.contract = contract
		self.id = id
		self.uuid = uuid
		self.title = title
		self.description = description
		self.external_domain_view_url = external_domain_view_url
		self.token_uri = token_uri
		self.media = media
		self.metadata = metadata
	}
}

access(all) struct NFTContractData {
	access(all) let name: String
	access(all) let address: Address
	access(all) let storage_path: String
	access(all) let public_path: String
	access(all) let public_collection_name: String
	access(all) let external_domain: String

	init(
		name: String,
		address: Address,
		storage_path: String,
		public_path: String,
		public_collection_name: String,
		external_domain: String
	) {
		self.name = name
		self.address = address
		self.storage_path = storage_path
		self.public_path = public_path
		self.public_collection_name = public_collection_name
		self.external_domain = external_domain
	}
}

access(all) struct NFTMedia {
	access(all) let uri: String?
	access(all) let mimetype: String?

	init(
		uri: String?,
		mimetype: String?
	) {
		self.uri = uri
		self.mimetype = mimetype
	}
}