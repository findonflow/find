import Beam from 0x86b4a0010a71cfc3 

pub struct MetadataCollectionItem {
	pub let id:UInt64
	pub let name: String
	pub let image: String
	pub let url: String
	pub let listPrice: UFix64?
	pub let listToken: String?
	pub let contentType:String
	pub let rarity:String


	init(id:UInt64, name:String, image:String, url:String, listPrice: UFix64?, listToken:String?, contentType: String, rarity: String) {
		self.id=id
		self.name=name
		self.url=url
		self.image=image
		self.listToken=listToken
		self.listPrice=listPrice
		self.contentType=contentType
		self.rarity=rarity
	}
}

pub fun main(address: Address) : [MetadataCollectionItem] {


	let items: [MetadataCollectionItem] = []
	let account=getAccount(address)
	let beamCap = account.getCapability<&{Beam.BeamCollectionPublic}>(Beam.CollectionPublicPath)
	if beamCap.check() {
		let collection = beamCap.borrow()!
		for id in collection.getIDs() {
			let nft = collection.borrowCollectible(id: id)!

	    let metadata = Beam.getCollectibleItemMetaData(collectibleItemID: nft.data.collectibleItemID)!
		  var mediaUrl: String? = metadata["mediaUrl"]
			if mediaUrl != nil &&  mediaUrl!.slice(from: 0, upTo: 7) != "ipfs://" {
				mediaUrl = "ipfs://".concat(mediaUrl!)
			}
			let item = MetadataCollectionItem(
				id: id,
				name: metadata["title"]!,
				image: mediaUrl ?? "",
				url: "https://".concat(metadata["domainUrl"]!),
				listPrice: nil,
				listToken: nil,
				contentType: metadata["mediaType"]!,
				rarity: ""
			)

			items.append(item)
		}
	}
	return items

}
