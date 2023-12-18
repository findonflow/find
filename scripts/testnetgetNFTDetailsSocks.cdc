import FIND from "../contracts/FIND.cdc"

access(all) main(user: String , project: String, id: UInt64, views: [String]) : NFTData? {

	return nil
}

pub struct NFTData {
	pub let contract: NFTContractData
	pub let id: UInt64
	pub let uuid: UInt64?
	pub let title: String?
	pub let description: String?
	pub let external_domain_view_url: String?
	pub let token_uri: String?
	pub let media: [NFTMedia?]
	pub let metadata: {String: String?}

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

pub struct NFTContractData {
	pub let name: String
	pub let address: Address
	pub let storage_path: String
	pub let public_path: String
	pub let public_collection_name: String
	pub let external_domain: String

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

pub struct NFTMedia {
	pub let uri: String?
	pub let mimetype: String?

	init(
		uri: String?,
		mimetype: String?
	) {
		self.uri = uri
		self.mimetype = mimetype
	}
}