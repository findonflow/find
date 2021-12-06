import Art from "../contracts/Art.cdc"

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

	 let imageUrlPrefix="https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_600/f_auto/maincache"
	 let items: [MetadataCollectionItem]=[]
   let artList= Art.getArt(address: address)
	 for art in artList {
		 items.append(MetadataCollectionItem(id:art.id, name:art.metadata.name.concat(" edition ").concat(art.metadata.edition.toString()).concat("/").concat(art.metadata.maxEdition.toString()).concat(" by ").concat(art.metadata.artist),  url:imageUrlPrefix.concat(art.cacheKey), ipfsHash:""))
	 }
 	 results["versus"]= MetadataCollection(type: Type<@Art.Collection>().identifier, items: items)
	 return results
}
