import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindViews from "../contracts/FindViews.cdc"

pub struct ViewCollectionPointer {
	access(self) let cap: Capability<&{MetadataViews.ResolverCollection}>
	pub let nftInfo: NFTRegistry.NFTInfo

	init(cap: Capability<&{MetadataViews.ResolverCollection}>, alias: String) {
		self.cap=cap
		self.nftInfo=NFTRegistry.getNFTInfoByAlias(alias)!
	}

	pub fun resolveView(_ type: Type, id: UInt64) : AnyStruct? {
		return self.getViewResolver(id).resolveView(type)
	}

	pub fun getUUID(_ id: UInt64) :UInt64{
		return self.getViewResolver(id).uuid
	}

	pub fun getViews(_ id: UInt64) : [Type]{
		return self.getViewResolver(id).getViews()
	}

	pub fun owner() : Address {
		return self.cap.address
	}

	pub fun valid(_ id: UInt64) : Bool {
		if !self.cap.borrow()!.getIDs().contains(id) {
			return false
		}
		return true
	}

	pub fun getItemType(_ id: UInt64) : Type {
		return self.getViewResolver(id).getType()
	}

	pub fun getViewResolver(_ id: UInt64) : &AnyResource{MetadataViews.Resolver} {
		return self.cap.borrow()!.borrowViewResolver(id: id)
	}

	pub fun resolveDisplayViews(_ id: UInt64) : MetadataViews.Display {
		return self.resolveView(Type<MetadataViews.Display>(), id: id)! as! MetadataViews.Display
	}

	pub fun getName(_ id: UInt64) : String {
		return self.resolveDisplayViews(id).name
	}

	pub fun getImage(_ id: UInt64) : String {
		return self.resolveDisplayViews(id).thumbnail.uri()
	}

	pub fun getRarityView(_ id: UInt64) : FindViews.Rarity? {
		return self.resolveView(Type<FindViews.Rarity>(), id:id) as? FindViews.Rarity
	}

	pub fun getRarity(_ id: UInt64) : String {
		if let rarity = self.getRarityView(id) {
			return rarity.rarityName
		}
		return ""
	}

	pub fun getExternalUrlView(_ id: UInt64) : MetadataViews.ExternalURL? {
		return  self.resolveView(Type<MetadataViews.ExternalURL>(), id:id) as? MetadataViews.ExternalURL
	}

	pub fun getExternalUrl(_ id: UInt64) : String {
		if let url = self.getExternalUrlView(id) {
			return url.url
		}
		return self.nftInfo.externalFixedUrl
	}

}

pub fun createViewReadPointer(address:Address, alias:String) : ViewCollectionPointer {
	let path= NFTRegistry.getNFTInfoByAlias(alias)!.publicPath
	let cap= getAccount(address).getCapability<&{MetadataViews.ResolverCollection}>(path)
	let pointer= ViewCollectionPointer(cap: cap, alias: alias)
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
	pub let collection: String 

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

pub fun main(address: Address, aliases: [String], ids:[UInt64]) : [MetadataCollectionItem] {

	var pointerMap: {String : ViewCollectionPointer} = {}

	var resultMap : [MetadataCollectionItem] = []

	assert(aliases.length == ids.length, message: "The length of alias passed in does not match with that of the IDs.")
	var i = 0
	while i < aliases.length {
		let alias = aliases[i]
		let id = ids[i]
		if pointerMap[alias] == nil {
			pointerMap[alias] = createViewReadPointer(address: address, alias: alias)
		}
		let pointer = pointerMap[alias]!
		resultMap.append(MetadataCollectionItem(id: id, 
												type: pointer.getItemType(id), 
												uuid: pointer.getUUID(id), 
												name: pointer.getName(id), 
												image: pointer.getImage(id), 
												url: pointer.getExternalUrl(id), 
												contentType: "image", 
												rarity: pointer.getRarity(id), 
												collection: alias)
		)
		i = i + 1
	}
	return resultMap
}

