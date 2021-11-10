/*
- collection
 - type
 - dictionary id ->
  - name
  - imageurl
  - hash
	*/

import TypedMetadata from "../contracts/TypedMetadata.cdc"
import Profile from "../contracts/Profile.cdc"


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
	pub let url: String
	pub let ipfsHash: String


	init(id:UInt64, name:String, url:String, ipfsHash:String) {
		self.id=id
		self.name=name
		self.url=url
		self.ipfsHash=ipfsHash
	}

}


pub fun main(address: Address) : {String : MetadataCollection} {

	let results : {String :  MetadataCollection}={}

	let collections= getAccount(address).getCapability(Profile.publicPath).borrow<&{Profile.Public}>()!.getCollections()

	for col in collections {
		if col.type ==Type<&{TypedMetadata.ViewResolverCollection}>() {
			let name=col.name
			let collection : { UInt64 : { String : AnyStruct }}={}
			let vrc= col.collection.borrow<&{TypedMetadata.ViewResolverCollection}>()!

			let items: [MetadataCollectionItem]=[]
			for id in vrc.getIDs() {
				let nft=vrc.borrowViewResolver(id: id)
				var name=""
				var ipfsHash=""
				var url=""
				for view in nft.getViews() {

					if view == Type<String>() {
					  name= nft.resolveView(view) as! String
					}

					if view == Type<TypedMetadata.Media>() {
						let resolve= nft.resolveView(view) 

						let media= resolve as! TypedMetadata.Media

						if media.protocol=="http" {
							url=media.data
						}

						if media.protocol=="ipfs" {
							ipfsHash=media.data
						}
					}
				}
				items.append(MetadataCollectionItem(id:id, name:name,  url:url, ipfsHash:ipfsHash))
			}
			results[name]= MetadataCollection(type: vrc.getType().identifier, items: items)
		}
	}
	return results
}





