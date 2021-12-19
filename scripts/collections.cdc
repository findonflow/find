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

	let flovatarList= Flovatar.getFlovatars(address: address)
	if flovatarList.length > 0 {
		let items: [MetadataCollectionItem] = []
		for flovatar in flovatarList  {
			var name = flovatar.name
			if name == "" {
				name="Flovatar #".concat(flovatar.id.toString())
			}
			items.append(MetadataCollectionItem(
				id: flovatar.id, 
				name: name, 
				image: "https://flovatar.com/api/image/".concat(flovatar.id.toString()),
				url: "https://flovatar.com/flovatars/".concat(flovatar.id.toString()).concat("/").concat(address.toString()),
				listPrice: nil,
				listToken: nil
			))
		}

		results["flovatar"] = MetadataCollection(type: Type<@Flovatar.Collection>().identifier, items: items)
	}

	let flovatarMarketDetails = FlovatarMarketplace.getFlovatarSales(address: address)
	if flovatarMarketDetails.length > 0 {
		let items: [MetadataCollectionItem] = []
		for flovatar in flovatarMarketDetails  {
			var	name="Flovatar #".concat(flovatar.id.toString())
			items.append(MetadataCollectionItem(
				id: flovatar.id, 
				name: name, 
				image: "https://flovatar.com/api/image/".concat(flovatar.id.toString()),
				url: "https://flovatar.com/flovatars/".concat(flovatar.id.toString()).concat("/").concat(address.toString()),
				listPrice: flovatar.price,
				listToken: "Flow"
			))
		}

		if items.length != 0 {
			results["flovatarSales"] = MetadataCollection(type: Type<@Flovatar.Collection>().identifier, items: items)
		}
	}

	let versusImageUrlPrefix = "https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_600/f_auto/maincache"
	let artList = Art.getArt(address: address)
	if artList.length > 0 {
		let items: [MetadataCollectionItem] = []
		for art in artList {
			items.append(MetadataCollectionItem(
				id: art.id, 
				name: art.metadata.name.concat(" edition ").concat(art.metadata.edition.toString()).concat("/").concat(art.metadata.maxEdition.toString()).concat(" by ").concat(art.metadata.artist),  
				image: versusImageUrlPrefix.concat(art.cacheKey), 
				url: "https://www.versus.auction/piece/".concat(address.toString()).concat("/").concat(art.id.toString()).concat("/"),
				listPrice: nil,
				listToken: nil
			))
		}
		results["versus"]= MetadataCollection(type: Type<@Art.Collection>().identifier, items: items)
	}

	let versusMarketplace = account.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
	if versusMarketplace.check() {
		let items: [MetadataCollectionItem] = []
		let versusMarket = versusMarketplace.borrow()!.listSaleItems()
		for saleItem in versusMarket {
			items.append(MetadataCollectionItem(
				id: saleItem.id, 
				name: saleItem.art.name.concat(" edition ").concat(saleItem.art.edition.toString()).concat("/").concat(saleItem.art.maxEdition.toString()).concat(" by ").concat(saleItem.art.artist),
				image: versusImageUrlPrefix.concat(saleItem.cacheKey), 
				url: "https://www.versus.auction/listing/".concat(saleItem.id.toString()).concat("/"),
				listPrice: saleItem.price,
				listToken: "Flow"
			))
		}
		if items.length != 0 {
			results["versusSale"]= MetadataCollection(type: Type<@Marketplace.SaleCollection>().identifier, items: items)
		}
	}


	let goobersCap = account.getCapability<&GooberXContract.Collection{NonFungibleToken.CollectionPublic, GooberXContract.GooberCollectionPublic}>(GooberXContract.CollectionPublicPath)

	if goobersCap.check() {
		let items: [MetadataCollectionItem] = []
		let goobers = goobersCap.borrow()!.listUsersGoobers()
		for id in goobers.keys {
			let goober = goobers[id]!
			items.append(MetadataCollectionItem(
				id: id,
				name: "Goober #".concat(id.toString()),
				image: goober.uri,
				url: "https://partymansion.io/gooberz/".concat(id.toString()),
				listPrice: nil,
				listToken: nil
			))

		}
		if items.length != 0 {
			results["goobers"] = MetadataCollection(type: Type<@GooberXContract.Collection>().identifier, items: items)
		}
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
		results["basicbeasts"] = MetadataCollection(type: Type<@BasicBeast.Collection>().identifier, items: items)
	}
	*/


	let rareRoomCollection = account.getCapability<&RareRooms_NFT.Collection{RareRooms_NFT.RareRooms_NFTCollectionPublic}>(RareRooms_NFT.CollectionPublicPath)
	if rareRoomCollection.check() {
		let rareRoomNfts = rareRoomCollection.borrow()!.getIDs()
		let items: [MetadataCollectionItem] = []
		for id in rareRoomNfts {
			let nft = rareRoomCollection.borrow()!.borrowRareRooms_NFT(id: id)!
			items.append(MetadataCollectionItem(
				id: id,
				name: RareRooms_NFT.getSetMetadataByField(setId: nft.setId, field: "name")!,
				// we use "preview" and not "image" because of potential .glg and .mp4 file types
				image: RareRooms_NFT.getSetMetadataByField(setId: nft.setId, field: "preview")!,
				url: "https://rarerooms.io/tokens/".concat(id.toString()),
				listPrice: nil,
				listToken: nil
			))
		}

		if items.length != 0 {
			results["RareRooms"] = MetadataCollection(type: Type<@RareRooms_NFT.Collection>().identifier, items: items)
		}
	}


	let motoGPCollection = account.getCapability<&MotoGPCard.Collection{MotoGPCard.ICardCollectionPublic}>(/public/motogpCardCollection)
	if motoGPCollection.check() {
		let motoGPNfts = motoGPCollection.borrow()!.getIDs()
		let items: [MetadataCollectionItem] = []
		for id in motoGPNfts {
			let nft = motoGPCollection.borrow()!.borrowCard(id: id)!
			let metadata = nft.getCardMetadata()!
			items.append(MetadataCollectionItem(
				id: id,
				name: metadata.name,
				image: metadata.imageUrl,
				url: "https://motogp-ignition.com/nft/card/".concat(id.toString()).concat("?owner=").concat(address.toString()),
				listPrice: nil,
				listToken: nil
			))
		}

		if items.length != 0 {
			results["MotoGP"] = MetadataCollection(type: Type<@MotoGPCard.Collection>().identifier, items: items)
		}
	}

	let gaiaCollection = account.getCapability<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath)
	if gaiaCollection.check() {
		let gaiaNfts = gaiaCollection.borrow()!.getIDs()
		let items: [MetadataCollectionItem] = []
		for id in gaiaNfts {
			let nft = gaiaCollection.borrow()!.borrowGaiaNFT(id: id)!
			let metadata = Gaia.getTemplateMetaData(templateID: nft.data.templateID)!
			items.append(MetadataCollectionItem(
				id: id,
				name: metadata["title"]!,
				image: metadata["img"]!,
				url: metadata["uri"]!,
				listPrice: nil,
				listToken: nil
			))
		}

		if items.length != 0 {
			results["Gaia"] = MetadataCollection(type: Type<@Gaia.Collection>().identifier, items: items)
		}
	}

	let chainmonstersRewardsCollection = account.getCapability<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>(/public/ChainmonstersRewardCollection)
	if chainmonstersRewardsCollection.check() {
		let nfts = chainmonstersRewardsCollection.borrow()!.getIDs()
		let items: [MetadataCollectionItem] = []
		for id in nfts {
			let nft = chainmonstersRewardsCollection.borrow()!.borrowReward(id: id)!
			let rewardID = nft.data.rewardID
			// Other interesting metadata available are:
			// 		- serialNumber: nft.data.serialNumber
			// 		- totalMinted: ChainmonstersRewards.getNumRewardsMinted(rewardID: nft.data.rewardID)!
			let season = ChainmonstersRewards.getRewardSeason(rewardID:nft.data.rewardID)!
			var seasonName="closedbeta"
			if season == 3 {
				seasonName="flowfest2021"
			}
			items.append(MetadataCollectionItem(
				id: id,
				name: ChainmonstersRewards.getRewardMetaData(rewardID: nft.data.rewardID)!,
				image: "https://chainmonsters.com/_next/image?w=384&q=75&url=/images/rewards/".concat(seasonName).concat("/").concat(rewardID.toString()).concat(".png"),
				url: "https://chainmonsters.com",
				listPrice: nil,
				listToken: nil
			))
		}
		if items.length != 0 {
			results["ChainmonstersRewards"] = MetadataCollection(type: Type<@ChainmonstersRewards.Collection>().identifier, items: items)
		}
	}


	if results.keys.length == 0 {
		return nil
	}
	return results
}
