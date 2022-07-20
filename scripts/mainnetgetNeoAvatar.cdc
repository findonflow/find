import FIND from "../contracts/FIND.cdc"

import NeoAvatar from 0xb25138dbf45e5801
import NeoViews from 0xb25138dbf45e5801
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

pub fun main(user: String) : [MetadataCollectionItem] {

	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return []}
	let address = resolveAddress!
	let account=getAccount(address)

	return getItemForMetadataStandard(path: NeoAvatar.CollectionPublicPath, account:account)
	/*
	let items: [MetadataCollectionItem] = []
	let account=getAccount(address)
	let neoAvatarCap = account.getCapability<&{MetadataViews.ResolverCollection}>(NeoAvatar.CollectionPublicPath)
	if neoAvatarCap.check() {
		let collection = neoAvatarCap.borrow()!
		for id in collection.getIDs() {
			let nft = collection.borrowViewResolver(id: id)!

			if let displayView = nft.resolveView(Type<MetadataViews.Display>()) {
				let display = displayView as! MetadataViews.Display
				if let externalUrlView = nft.resolveView(Type<NeoViews.ExternalDomainViewUrl>()) {
					let externalUrl= externalUrlView! as! NeoViews.ExternalDomainViewUrl
					let item = MetadataCollectionItem(
						id: id,
						name: display.name,
						image: display.thumbnail.uri(),
						url: externalUrl.url,
						listPrice: nil,
						listToken: nil,
						contentType: "image",
						rarity: ""
					)

					items.append(item)
				}
			}
		}
	}
	return items
	*/

}

pub fun getItemForMetadataStandard(path: PublicPath, account:PublicAccount) : [MetadataCollectionItem] {
	let items: [MetadataCollectionItem] = []
	let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(path)
	if resolverCollectionCap.check() {
		let collection = resolverCollectionCap.borrow()!
		for id in collection.getIDs() {
			let nft = collection.borrowViewResolver(id: id)!

			if let displayView = nft.resolveView(Type<MetadataViews.Display>()) {
				let display = displayView as! MetadataViews.Display
				if let externalUrlView = nft.resolveView(Type<NeoViews.ExternalDomainViewUrl>()) {
					let externalUrl= externalUrlView! as! NeoViews.ExternalDomainViewUrl
					let item = MetadataCollectionItem(
						id: id,
						name: display.name,
						image: display.thumbnail.uri(),
						url: externalUrl.url,
						listPrice: nil,
						listToken: nil,
						contentType: "image",
						rarity: ""
					)

					items.append(item)
				}
			}
		}
	}
	return items



}
