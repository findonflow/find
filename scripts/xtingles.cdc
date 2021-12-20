import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

//mainnet
import Art from 0xd796ff17107bbff6
import Marketplace from 0xd796ff17107bbff6
import GooberXContract from 0x34f2bf4a80bb0f69
import Flovatar from 0x921ea449dffec68a
import FlovatarMarketplace from  0x921ea449dffec68a
import RareRooms_NFT from 0x329feb3ab062d289
import MotoGPCard from 0xa49cc0ee46c54bfb
import Gaia from 0x8b148183c28ff88f
import ChainmonstersRewards from 0x93615d25d14fa337
import Moments from 0xd4ad4740ee426334
import Collectible from 0xf5b0eb433389ac3f


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


	init(id:UInt64, name:String, image:String, url:String, listPrice: UFix64?, listToken:String?) {
		self.id=id
		self.name=name
		self.url=url
		self.image=image
		self.listToken=listToken
		self.listPrice=listPrice
	}
}

pub fun main(address: Address) : {String : MetadataCollection}? {

	let account = getAccount(address)
	let results : {String :  MetadataCollection}={}


	let xtingles = Collectible.getCollectibleDatas(address:address) 
	if xtingles.length > 0 {
		let items: [MetadataCollectionItem] = []
		for item in xtingles {
			items.append(MetadataCollectionItem(
				id: item.id,
				name: item.metadata.name,
				image: item.metadata.link,
				url: "http://xtingles.com",
				listPrice: nil,
				listToken: nil
			))
		}

		results["xtingles"] = MetadataCollection(type: Type<@Collectible.Collection>().identifier, items: items)


	}

	if results.keys.length == 0 {
		return nil
	}
	return results
}
