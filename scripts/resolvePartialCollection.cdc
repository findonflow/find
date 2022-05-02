import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindViews from "../contracts/FindViews.cdc"

// Collection Index.cdc Address : [{Path, ID}]
/* 
	pub struct CollectionItemPointer {
		pub let path 
		pub let id 
	}
 */
// Need : A metadata collection index : -> path, id, collection (Where do you want to group them)
// A list of these for all the items (Like collections and cur)

// Resolve Partial Collection.cdc Address, {path : [IDs]}
// Address
// [path1 , path1, path2]
// [id1 , id2, id3]
// Another list -> take these path, id, collection and return the specific collection information (similar in collections)
pub struct ViewReadPointer : FindViews.Pointer {
	access(self) let cap: Capability<&{MetadataViews.ResolverCollection}>
	pub let id: UInt64

	init(cap: Capability<&{MetadataViews.ResolverCollection}>, id: UInt64) {
		self.cap=cap
		self.id=id
	}

	pub fun resolveView(_ type: Type) : AnyStruct? {
		return self.getViewResolver().resolveView(type)
	}

	pub fun getUUID() :UInt64{
		return self.getViewResolver().uuid
	}

	pub fun getViews() : [Type]{
		return self.getViewResolver().getViews()
	}

	pub fun owner() : Address {
		return self.cap.address
	}

	pub fun valid() : Bool {
		if !self.cap.borrow()!.getIDs().contains(self.id) {
			return false
		}
		return true
	}

	pub fun getItemType() : Type {
		return self.getViewResolver().getType()
	}

	pub fun getViewResolver() : &AnyResource{MetadataViews.Resolver} {
		return self.cap.borrow()!.borrowViewResolver(id: self.id)
	}

	pub fun getNFTInfo() : NFTRegistry.NFTInfo {
		return NFTRegistry.getNFTInfoByTypeIdentifier(self.getItemType().identifier)!
	}

	pub fun getCollection() : String {
		return self.getNFTInfo().alias
	}

	pub fun resolveDisplayViews() : MetadataViews.Display {
		return self.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
	}

	pub fun getName() : String {
		return self.resolveDisplayViews().name
	}

	pub fun getImage() : String {
		return self.resolveDisplayViews().thumbnail.uri()
	}

	pub fun getRarityView() : FindViews.Rarity? {
		return self.resolveView(Type<FindViews.Rarity>()) as? FindViews.Rarity
	}

	pub fun getRarity() : String {
		if let rarity = self.getRarityView() {
			return rarity.rarityName
		}
		return ""
	}

	pub fun getExternalUrlView() : MetadataViews.ExternalURL? {
		return  self.resolveView(Type<MetadataViews.ExternalURL>()) as? MetadataViews.ExternalURL
	}

	pub fun getExternalUrl() : String {
		if let url = self.getExternalUrlView() {
			return url.url
		}
		return self.getNFTInfo().externalFixedUrl
	}

}

pub fun createViewReadPointer(address:Address, path:PublicPath, id:UInt64) : ViewReadPointer {
	let cap=	getAccount(address).getCapability<&{MetadataViews.ResolverCollection}>(path)
	let pointer= ViewReadPointer(cap: cap, id: id)
	return pointer
}

pub struct MetadataCollectionItem {
	pub let id:UInt64
	pub let typeIdentifier: String
	pub let uuid: UInt64 
	pub let name: String
	pub let image: String
	pub let url: String
	pub let contentType:String
	pub let rarity:String
	//Refine later 
	pub let metadata: {String : String}
	pub let collection: String // <- This will be Alias unless they want something else

	init(id:UInt64, type: Type, uuid: UInt64, name:String, image:String, url:String, contentType: String, rarity: String, collection: String) {
		self.id=id
		self.typeIdentifier = type.identifier
		self.uuid = uuid
		self.name=name
		self.url=url
		self.image=image
		self.contentType=contentType
		self.rarity=rarity
		self.metadata={}
		self.collection=collection
	}
}

pub fun main(address: Address, publicPathIdentifiers: [String], ids:[UInt64]) : [MetadataCollectionItem] {

	var resultMap : [MetadataCollectionItem] = []
	var publicPaths : [PublicPath] = []
	for identifier in publicPathIdentifiers {
		publicPaths.append(PublicPath(identifier:identifier)!)
	}

	assert(publicPaths.length == ids.length, message: "The length of publicPath passed in does not match with that of the IDs.")
	var i = 0
	while i < publicPaths.length {
		let path = publicPaths[i]
		let id = ids[i]
		let pointer = createViewReadPointer(address: address, path: path, id: id)
		resultMap.append(MetadataCollectionItem(id: id, 
												type: pointer.getItemType(), 
												uuid: pointer.getUUID(), 
												name: pointer.getName(), 
												image: pointer.getImage(), 
												url: pointer.getExternalUrl(), 
												contentType: "image", 
												rarity: pointer.getRarity(), 
												collection: pointer.getCollection())
		)
		i = i + 1
	}
	return resultMap
}

