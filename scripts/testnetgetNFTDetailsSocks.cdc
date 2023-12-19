import FIND from "../contracts/FIND.cdc"

access(all) main(user: String , project: String, id: UInt64, views: [String]) : NFTData? {

	return nil
}

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