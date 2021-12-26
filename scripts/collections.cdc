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
import MatrixWorldFlowFestNFT from 0x2d2750f240198f91
import SturdyItems from 0x427ceada271aa0b1


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
	let flovatarMarketDetails = FlovatarMarketplace.getFlovatarSales(address: address)
	if flovatarList.length > 0 || flovatarMarketDetails.length > 0 {
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
				url: "https://flovatar.com/flovatars/".concat(flovatar.id.toString()).concat("/"),
				listPrice: nil,
				listToken: nil
			))
		}

		for flovatar in flovatarMarketDetails  {
			var	name="Flovatar #".concat(flovatar.id.toString())
			items.append(MetadataCollectionItem(
				id: flovatar.id, 
				name: name, 
				image: "https://flovatar.com/api/image/".concat(flovatar.id.toString()),
				url: "https://flovatar.com/flovatars/".concat(flovatar.id.toString()).concat("/"),
				listPrice: flovatar.price,
				listToken: "Flow"
			))
		}

		if items.length != 0 {
			results["Flovatar"] = MetadataCollection(type: Type<@Flovatar.Collection>().identifier, items: items)
		}
	}

	let versusMarketplace = account.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
	let versusImageUrlPrefix = "https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_600/f_auto/maincache"
	let artList = Art.getArt(address: address)
	if artList.length > 0 || versusMarketplace.check() {
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
		if versusMarketplace.check() {
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
		}
		if items.length != 0 {
			results["Versus"]= MetadataCollection(type: Type<@Art.Collection>().identifier, items: items)
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
			results["Gooberz"] = MetadataCollection(type: Type<@GooberXContract.Collection>().identifier, items: items)
		}
	}

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

	/*
	let chamonsterSeasonTable :  {UInt32: String} = {0 : "kickstarter", 1 : "alpha", 2 : "genesis", 4 : "flowfest2021" , 3: "closedbeta" }

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

			var seasonName = chamonsterSeasonTable[season] ?? "unknown".concat(season.toString())

			if season == 3 && rewardID < 45 {
				seasonName = "flowfest2021"
			}
			items.append(MetadataCollectionItem(
				id: id,
				name: ChainmonstersRewards.getRewardMetaData(rewardID: nft.data.rewardID)!,
				image: "https://chainmonsters.com/images/rewards/".concat(seasonName).concat("/").concat(rewardID.toString()).concat(".png"),
				url: "https://chainmonsters.com",
				listPrice: nil,
				listToken: nil
			))
		}
		if items.length != 0 {
			results["ChainmonstersRewards"] = MetadataCollection(type: Type<@ChainmonstersRewards.Collection>().identifier, items: items)
		}
	}
	*/

	let jambbCap = account.getCapability<&Moments.Collection{Moments.CollectionPublic}>(Moments.CollectionPublicPath)
	if jambbCap.check() {
		let nfts = jambbCap.borrow()!.getIDs()
		let items: [MetadataCollectionItem] = []
		for id in nfts {
			let nft = jambbCap.borrow()!.borrowMoment(id: id)!
			let metadata=nft.getMetadata()
			items.append(MetadataCollectionItem(
				id: id,
				name: metadata.contentName,
				image: metadata.previewImage,
				url: "http://jambb.com",
				listPrice: nil,
				listToken: nil
			))
		}

		if items.length != 0 {
			results["Jambb"] = MetadataCollection(type: Type<@Moments.Collection>().identifier, items: items)
		}
	}

	let mw = MatrixWorldFlowFestNFT.getNft(address:address)
	if mw.length > 0 {
		let items: [MetadataCollectionItem] = []
		for nft in mw {
			let metadata=nft.metadata
			items.append(MetadataCollectionItem(
				id: nft.id,
				name: metadata.name,
				image: metadata.animationUrl,
				url: "https://matrixworld.org/",
				listPrice: nil,
				listToken: nil
			))
		}

		if items.length != 0 {
			results["MatrixWorld"] = MetadataCollection(type: Type<@MatrixWorldFlowFestNFT.Collection>().identifier, items: items)
		}
	}

	let sturdyCollectionCap = account
        .getCapability<&SturdyItems.Collection{SturdyItems.SturdyItemsCollectionPublic}>(SturdyItems.CollectionPublicPath)
	if sturdyCollectionCap.check() {
		let sturdyNfts = sturdyCollectionCap.borrow()!.getIDs()
		let items: [MetadataCollectionItem] = []
		for id in sturdyNfts {
			// the metadata is a JSON stored on IPFS at the address nft.tokenURI
			let nft = sturdyCollectionCap.borrow()!.borrowSturdyItem(id: id)!
			// the only thing we can play with is the nft title which is for example:
			// 	- "HOODLUM#10"
			// 	- "HOLIDAY MYSTERY BADGE 2021"
			//  - "EXCALIBUR"
			let isHoodlum = nft.tokenTitle.slice(from: 0, upTo: 7) == "HOODLUM"
			if isHoodlum {
				// the hoodlum id is needed to retrieve the image but is not in the nft
				let hoodlumId = nft.tokenTitle.slice(from: 8, upTo: nft.tokenTitle.length)
				items.append(MetadataCollectionItem(
					id: id,
					name: nft.tokenTitle,
					image: "https://hoodlumsnft.com/_next/image?url=%2Fthumbs%2FsomeHoodlum_".concat(hoodlumId).concat(".png&w=1920&q=75"),
					url: "https://hoodlumsnft.com/"
				))
			}
		}
        results["Hoodlums"] = MetadataCollection(type: Type<@SturdyItems.Collection>().identifier, items: items)
    }

	if results.keys.length == 0 {
		return nil
	}
	return results
}
