import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"

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


pub fun main(user: String, aliasOrIdentifier: String, id:UInt64) : MetadataCollectionItem?{

	let nftInfo = NFTRegistry.getNFTInfo(aliasOrIdentifier) 
	if nftInfo == nil {panic("This NFT is not registered in registry. input: ".concat(aliasOrIdentifier))}

	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return nil}
	let address = resolveAddress!
	let account=getAccount(address)
	let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(nftInfo!.publicPath)
	if !resolverCollectionCap.check() {
		return nil
	}

	let collection = resolverCollectionCap.borrow()!
	let nft = collection.borrowViewResolver(id: id)!

	if let displayView = nft.resolveView(Type<MetadataViews.Display>()) {
		let display = displayView as! MetadataViews.Display

		var externalUrl=""
		if let externalUrlView = nft.resolveView(Type<MetadataViews.ExternalURL>()) {
			let edvu= externalUrlView! as! MetadataViews.ExternalURL
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

