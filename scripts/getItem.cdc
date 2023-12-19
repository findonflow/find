import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

access(all) struct MetadataCollectionItem {
	access(all) let id:UInt64
	access(all) let uuid:UInt64
	access(all) let name: String
	access(all) let description: String?
	access(all) let image: String
	access(all) let url: String
	access(all) let contentType:String
	access(all) let rarity:String
	access(all) let minter:String?
	access(all) let type:Type


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


access(all) main(user: String, aliasOrIdentifier: String, id:UInt64) : MetadataCollectionItem?{

	let publicPath = getPublicPath(aliasOrIdentifier)

	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return nil}
	let address = resolveAddress!
	let account=getAccount(address)
	if account.balance == 0.0 {
		return nil
	}
	let resolverCollectionCap= account.getCapability<&{ViewResolver.ResolverCollection}>(publicPath)
	if !resolverCollectionCap.check() {
		return nil
	}

	let collection = resolverCollectionCap.borrow()!
	let nft = collection.borrowViewResolver(id: id)

	if let displayView = nft.resolveView(Type<MetadataViews.Display>()) {
		let display = displayView as! MetadataViews.Display

		var externalUrl=""
		if let externalUrlView = nft.resolveView(Type<MetadataViews.ExternalURL>()) {
			let edvu= externalUrlView as! MetadataViews.ExternalURL
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

access(all) getPublicPath(_ nftIdentifier: String) : PublicPath {
	let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
	let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
	return collection.collectionData.publicPath
}
