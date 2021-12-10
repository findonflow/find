import Art from "../contracts/Art.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

//testnet
//import Flovatar from 0x3c7e227e52ac6c0d
//import BasicBeast from 0x4742010dbfe107da

//mainnet
import GooberXContract from 0x34f2bf4a80bb0f69
import Flovatar from 0x921ea449dffec68a

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
	pub let svg: String


	init(id:UInt64, name:String, url:String, ipfsHash:String, svg:String) {
		self.id=id
		self.name=name
		self.url=url
		self.ipfsHash=ipfsHash
		self.svg=svg
	}

}


pub fun main(address: Address) : {String : MetadataCollection}? {

	let account = getAccount(address)
	let results : {String :  MetadataCollection}={}

	let artList= Art.getArt(address: address)
	if artList.length > 0 {
		let imageUrlPrefix="https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_600/f_auto/maincache"
		let items: [MetadataCollectionItem]=[]
		for art in artList {
			items.append(MetadataCollectionItem(id:art.id, name:art.metadata.name.concat(" edition ").concat(art.metadata.edition.toString()).concat("/").concat(art.metadata.maxEdition.toString()).concat(" by ").concat(art.metadata.artist),  url:imageUrlPrefix.concat(art.cacheKey), ipfsHash:"", svg:""))
		}
		results["versus"]= MetadataCollection(type: Type<@Art.Collection>().identifier, items: items)
	}

	let goobersCap = account.getCapability<&GooberXContract.Collection{NonFungibleToken.CollectionPublic, GooberXContract.GooberCollectionPublic}>(GooberXContract.CollectionPublicPath)

	if goobersCap.check() {
		let items: [MetadataCollectionItem]=[]
		let goobers = goobersCap.borrow()!.listUsersGoobers()
		for id in goobers.keys {
			let goober = goobers[id]!
			items.append(MetadataCollectionItem(id:id, name: "Goober #".concat(id.toString()), url:"", ipfsHash: goober.uri, svg: ""))
		}
		results["goobers"]= MetadataCollection(type: Type<@GooberXContract.Collection>().identifier, items: items)
	}

  let flovatarList= Flovatar.getFlovatars(address: address)
  if flovatarList.length > 0 {
		let items: [MetadataCollectionItem]=[]
		for flovatar in flovatarList  {
      let flovatarDetails = Flovatar.getFlovatar(address: address, flovatarId: flovatar.id)
			items.append(MetadataCollectionItem(id:flovatar.id, name:flovatar.name, url:"", ipfsHash:"", svg: flovatarDetails?.metadata?.svg ?? ""))
		}
		results["flovatar"]= MetadataCollection(type: Type<@Flovatar.Collection>().identifier, items: items)
	}
	
	/*
	let bbCap = account.getCapability<&{BasicBeast.BeastCollectionPublic}>(BasicBeast.CollectionPublicPath)
	if bbCap.check() {
		let items: [MetadataCollectionItem]=[]
		let bb = bbCap.borrow()!

		for bid in bb.getIDs() {
			let beast = bb.borrowBeast(id: bid)!
			let template=beast.data.beastTemplate
			let name= beast.nickname ?? template.name
			items.append(MetadataCollectionItem(id:beast.id, name:name, url:template.image, ipfsHash:"", svg: ""))

		}
		results["basicbeasts"]= MetadataCollection(type: Type<@BasicBeast.Collection>().identifier, items: items)
	}
	*/

	if results.keys.length == 0 {
		return nil
	}
	return results
}
