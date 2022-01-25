import StarlyCard from 0x5b82f21c0edf76e3

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
	let starlyCap = account.getCapability<&{StarlyCard.StarlyCardCollectionPublic}>(StarlyCard.CollectionPublicPath)
	if starlyCap.check() {
		let collection = starlyCap.borrow()!
		for id in collection.getIDs() {
			let nft = collection.borrowStarlyCard(id: id)!

			let url="https://starly.io/c/".concat(nft.starlyID)
			let item = MetadataCollectionItem(
				id: id,
				name: "Starly #".concat(id.toString()),
				image: url.concat(".json"),
				url: url,
				listPrice: nil,
				listToken: nil,
				contentType: "json/starly",
				rarity: ""
			)

			items.append(item)
		}
	}
	return items

}
