
import NeoViews from 0xb25138dbf45e5801
import MetadataViews from 0x1d7e57aa55817448

pub struct MetadataCollectionItem {
	pub let id:UInt64
	pub let uuid:UInt64
	pub let name: String
	pub let description: String?
	pub let image: String
	pub let url: String
	pub let contentType:String
	pub let rarity:String
	pub let minter:String?
	pub let type:Type


	init(id:UInt64, uuid:UInt64, name:String, description:String?, image:String, url:String, contentType: String, rarity: String, minter:String?, type:Type) {
		self.id=id
		self.uuid=uuid
		self.name=name
		self.description=description
		self.minter=minter
		self.url=url
		self.type=type
		self.image=image
		self.contentType=contentType
		self.rarity=rarity
	}
}


pub fun main(address: Address, path:PublicPath, id:UInt64) : MetadataCollectionItem?{

	let account=getAccount(address)
	let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(path)
	if !resolverCollectionCap.check() {
		return nil
	}

	let collection = resolverCollectionCap.borrow()!
	let nft = collection.borrowViewResolver(id: id)!

	if let displayView = nft.resolveView(Type<MetadataViews.Display>()) {
		let display = displayView as! MetadataViews.Display

		var externalUrl=""
		if let externalUrlView = nft.resolveView(Type<NeoViews.ExternalDomainViewUrl>()) {
			let edvu= externalUrlView! as! NeoViews.ExternalDomainViewUrl
			externalUrl=edvu.url
		}
		let item = MetadataCollectionItem(
			id: id,
			uuid: nft.uuid,
			name: display.name,
			description:display.description,
			image: display.thumbnail.uri(),
			url: externalUrl,
			contentType: "image",
			rarity: "",
			minter: "",
			type: nft.getType()
		)
		return item
	}
	return nil
}

