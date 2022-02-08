import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"

//mainnet
import Beam from 0x86b4a0010a71cfc3 
import Art from 0xd796ff17107bbff6
import Marketplace from 0xd796ff17107bbff6
import GooberXContract from 0x34f2bf4a80bb0f69
import Flovatar from 0x921ea449dffec68a
import FlovatarMarketplace from  0x921ea449dffec68a
import RareRooms_NFT from 0x329feb3ab062d289
import CNN_NFT from 0x329feb3ab062d289
import Canes_Vault_NFT from 0x329feb3ab062d289
import DGD_NFT from 0x329feb3ab062d289
import RaceDay_NFT from 0x329feb3ab062d289
import The_Next_Cartel_NFT from 0x329feb3ab062d289
import UFC_NFT from 0x329feb3ab062d289
import MotoGPCard from 0xa49cc0ee46c54bfb
import Gaia from 0x8b148183c28ff88f
import ChainmonstersRewards from 0x93615d25d14fa337
import Moments from 0xd4ad4740ee426334
import MatrixWorldFlowFestNFT from 0x2d2750f240198f91
import SturdyItems from 0x427ceada271aa0b1
import Evolution from 0xf4264ac8f3256818
import GeniaceNFT from 0xabda6627c70c7f52
import OneFootballCollectible from 0x6831760534292098
import CryptoPiggo from 0xd3df824bf81910a4
import GoatedGoatsVouchers from 0xdfc74d9d561374c0
import TraitPacksVouchers from 0xdfc74d9d561374c0
import HaikuNFT from 0xf61e40c19db2a9e2
import KlktnNFT from 0xabd6e80be7e9682c
import Mynft from 0xf6fcbef550d97aa5
import NeoAvatar from 0xb25138dbf45e5801
import NeoViews from 0xb25138dbf45e5801
import MetadataViews from 0x1d7e57aa55817448

//Jambb
import Vouchers from 0x444f5ea22c6ea12c

//xtingles
import Collectible from 0xf5b0eb433389ac3f

pub struct MetadataCollection {

	pub let path:PublicPath
	pub let type: Type
	pub let typeIdentifier: String
	pub let conformance: String 
	pub let domainUrl : String
	pub let category: String
	pub let legacyIdentifierPrefix:String

	init(path:PublicPath, type:Type, conformance:String, domainUrl:String, category:String, legacyIdentifierPrefix:String) {
		self.path=path
		self.type=type
		self.typeIdentifier=type.identifier
		self.conformance=conformance
		self.domainUrl=domainUrl
		self.category=category
		self.legacyIdentifierPrefix=legacyIdentifierPrefix
	}

}

pub struct MetadataCollections {

	pub let items: {UInt64 : MetadataCollectionItem}
	pub let internalToUuidMap: {String : UInt64 }
	pub let collections: {String : [UInt64]}

	init() {
		self.items= {}
		self.internalToUuidMap= {}
		self.collections={}
	}


	pub fun addCollection(collection:MetadataCollection) {



	}
	//This uses a view from Neo until we agree on another for ExternalDomainViewUrl
	pub fun addMetadataCollection(path: PublicPath, account:PublicAccount, category:String, legacyIdentifierPrefix: String, url:String)  {

		// init(path:PublicPath, type:Type, conformance:String, domainUrl:String, items: {UInt64:MetadataCollectionItem}, category:String, legacyIdentifierPrefix:String) {

		let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(path)
		if !resolverCollectionCap.check() {
			return 
		}

		let collection = resolverCollectionCap.borrow()!

		let mc= MetadataCollection(path: path, type: collection.getType() , conformance: "MetadataViews.ResolverCollection", domainUrl: url, category: category, legacyIdentifierPrefix: legacyIdentifierPrefix)


		let resultCollection = self.collections[mc.category] ?? []

		for id in collection.getIDs() {
			let nft = collection.borrowViewResolver(id: id)!

			if let displayView = nft.resolveView(Type<MetadataViews.Display>()) {
				let display = displayView as! MetadataViews.Display

				var externalUrl=mc.domainUrl
				if let externalUrlView = nft.resolveView(Type<NeoViews.ExternalDomainViewUrl>()) {
					let edvu= externalUrlView! as! NeoViews.ExternalDomainViewUrl
					externalUrl=edvu.url
				}

				//TODO: add check for rarity and minter here

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
					type: nft.getType(),
					collection:mc
				)

				self.items[nft.uuid]=item
				//we add a mapping from old legacy internal id to uuid
				self.internalToUuidMap[mc.legacyIdentifierPrefix.concat(id.toString())]= nft.uuid
				resultCollection.append(nft.uuid)
			}
		}
		self.collections[mc.category]=resultCollection
	}
}


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
	pub let collection:MetadataCollection


	init(id:UInt64, uuid:UInt64, name:String, description:String?, image:String, url:String, contentType: String, rarity: String, minter:String?, type:Type, collection: MetadataCollection) {
		self.id=id
		self.uuid=uuid
		self.name=name
		self.description=description
		self.minter=minter
		self.url=url
		self.type=type
		self.image=image
		self.collection=collection
		self.contentType=contentType
		self.rarity=rarity
	}
}

pub fun main(address: Address) : MetadataCollections? {

	let collection= MetadataCollections()
	let account=getAccount(address)

	collection.addMetadataCollection(path: NeoAvatar.CollectionPublicPath, account: account, category: "Neo", legacyIdentifierPrefix: "NeoAvatar", url: "https://neocollectibles.xyz")

	if collection.collections.length==0 {
		return nil
	}
	return collection
}


