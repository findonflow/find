import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"
import FIND from "../contracts/FIND.cdc"

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
	pub let transferable: Bool

	init(path:PublicPath, type:Type, conformance:String, domainUrl:String, category:String, legacyIdentifierPrefix:String, transferable:Bool) {
		self.path=path
		self.type=type
		self.typeIdentifier=type.identifier
		self.conformance=conformance
		self.domainUrl=domainUrl
		self.category=category
		self.legacyIdentifierPrefix=legacyIdentifierPrefix
		self.transferable=transferable
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


	pub fun addCollection(items:[MetadataCollectionItem]) {


		if items.length == 0 {
			return
		}

		let collection=items[0].collection
		let resultCollection = self.collections[collection.category] ?? []
		for item in items {
			self.items[item.uuid]=item
			//we add a mapping from old legacy internal id to uuid
			self.internalToUuidMap[collection.legacyIdentifierPrefix.concat(item.id.toString())]= item.uuid
			resultCollection.append(item.uuid)
		}
		self.collections[collection.category]=resultCollection
	}

	//This uses a view from Neo until we agree on another for ExternalDomainViewUrl
	pub fun addMetadataCollection(path: PublicPath, account:PublicAccount, category:String, legacyIdentifierPrefix: String, url:String, transferable:Bool)  {

		// init(path:PublicPath, type:Type, conformance:String, domainUrl:String, items: {UInt64:MetadataCollectionItem}, category:String, legacyIdentifierPrefix:String) {

		let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(path)
		if !resolverCollectionCap.check() {
			return 
		}

		let collection = resolverCollectionCap.borrow()!

		let mc= MetadataCollection(path: path, type: collection.getType() , conformance: "MetadataViews.ResolverCollection", domainUrl: url, category: category, legacyIdentifierPrefix: legacyIdentifierPrefix, transferable: transferable)


		let items:[MetadataCollectionItem]=[]
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
				items.append(item)
			}
		}
		self.addCollection(items: items)
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

//TODO change bacak to address later
//pub fun main(address: Address) : MetadataCollections? {
pub fun main(name: String) : MetadataCollections? {
	let address=FIND.lookupAddress(name)!

	let collection= MetadataCollections()
	let account=getAccount(address)

	let items:[MetadataCollectionItem]=[]

	let versusArtCap=account.getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
	let versusImageUrlPrefix = "https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_600/f_auto/maincache"
	if versusArtCap.check(){

		let artCollection= versusArtCap.borrow()!

		let mc= MetadataCollection(path: Art.CollectionPublicPath, type: artCollection.getType() , conformance: "Art.CollectionPublic", domainUrl: "https://versus.auction", category: "Versus", legacyIdentifierPrefix: "Versus", transferable: true)

		for id in artCollection.getIDs() {
			var art=artCollection.borrowArt(id: id)!
			let item = MetadataCollectionItem(
				id: id,
				uuid: art.uuid,
				name: art.metadata.name.concat(" edition ").concat(art.metadata.edition.toString()).concat("/").concat(art.metadata.maxEdition.toString()).concat(" by ").concat(art.metadata.artist),  
				description:art.metadata.description,
				image: versusImageUrlPrefix.concat(art.cacheKey()), 
				url: "https://www.versus.auction/piece/".concat(address.toString()).concat("/").concat(art.id.toString()).concat("/"),
				contentType: "image",
				rarity: "",
				minter: "",
				type: art.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

	let versusMarketplace = account.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
	if versusMarketplace.check() {

		let versusMarket = versusMarketplace.borrow()!

		let mc= MetadataCollection(path: Marketplace.CollectionPublicPath, type: versusMarketplace.borrow()!.getType() , conformance: "Marketplace.SalePublic", domainUrl: "https://versus.auction", category: "Versus", legacyIdentifierPrefix: "Versus", transferable:false)

		let saleItems = versusMarket.listSaleItems()
		for saleItem in saleItems {

			let uuid = versusMarket.getUUIDforSaleItem(tokenID: saleItem.id)
			let item = MetadataCollectionItem(
				id: saleItem.id,
				uuid: uuid,
				name: saleItem.art.name.concat(" edition ").concat(saleItem.art.edition.toString()).concat("/").concat(saleItem.art.maxEdition.toString()).concat(" by ").concat(saleItem.art.artist),
				description:"",
				image: versusImageUrlPrefix.concat(saleItem.cacheKey), 
				url: "https://www.versus.auction/listing/".concat(saleItem.id.toString()).concat("/"),
				contentType: "image",
				rarity: "",
				minter: "",
				type: Type<@Art.NFT>(), 
				collection:mc
			)
			items.append(item)
		}
	}

  let flovatarCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)  
	if flovatarCap.check(){

		let flovatars=flovatarCap.borrow()!
		 let mc= MetadataCollection(path: Flovatar.CollectionPublicPath, type: flovatars.getType() , conformance: "Flovatar.CollectionPublic", domainUrl: "https://flovatar.com", category: "Flovatar", legacyIdentifierPrefix: "Flovatar", transferable:true)
		for id in flovatars.getIDs() {
			let flovatar = flovatars.borrowFlovatar(id: id)!

			let metadata=flovatar.getMetadata()
			var name = flovatar.getName()
			if name == "" {
				name="Flovatar #".concat(flovatar.id.toString())
			}

			var rarity="common"
			if metadata.legendaryCount > 0 {
				rarity="legendary"
			}else if metadata.epicCount > 0 {
				rarity="epic"
			}else if metadata.rareCount > 0 {
				rarity="rare"
			}


			let item=MetadataCollectionItem(
				id: flovatar.id, 
				uuid:flovatar.uuid,
				name: name, 
				description: flovatar.description,
				image: "https://flovatar.com/api/image/".concat(flovatar.id.toString()),
				url: "https://flovatar.com/flovatars/".concat(flovatar.id.toString()).concat("/"),
				contentType: "image",
				rarity: rarity,
				minter: "",
				type: flovatar.getType(),
				collection:mc
			)
			items.append(item)
		}
	}


	let flovatarMarketCap = account.getCapability<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath)  
	if flovatarMarketCap.check(){

		let saleCollection=flovatarMarketCap.borrow()!
		 let mc= MetadataCollection(path: FlovatarMarketplace.CollectionPublicPath, type: saleCollection.getType() , conformance: "FlovatarMarketplace.SalePublic", domainUrl: "https://flovatar.com", category: "Flovatar", legacyIdentifierPrefix: "Flovatar", transferable:false)
		for id in saleCollection.getFlovatarIDs() {
			let flovatar = saleCollection.getFlovatar(tokenId: id)!

			let metadata=flovatar.getMetadata()
			var name = flovatar.getName()
			if name == "" {
				name="Flovatar #".concat(flovatar.id.toString())
			}

			var rarity="common"
			if metadata.legendaryCount > 0 {
				rarity="legendary"
			}else if metadata.epicCount > 0 {
				rarity="epic"
			}else if metadata.rareCount > 0 {
				rarity="rare"
			}


			let item=MetadataCollectionItem(
				id: flovatar.id, 
				uuid:flovatar.uuid,
				name: name, 
				description: flovatar.description,
				image: "https://flovatar.com/api/image/".concat(flovatar.id.toString()),
				url: "https://flovatar.com/flovatars/".concat(flovatar.id.toString()).concat("/"),
				contentType: "image",
				rarity: rarity,
				minter: "",
				type: flovatar.getType(),
				collection:mc
			)
			items.append(item)
		}
	}


	let goobersCap = account.getCapability<&GooberXContract.Collection{NonFungibleToken.CollectionPublic, GooberXContract.GooberCollectionPublic}>(GooberXContract.CollectionPublicPath)
	if goobersCap.check() {

		let goobers = goobersCap.borrow()!

		let mc= MetadataCollection(path: GooberXContract.CollectionPublicPath, type: goobers.getType() , conformance: "NonFungibleToken.CollectionPublic, GooberXContract.GooberCollectionPublic", domainUrl: "https://partimansion.io/gooberz", category: "Gooberz", legacyIdentifierPrefix: "Gooberz", transferable:true)
		for id in goobers.getIDs() {
			let goober= goobers.borrowGoober(id:id)!
			let item=MetadataCollectionItem(
				id: id,
				uuid: goober.uuid,
				name: "Goober #".concat(id.toString()),
				description: "",
				image: goober.data.uri,
				url: "https://partymansion.io/gooberz/".concat(id.toString()),
				contentType: "image",
				rarity: "",
				minter:"",
				type: goober.getType(),
				collection:mc
			)
			items.append(item)
		}
	}


	let rareRoomCap = account.getCapability<&RareRooms_NFT.Collection{RareRooms_NFT.RareRooms_NFTCollectionPublic}>(RareRooms_NFT.CollectionPublicPath)
	if rareRoomCap.check() {

		let rareRooms = rareRoomCap.borrow()!
		let mc= MetadataCollection(path: RareRooms_NFT.CollectionPublicPath, type: rareRooms.getType() , conformance: "RareRooms_NFT.RareRooms_NFTCollectionPublic", domainUrl: "https://rarerooms.io", category: "RareRooms", legacyIdentifierPrefix: "RareRooms", transferable:true)
		for id in rareRooms.getIDs() {
			let nft = rareRooms.borrowRareRooms_NFT(id: id)!
			let metadata = RareRooms_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata["name"]!,
				description: metadata["description"] ?? "", 
				image: metadata["preview"]!,
				url: "https://rarerooms.io/tokens/".concat(id.toString()),
				contentType: "image",
				rarity: "",
				minter: "",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}
	

	let cnnCap = account.getCapability<&CNN_NFT.Collection{CNN_NFT.CNN_NFTCollectionPublic}>(CNN_NFT.CollectionPublicPath)
	if cnnCap.check() {

		let cnns = cnnCap.borrow()!
		let mc= MetadataCollection(path: CNN_NFT.CollectionPublicPath, type: cnns.getType() , conformance: "CNN_NFT.CNN_NFTCollectionPublic", domainUrl: "https://vault.cnn.com", category: "CNN", legacyIdentifierPrefix: "CNN", transferable:true)
		for id in cnns.getIDs() {
			let nft = cnns.borrowCNN_NFT(id: id)!
			let metadata = CNN_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata["name"]!,
				description: metadata["description"] ?? "", 
				image: metadata["preview"]!,
				url: "https://vault.cnn.com",
				contentType: "image",
				rarity: "",
				minter: "",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

	let canesVaultCap = account.getCapability<&Canes_Vault_NFT.Collection{Canes_Vault_NFT.Canes_Vault_NFTCollectionPublic}>(Canes_Vault_NFT.CollectionPublicPath)
	if canesVaultCap.check() {

		let canesVaults = canesVaultCap.borrow()!
		let mc= MetadataCollection(path: Canes_Vault_NFT.CollectionPublicPath, type: canesVaults.getType() , conformance: "Canes_Vault_NFT.Canes_Vault_NFTCollectionPublic", domainUrl: "https://canesvault.com", category: "Canes_Vault", legacyIdentifierPrefix: "Canes_Vault_NFT", transferable:true)
		for id in canesVaults.getIDs() {
			let nft = canesVaults.borrowCanes_Vault_NFT(id: id)!
			let metadata = Canes_Vault_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata["name"]!,
				description: metadata["description"] ?? "", 
				image: metadata["preview"]!,
				url: "https://canesvault.com",
				contentType: "image",
				rarity: "",
				minter: "",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

	let dgdCap = account.getCapability<&DGD_NFT.Collection{DGD_NFT.DGD_NFTCollectionPublic}>(DGD_NFT.CollectionPublicPath)
	if dgdCap.check() {

		let dgds = dgdCap.borrow()!
		let mc= MetadataCollection(path: DGD_NFT.CollectionPublicPath, type: dgds.getType() , conformance: "DGD_NFT.DGD_NFTCollectionPublic", domainUrl: "https://theplayerslounge.io", category: "DGD", legacyIdentifierPrefix: "DGD", transferable:true)
		for id in dgds.getIDs() {
			let nft = dgds.borrowDGD_NFT(id: id)!
			let metadata = DGD_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata["name"]!,
				description: metadata["description"] ?? "", 
				image: metadata["preview"]!,
				url: "https://www.theplayerslounge.io",
				contentType: "image",
				rarity: "",
				minter: "",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}
	
	let raceDayCap = account.getCapability<&RaceDay_NFT.Collection{RaceDay_NFT.RaceDay_NFTCollectionPublic}>(RaceDay_NFT.CollectionPublicPath)
	if raceDayCap.check() {

		let raceDays = raceDayCap.borrow()!
		let mc= MetadataCollection(path: RaceDay_NFT.CollectionPublicPath, type: raceDays.getType() , conformance: "RaceDay_NFT.RaceDay_NFTCollectionPublic", domainUrl: "https://racedaynft.com", category: "RaceDay", legacyIdentifierPrefix: "RaceDay_NFT", transferable:true)
		for id in raceDays.getIDs() {
			let nft = raceDays.borrowRaceDay_NFT(id: id)!
			let metadata = RaceDay_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata["name"]!,
				description: metadata["description"] ?? "", 
				image: metadata["preview"]!,
				url: "https://www.racedaynft.com",
				contentType: "image",
				rarity: "",
				minter: "",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

	let nextCartelCap = account.getCapability<&The_Next_Cartel_NFT.Collection{The_Next_Cartel_NFT.The_Next_Cartel_NFTCollectionPublic}>(The_Next_Cartel_NFT.CollectionPublicPath)
	if nextCartelCap.check() {

		let nextCartels = nextCartelCap.borrow()!
		let mc= MetadataCollection(path: The_Next_Cartel_NFT.CollectionPublicPath, type: nextCartels.getType() , conformance: "The_Next_Cartel_NFT.The_Next_Cartel_NFTCollectionPublic", domainUrl: "https://thenextcartel.com", category: "The_Next_Cartel", legacyIdentifierPrefix: "The_Next_Cartel_NFT", transferable:true)
		for id in nextCartels.getIDs() {
			let nft = nextCartels.borrowThe_Next_Cartel_NFT(id: id)!
			let metadata = The_Next_Cartel_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata["name"]!,
				description: metadata["description"] ?? "", 
				image: metadata["preview"]!,
				url: "https://thenextcartel.com/",
				contentType: "image",
				rarity: "",
				minter: "",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

	let utcCap = account.getCapability<&UFC_NFT.Collection{UFC_NFT.UFC_NFTCollectionPublic}>(UFC_NFT.CollectionPublicPath)
	if utcCap.check() {

		let utcs = utcCap.borrow()!
		let mc= MetadataCollection(path: UFC_NFT.CollectionPublicPath, type: utcs.getType() , conformance: "UFC_NFT.UFC_NFTCollectionPublic", domainUrl: "https://ufcstrike.com", category: "UFC", legacyIdentifierPrefix: "UFC", transferable:true)
		for id in utcs.getIDs() {
			let nft = utcs.borrowUFC_NFT(id: id)!
			let metadata = UFC_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata["name"]!,
				description: metadata["description"] ?? "", 
				image: metadata["image"]!,
				url: "https://ufcstrike.com",
				contentType: "video",
				rarity: "",
				minter: "",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

	let motoGPCollection = account.getCapability<&MotoGPCard.Collection{MotoGPCard.ICardCollectionPublic}>(/public/motogpCardCollection)
	if motoGPCollection.check() {
		let motoGPNfts = motoGPCollection.borrow()!

		let mc= MetadataCollection(path: /public/motogpCardCollection, type: motoGPNfts.getType() , conformance: "MotoGPCard.ICardCollectionPublic", domainUrl: "https://motogp-ignition.com.com", category: "MotoGP", legacyIdentifierPrefix: "MotoGP", transferable:true)
		for id in motoGPNfts.getIDs() {
			let nft = motoGPNfts.borrowCard(id: id)!
			let metadata = nft.getCardMetadata()!
			let item = MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata.name,
				description: metadata.description,
				image: metadata.imageUrl,
				url: "https://motogp-ignition.com/nft/card/".concat(id.toString()).concat("?owner=").concat(address.toString()),
				contentType: "image",
				rarity: "",
				minter: "",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

	let gaiaCollection = account.getCapability<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath)
	if gaiaCollection.check() {

		let gaiaNfts = gaiaCollection.borrow()!

		let mc= MetadataCollection(path: Gaia.CollectionPublicPath, type: gaiaNfts.getType() , conformance: "Gaia.CollectionPublic", domainUrl: "http://ongaia.com", category: "Gaia", legacyIdentifierPrefix: "Gaia", transferable:true)
		for id in gaiaNfts.getIDs() {
			let nft = gaiaNfts.borrowGaiaNFT(id: id)!
			let metadata = Gaia.getTemplateMetaData(templateID: nft.data.templateID)!


			var url=""
			let metadataId=metadata["id"]
			var name=metadata["title"]!
			if metadataId != nil {
				url="http://ongaia.com/ballerz/".concat(metadataId!)
			}
			//For ballerz we can do this...

			if let seriesFullName=metadata["series"] {
				if seriesFullName=="Shareef O\u{2019}Neal - Basketball" {
					//If the series is basketball with shareef we can do this
					url="http://ongaia.com/sharef/".concat(id.toString())
					name=metadata["title"]!.concat(" #").concat(nft.data.mintNumber.toString())
				}else if seriesFullName=="Bryson DeChambeau - Vegas, Baby!" {
					//For golf there is yet another way
					url="http://ongaia.com/bryson/".concat(nft.data.mintNumber.toString())
					name=metadata["title"]!.concat(" #").concat(nft.data.mintNumber.toString())
				}
			}

			let item = MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: name,
				description: metadata["description"] ?? "",
				image: metadata["img"]!,
				url: url,
				contentType: "image",
				rarity: "",
				minter: "",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

	let jambbCap = account.getCapability<&Moments.Collection{Moments.CollectionPublic}>(Moments.CollectionPublicPath)
	if jambbCap.check() {

		let nfts = jambbCap.borrow()!
		let mc= MetadataCollection(path: Moments.CollectionPublicPath, type: nfts.getType() , conformance: "Moments.CollectionPublic", domainUrl: "http://jambb.com", category: "Jambb", legacyIdentifierPrefix: "Jambb", transferable:true)
		for id in nfts.getIDs() {
			let nft = nfts.borrowMoment(id: id)!
			let metadata=nft.getMetadata()
			let item  =MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata.contentName,
				description: metadata.contentDescription,
				image: "ipfs://".concat(metadata.videoHash),
        url: "https://www.jambb.com/c/moment/".concat(id.toString()),
				contentType: "video",
				rarity: "",
				minter: "",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}

	}

	let voucherCap = account.getCapability<&{Vouchers.CollectionPublic}>(Vouchers.CollectionPublicPath)
	if voucherCap.check() {

		let jambb = voucherCap.borrow()!
		let mc= MetadataCollection(path: Vouchers.CollectionPublicPath, type: jambb.getType() , conformance: "Vouchers.CollectionPublic", domainUrl: "http://jambb.com", category: "Jambb", legacyIdentifierPrefix: "JambbVoucher", transferable:false)
		for id in jambb.getIDs() {
			let nft = jambb.borrowVoucher(id: id)!
			let metadata=nft.getMetadata()!

			let url="https://jambb.com"
			let item = MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata.name,
				description: metadata.description,
				image: "ipfs://".concat(metadata.mediaHash),
				url: url,
				contentType: metadata.mediaType,
				rarity: "",
				minter: "",
				type:nft.getType(),
				collection: mc
			)
			items.append(item)
		}

	}

	
	//TODO:matrixworld

  let sturdyCollectionCap = account.getCapability<&SturdyItems.Collection{SturdyItems.SturdyItemsCollectionPublic}>(SturdyItems.CollectionPublicPath)
	if sturdyCollectionCap.check() {
		let sturdyNfts = sturdyCollectionCap.borrow()!

		let mc= MetadataCollection(path: SturdyItems.CollectionPublicPath, type: sturdyNfts.getType() , conformance: "SturdyItems.SturdyItemsCollectionPublic", domainUrl: "http://hoodlumsnft.com.com", category: "Hoodlums", legacyIdentifierPrefix: "Hoodlums", transferable:true)
		for id in sturdyNfts.getIDs() {
			// the metadata is a JSON stored on IPFS at the address nft.tokenURI
			let nft = sturdyNfts.borrowSturdyItem(id: id)!
			// the only thing we can play with is the nft title which is for example:
			// 	- "HOODLUM#10"
			// 	- "HOLIDAY MYSTERY BADGE 2021"
			//  - "EXCALIBUR"
			let isHoodlum = nft.tokenTitle.slice(from: 0, upTo: 7) == "HOODLUM"
			if isHoodlum {
				// the hoodlum id is needed to retrieve the image but is not in the nft
				let hoodlumId = nft.tokenTitle.slice(from: 8, upTo: nft.tokenTitle.length)
				let item=MetadataCollectionItem(
					id: id,
					uuid:nft.uuid,
					name: nft.tokenTitle,
					description: "",
					image: "https://hoodlumsnft.com/_next/image?url=%2Fthumbs%2FsomeHoodlum_".concat(hoodlumId).concat(".png&w=1920&q=75"),
					url: "https://hoodlumsnft.com/",
					contentType:"image",
					rarity: "",
					minter:"",
					type: nft.getType(),
					collection: mc
				)
				items.append(item)
			}
		}
	}

  let charityCap = account.getCapability<&{CharityNFT.CollectionPublic}>(/public/findCharityNFTCollection)
	if charityCap.check() {
		let nfts = charityCap.borrow()!
		let mc= MetadataCollection(path: /public/findCharityNFTCollection, type: nfts.getType() , conformance: "CharityNFT.CollectionPublicPath", domainUrl: "https://find.xyz/neo-x-flowverse-community-charity-tree", category: "Find", legacyIdentifierPrefix: "Charity", transferable:true)

		for id in nfts.getIDs() {
			let nft = nfts.borrowCharity(id: id)!
			let metadata = nft.getMetadata()
			let item=MetadataCollectionItem(
				id: id,
				uuid:nft.uuid,
				name: metadata["name"]!,
				description: "",
				image: metadata["thumbnail"]!,
				url: metadata["originUrl"]!,
				contentType:"image",
				rarity: "",
				minter: "",
				type: nft.getType(),
				collection:mc
			)

			items.append(item)
		}
	}

  let evolutionCap=account.getCapability<&{Evolution.EvolutionCollectionPublic}>(/public/f4264ac8f3256818_Evolution_Collection)
	if evolutionCap.check() {
		let nfts = evolution.getIDs()

		let mc= MetadataCollection(path: /public/f4264ac8f3256818_Evolution_Collection, type: nfts.getType() , conformance: "Evolution.EvolutionCollectionPublic", domainUrl: "https://evolution-collect.com", category: "Evolution", legacyIdentifierPrefix: "Evolution", transferable:true)
		for id in nfts{
			// the metadata is a JSON stored on IPFS at the address nft.tokenURI
			let nft = evolution.borrowCollectible(id: id)!
			let metadata = Evolution.getItemMetadata(itemId: nft.data.itemId)!
			let item=MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata["Title"]!.concat(" #").concat(nft.data.serialNumber.toString()),
				description: metadata["Description"] ?? "",
				image: "https://storage.viv3.com/0xf4264ac8f3256818/mv/".concat(nft.data.itemId.toString()),
				url: "https://www.evolution-collect.com/",
				contentType:"video",
				rarity: "",
				minter:"",
				type:nft.getType(),
				collection:mc
			)

			items.append(item)
		}
	}

  let geniaceCap = account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.CollectionPublic, GeniaceNFT.GeniaceNFTCollectionPublic}>(GeniaceNFT.CollectionPublicPath)
	if geniaceCap.check() {
		let geniace=geniaceCap.borrow()!

		let mc= MetadataCollection(path: GeniaceNFT.CollectionPublic, type: geniace.getType() , conformance: "NonFungibleToken.CollectionPublic, GeniaceNFT.GeniaceNFTCollectionPublic", domainUrl: "https://geniace.com", category: "Geniace", legacyIdentifierPrefix: "Geniace", transferable:true)
		let nfts = geniace.getIDs()
		for id in nfts{
			// the metadata is a JSON stored on IPFS at the address nft.tokenURI
			let nft = geniace.borrowGeniaceNFT(id: id)!
			let metadata = nft.metadata
			var rarity=""
			if metadata.rarity == GeniaceNFT.Rarity.Collectible {
				rarity="Collectible"
			}else if metadata.rarity == GeniaceNFT.Rarity.Rare {
				rarity="Rare"
			}else if metadata.rarity == GeniaceNFT.Rarity.UltraRare {
				rarity="UltraRare"
			}

			let item=MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata.name,
				description:metadata.description,
				image: metadata.imageUrl,
				url: "https://www.geniace.com/product/".concat(id.toString()),
				contentType: metadata.data["mimetype"]!,
				rarity: rarity,
				minter: "",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

// https://flow-view-source.com/mainnet/account/0x6831760534292098/contract/OneFootballCollectible
	let oneFootballCollectibleCap = account.getCapability<&OneFootballCollectible.Collection{OneFootballCollectible.OneFootballCollectibleCollectionPublic}>(OneFootballCollectible.CollectionPublicPath)
	if oneFootballCollectibleCap.check() {
		let nfts = oneFootballCollectibleCap.borrow()!

		let mc= MetadataCollection(path: OneFootballCollectible.ColllectionPublicPath, type: nfts.getType() , conformance: "OneFootballCollectible.OneFootballCollectibleCollectionPublic", domainUrl: "https://xmas.onefootball.com", category: "OneFootball", legacyIdentifierPrefix: "OneFootballCollectible", transferable:true)
		for id in nfts.getIDs() {
			let nft = nfts.borrowOneFootballCollectible(id: id)!
			let metadata = nft.getTemplate()!
			let item=MetadataCollectionItem(
				id: id,
				uuid: nft.uuid,
				name: metadata.name,
				description:metadata.description,
				image: "ipfs://".concat(metadata.media),
				url: "https://xmas.onefootball.com/".concat(account.address.toString()),
				contentType: "video",
				rarity: "",
				minter:"",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

  let cryptoPiggoCap = account.getCapability<&{CryptoPiggo.CryptoPiggoCollectionPublic}>(CryptoPiggo.CollectionPublicPath)
	if cryptoPiggoCap.check() {
		let nfts = cryptoPiggoCap.borrow()!

		let mc= MetadataCollection(path: CryptoPiggo.CollectionPublicPath, type: nfts.getType() , conformance: "CryptoPiggo.CryptoPiggoCollectionPublic", domainUrl: "https://rareworx.com/piggo", category: "CryptoPiggo", legacyIdentifierPrefix: "CryptoPiggo", transferable:true)
		for id in nfts.getIDs() {
			let nft = nfts.borrowItem(id: id)!
			let item=MetadataCollectionItem(
				id: id,
				uuid:nft.uuid,
				name: "CryptoPiggo #".concat(id.toString()),
				description: "",
				image: "https://s3.us-west-2.amazonaws.com/crypto-piggo.nft/piggo-".concat(id.toString()).concat(".png"),
				url: "https://rareworx.com/piggo/details/".concat(id.toString()),
				contentType: "image",
				rarity: "",
				minter:"",
				type: nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

	//TODO: xtingles

	/*
	TODO: goats
	let goatsCap = account.getCapability<&{GoatedGoatsVouchers.GoatsVoucherCollectionPublic}>(GoatedGoatsVouchers.CollectionPublicPath)
	if goatsCap.check() {
		let goatsImageUrl= GoatedGoatsVouchers.getCollectionMetadata()["mediaURL"]!
		let nfts = goatsCap.borrow()!
		let mc= MetadataCollection(path: GoatedGoatsVouchers.CollectionPublicPath, type: nfts.getType() , conformance: "GoatedGoatsVouchers.GoatsVoucherCollectionPublic", domainUrl: "https://goatedgoats.com", category: "GoatedGoats", legacyIdentifierPrefix: "GoatedGoatsVouchers", transferable:false)
		for id in nfts.getIDs() {
			let item=MetadataCollectionItem(
				id: id,
				uuid: nft.get
				name: "Goated Goat Base Goat Voucher #".concat(id.toString()),
				image: goatsImageUrl, 
				url: "https://goatedgoats.com/",
				contentType: "image",
				rarity: ""

			)
			items.append(item)
		}
	}
  
	let goatsTraitCap = account.getCapability<&{TraitPacksVouchers.PackVoucherCollectionPublic}>(TraitPacksVouchers.CollectionPublicPath)
	if goatsTraitCap.check() {
		let goatsImageUrl= TraitPacksVouchers.getCollectionMetadata()["mediaURL"]!
		let collection = goatsTraitCap.borrow()!
		for id in collection.getIDs() {
			let item=MetadataCollectionItem(
				id: id,
				name: "Goated Goat Trait Pack Voucher #".concat(id.toString()),
				image: goatsImageUrl, 
				url: "https://goatedgoats.com/",
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""

			)
			let itemId="GoatedGoatsTraitVoucher".concat(id.toString())
			goats.append(itemId)
			resultMap[itemId] = item
		}
	}
	*/

  let bitkuCap = account.getCapability<&{HaikuNFT.HaikuCollectionPublic}>(HaikuNFT.HaikuCollectionPublicPath)
	if bitkuCap.check() {
		let nfts = bitkuCap.borrow()!

		let mc= MetadataCollection(path: HaikuNFT.CollectionPublicPath, type: nfts.getType() , conformance: "HaikuNFT.HaikuCollectionPublic", domainUrl: "https://bitku.art", category: "Bitku", legacyIdentifierPrefix: "Bitku", transferable:true)
		for id in nfts.getIDs() {
			let nft = nfts.borrowHaiku(id: id)!
			let item = MetadataCollectionItem(
				id: id,
				uuid:nft.uuid,
				name: "Bitku #".concat(id.toString()),
				description:"",
				image: nft.text,
				url: "https://bitku.art/#".concat(address.toString()).concat("/").concat(id.toString()),
				contentType: "text",
				rarity: "",
				minter:"",
				type:nft.getType(),
				collection:mc
			)

			items.append(item)
		}
	}

	let klktnCap = account.getCapability<&{KlktnNFT.KlktnNFTCollectionPublic}>(KlktnNFT.CollectionPublicPath)
	if klktnCap.check() {
		let nfts = klktnCap.borrow()!

		let mc= MetadataCollection(path: KlktnNFT.CollectionPublicPath, type: nfts.getType() , conformance: "KlktnNFT.KlktnNFTCollectionPublic", domainUrl: "https://klktn.com", category: "KLKTN", legacyIdentifierPrefix: "KLKTN", transferable:true)
		for id in nfts.getIDs() {
			let nft = nfts.borrowKlktnNFT(id: id)!

			let metadata=nft.getNFTMetadata()
			/*

			Result: {"uri": "ipfs://bafybeifsiousmtmcruuelgyiku3xa5hmw7ylsyqfdvpjsea7r4xa74bhym", "name": "Kevin Woo - What is KLKTN?", "mimeType": "video/mp4", "media": "https://ipfs.io/ipfs/bafybeifsiousmtmcruuelgyiku3xa5hmw7ylsyqfdvpjsea7r4xa74bhym/fb91ad34d61dde04f02ad240f0ca924902d8b4a3da25daaf0bb1ed769977848c.mp4", "description": "K-pop sensation Kevin Woo has partnered up with KLKTN to enhance his artist to fan interactions and experiences within his fandom. Join our chat to learn more: https://discord.gg/UJxb4erfUw"}

			*/
			let item = MetadataCollectionItem(
				id: id,
				uuid:nft.uuid,
				name: metadata["name"]!,
				description: metadata["description"]!,
				image: metadata["media"]!,
				url: "https://klktn.com/",
				contentType: "video", //metadata["mimeType"]!,
				rarity: "",
				minter:"",
				type:nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

	let mynftCap = account.getCapability<&{Mynft.MynftCollectionPublic}>(Mynft.CollectionPublicPath)
	if mynftCap.check() {
		let nfts = mynftCap.borrow()!

		let mc= MetadataCollection(path: Mynft.CollectionPublicPath, type: nfts.getType() , conformance: "Mynft.MynftCollectionPublic", domainUrl: "https://mynft.io", category: "mynft", legacyIdentifierPrefix: "mynft", transferable:true)
		for id in nfts.getIDs() {
			let nft = nfts.borrowArt(id: id)!
			let metadata=nft.metadata

			var image= metadata.ipfsLink
			if image == "" {
				image="https://arweave.net/".concat(metadata.arLink)
			}
			let item = MetadataCollectionItem(
				id: id,
				uuid:nft.uuid,
				name: metadata.name,
				description:metadata.description,
				image: image,
				url: "http://mynft.io",
				contentType: metadata.type,
				rarity: "",
				minter:"",
				type:nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}

	/*
	TODO: add when url fixed
	let beamCap = account.getCapability<&{Beam.BeamCollectionPublic}>(Beam.CollectionPublicPath)
		if beamCap.check() {
		let nfts = beamCap.borrow()!

		let mc= MetadataCollection(path: Beam.CollectionPublicPath, type: nfts.getType() , conformance: "Beam.BeamCollectionPublic", domainUrl: "https://https://frightclub.niftory.com", category: "FrightClub", legacyIdentifierPrefix: "FrightClub", transferable:true)
		for id in nfts.getIDs() {
			let nft = nfts.borrowCollectible(id: id)!

	    let metadata = Beam.getCollectibleItemMetaData(collectibleItemID: nft.data.collectibleItemID)!
		  var mediaUrl: String? = metadata["mediaUrl"]
			if mediaUrl != nil &&  mediaUrl!.slice(from: 0, upTo: 7) != "ipfs://" {
				mediaUrl = "ipfs://".concat(mediaUrl!)
			}
			let item = MetadataCollectionItem(
				id: id,
				uuid:nft.uuid,
				name: metadata["title"]!,
				description: metadata["description"] ?? "",
				image: mediaUrl ?? "",
				url: "https://".concat(metadata["domainUrl"]!),
				contentType: metadata["mediaType"]!,
				rarity: "",
				minter:"",
				type:nft.getType(),
				collection:mc
			)
			items.append(item)
		}
	}
	*/

	collection.addCollection(items: items)

	//Adding a collection that supports the metadata standard is SOOO much easier
	collection.addMetadataCollection(path: NeoAvatar.CollectionPublicPath, account: account, category: "Neo", legacyIdentifierPrefix: "NeoAvatar", url: "https://neocollectibles.xyz", transferable: true)

	if collection.collections.length==0 {
		return nil
	}
	return collection
}

