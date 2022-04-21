import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"

import Dandy from "../contracts/Dandy.cdc"

pub struct MetadataCollections {

	pub let items: {String : MetadataCollectionItem}
	pub let collections: {String : [String]}
	pub let curatedCollections: {String : [String]}

	init(items: {String : MetadataCollectionItem}, collections: {String : [String]}, curatedCollections: {String: [String]}) {
		self.items=items
		self.collections=collections
		self.curatedCollections=curatedCollections
	}
}


pub struct MetadataCollection{
	pub let type: String
	pub let items: [MetadataCollectionItem]

	init(type:String, items: [MetadataCollectionItem]) {
		self.type=type
		self.items=items
	}
}


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

pub fun main(address: Address) : MetadataCollections? {

	var resultMap : {String : MetadataCollectionItem} = {}
	let account = getAccount(address)
	let results : {String :  [String]}={}

for nftInfo in NFTRegistry.getNFTInfoAll().values {
	let mappings = getItemForMetadataStandard(alias:nftInfo.alias, path: nftInfo.publicPath, account:account, externalFixedUrl: nftInfo.externalFixedUrl)
	for key in mappings.keys {
		resultMap.insert(key:key, mappings[key]! )
	}
	
}

let publicPath=/public/FindCuratedCollections
let link = account.getCapability<&{String: [String]}>(publicPath)
var curatedCollections : {String: [String]} = {}
if link.check() {
	let curated = link.borrow()!
	for curatedKey in curated.keys {
		curatedCollections[curatedKey] = curated[curatedKey]!
	}
}

return MetadataCollections(items: resultMap, collections:results, curatedCollections: curatedCollections)
}

//This uses a view from Neo until we agree on another for ExternalDomainViewUrl
pub fun getItemForMetadataStandard(alias:String, path: PublicPath, account:PublicAccount, externalFixedUrl: String) : {String : MetadataCollectionItem} {
	let items: {String : MetadataCollectionItem} = {}
	let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(path)
	if resolverCollectionCap.check() {
		let collection = resolverCollectionCap.borrow()!
		for id in collection.getIDs() {
			let nft = collection.borrowViewResolver(id: id) 

			if nft.resolveView(Type<MetadataViews.Display>()) != nil {
				let displayView = nft.resolveView(Type<MetadataViews.Display>())!
				let display = displayView as! MetadataViews.Display
				var externalUrl=externalFixedUrl
				/* 
				if let externalUrlView = nft.resolveView(Type<NeoViews.ExternalDomainViewUrl>()) {
					let url= externalUrlView! as! NeoViews.ExternalDomainViewUrl
					externalUrl=url.url
				}
				*/
				let item = MetadataCollectionItem(
					id: id,
					name: display.name,
					image: display.thumbnail.uri(),
					url: externalUrl,
					listPrice: nil,
					listToken: nil,
					contentType: "image",
					rarity: ""
				)
				let itemId = alias.concat(item.id.toString())
				items[itemId] = item
			}
		}
	}
	return items

}
