import StarlyCard from 0x5b82f21c0edf76e3
import StarlyMetadataViews from 0x5b82f21c0edf76e3
import MetadataViews from 0x1d7e57aa55817448

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

	let account=getAccount(address)
	let items: [MetadataCollectionItem] = []
	let resolverCollectionCap= account.getCapability<&{StarlyCard.StarlyCardCollectionPublic}>(StarlyCard.CollectionPublicPath)
	if resolverCollectionCap.check() {
		let collection = resolverCollectionCap.borrow()!
		for id in collection.getIDs() {
			let nft = collection.borrowViewResolver(id: id)!

			if let displayView = nft.resolveView(Type<MetadataViews.Display>()) {
				let display = displayView as! MetadataViews.Display
				if let starlyView = nft.resolveView(Type<StarlyMetadataViews.CardEdition>()) {
					 let cardEdition= starlyView as! StarlyMetadataViews.CardEdition

					let item = MetadataCollectionItem(
						id: id,
						name: display.name,
						image: display.thumbnail.uri(),
						url:cardEdition.url,
						listPrice: nil,
						listToken: nil,
						contentType: "image",
						rarity: cardEdition.card.rarity
					)

					items.append(item)
				}
			}
		}
	}
	return items
}

