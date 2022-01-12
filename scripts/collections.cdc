import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"

//mainnet
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
import MotoGPCard from 0xa49cc0ee46c54bfb
import Gaia from 0x8b148183c28ff88f
import ChainmonstersRewards from 0x93615d25d14fa337
import Moments from 0xd4ad4740ee426334
import MatrixWorldFlowFestNFT from 0x2d2750f240198f91
import SturdyItems from 0x427ceada271aa0b1
import Evolution from 0xf4264ac8f3256818
import GeniaceNFT from 0xabda6627c70c7f52


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

	let resultMap : {String : MetadataCollectionItem} = {}
	let account = getAccount(address)
	let results : {String :  [String]}={}

	let flovatarList= Flovatar.getFlovatars(address: address)
	let flovatarMarketDetails = FlovatarMarketplace.getFlovatarSales(address: address)
	if flovatarList.length > 0 || flovatarMarketDetails.length > 0 {
		let items: [String] = []
		for flovatar in flovatarList  {
			var name = flovatar.name
			if name == "" {
				name="Flovatar #".concat(flovatar.id.toString())
			}

			var rarity="common"
			if flovatar.metadata.legendaryCount > 0 {
				rarity="legendary"
			}else if flovatar.metadata.epicCount > 0 {
				rarity="epic"
			}else if flovatar.metadata.rareCount > 0 {
				rarity="rare"
			}


			let item=MetadataCollectionItem(
				id: flovatar.id, 
				name: name, 
				image: "https://flovatar.com/api/image/".concat(flovatar.id.toString()),
				url: "https://flovatar.com/flovatars/".concat(flovatar.id.toString()).concat("/"),
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: rarity
			)
			let itemId="Flovatar".concat(flovatar.id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		for flovatar in flovatarMarketDetails  {
			var	name="Flovatar #".concat(flovatar.id.toString())

			var rarity="common"
			if flovatar.metadata.legendaryCount > 0 {
				rarity="legendary"
			}else if flovatar.metadata.epicCount > 0 {
				rarity="epic"
			}else if flovatar.metadata.rareCount > 0 {
				rarity="rare"
			}


			let item=MetadataCollectionItem(
				id: flovatar.id, 
				name: name, 
				image: "https://flovatar.com/api/image/".concat(flovatar.id.toString()),
				url: "https://flovatar.com/flovatars/".concat(flovatar.id.toString()).concat("/"),
				listPrice: flovatar.price,
				listToken: "Flow",
				contentType: "image",
				rarity: rarity
			)

			let itemId="Flovatar".concat(flovatar.id.toString())
			items.append(itemId)
			resultMap[itemId] = item

		}

		if items.length != 0 {
			results["Flovatar"] = items
		}
	}

	let versusMarketplace = account.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
	let versusImageUrlPrefix = "https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_600/f_auto/maincache"
	let artList = Art.getArt(address: address)
	if artList.length > 0 || versusMarketplace.check() {
		let items: [String] = []
		for art in artList {
			let item=MetadataCollectionItem(
				id: art.id, 
				name: art.metadata.name.concat(" edition ").concat(art.metadata.edition.toString()).concat("/").concat(art.metadata.maxEdition.toString()).concat(" by ").concat(art.metadata.artist),  
				image: versusImageUrlPrefix.concat(art.cacheKey), 
				url: "https://www.versus.auction/piece/".concat(address.toString()).concat("/").concat(art.id.toString()).concat("/"),
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""

			)
			let itemId="Versus".concat(art.id.toString())
			items.append(itemId)
			resultMap[itemId] = item

		}
		if versusMarketplace.check() {
			let versusMarket = versusMarketplace.borrow()!.listSaleItems()
			for saleItem in versusMarket {
				let item=MetadataCollectionItem(
					id: saleItem.id, 
					name: saleItem.art.name.concat(" edition ").concat(saleItem.art.edition.toString()).concat("/").concat(saleItem.art.maxEdition.toString()).concat(" by ").concat(saleItem.art.artist),
					image: versusImageUrlPrefix.concat(saleItem.cacheKey), 
					url: "https://www.versus.auction/listing/".concat(saleItem.id.toString()).concat("/"),
					listPrice: saleItem.price,
					listToken: "Flow",
					contentType: "image",
				rarity: ""

				)

				let itemId="Versus".concat(saleItem.id.toString())
				items.append(itemId)
				resultMap[itemId] = item
			}
		}
		if items.length != 0 {
			results["Versus"]= items
		}
	}




	let goobersCap = account.getCapability<&GooberXContract.Collection{NonFungibleToken.CollectionPublic, GooberXContract.GooberCollectionPublic}>(GooberXContract.CollectionPublicPath)

	if goobersCap.check() {
		let items: [String] = []
		let goobers = goobersCap.borrow()!.listUsersGoobers()
		for id in goobers.keys {
			let goober = goobers[id]!
			let item=MetadataCollectionItem(
				id: id,
				name: "Goober #".concat(id.toString()),
				image: goober.uri,
				url: "https://partymansion.io/gooberz/".concat(id.toString()),
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""

			)
			let itemId="Gooberz".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}
		if items.length != 0 {
			results["Gooberz"] = items
		}
	}

	let rareRoomCap = account.getCapability<&RareRooms_NFT.Collection{RareRooms_NFT.RareRooms_NFTCollectionPublic}>(RareRooms_NFT.CollectionPublicPath)
	if rareRoomCap.check() {
		let collection = rareRoomCap.borrow()!
		let items: [String] = []
		for id in collection.getIDs() {
			let nft = collection.borrowRareRooms_NFT(id: id)!
			let metadata = RareRooms_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				name: metadata["name"]!,
				// we use "preview" and not "image" because of potential .glg and .mp4 file types
				image: metadata["preview"]!,
				url: "https://rarerooms.io/tokens/".concat(id.toString()),
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""

			)

			let itemId="RareRooms".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["RareRooms"] = items
		}
	}

	let cnnCap = account.getCapability<&CNN_NFT.Collection{CNN_NFT.CNN_NFTCollectionPublic}>(CNN_NFT.CollectionPublicPath)
	if cnnCap.check() {
		let collection = cnnCap.borrow()!
		let items: [String] = []
		for id in collection.getIDs() {
			let nft = collection.borrowCNN_NFT(id: id)!
			let metadata = CNN_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				name: metadata["name"]!,
				// we use "preview" and not "image" because of potential .glg and .mp4 file types
				image: metadata["preview"]!,
				url: metadata["external_url"]!,
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""
			)

			let itemId="CNN".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["CNN"] = items
		}
	}

	let canesVaultCap = account.getCapability<&Canes_Vault_NFT.Collection{Canes_Vault_NFT.Canes_Vault_NFTCollectionPublic}>(Canes_Vault_NFT.CollectionPublicPath)
	if canesVaultCap.check() {
		let collection = canesVaultCap.borrow()!
		let items: [String] = []
		for id in collection.getIDs() {
			let nft = collection.borrowCanes_Vault_NFT(id: id)!
			let metadata = Canes_Vault_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				name: metadata["name"]!,
				// we use "preview" and not "image" because of potential .glg and .mp4 file types
				image: metadata["preview"]!,
				url: metadata["external_url"]!,
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""
			)

			let itemId="Canes_Vault_NFT".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["Canes_Vault_NFT"] = items
		}
	}

	let dgdCap = account.getCapability<&DGD_NFT.Collection{DGD_NFT.DGD_NFTCollectionPublic}>(DGD_NFT.CollectionPublicPath)
	if dgdCap.check() {
		let collection = dgdCap.borrow()!
		let items: [String] = []
		for id in collection.getIDs() {
			let nft = collection.borrowDGD_NFT(id: id)!
			let metadata = DGD_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				name: metadata["name"]!,
				// we use "preview" and not "image" because of potential .glg and .mp4 file types
				image: metadata["preview"]!,
				url: metadata["external_url"]!,
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""
			)

			let itemId="DGD_NFT".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["DGD_NFT"] = items
		}
	}

	let raceDayCap = account.getCapability<&RaceDay_NFT.Collection{RaceDay_NFT.RaceDay_NFTCollectionPublic}>(RaceDay_NFT.CollectionPublicPath)
	if raceDayCap.check() {
		let collection = raceDayCap.borrow()!
		let items: [String] = []
		for id in collection.getIDs() {
			let nft = collection.borrowRaceDay_NFT(id: id)!
			let metadata = RaceDay_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				name: metadata["name"]!,
				// we use "preview" and not "image" because of potential .glg and .mp4 file types
				image: metadata["preview"]!,
				url: metadata["external_url"]!,
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""
			)

			let itemId="RaceDay_NFT".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["RaceDay_NFT"] = items
		}
	}

	let nextCartelCap = account.getCapability<&The_Next_Cartel_NFT.Collection{The_Next_Cartel_NFT.The_Next_Cartel_NFTCollectionPublic}>(The_Next_Cartel_NFT.CollectionPublicPath)
	if nextCartelCap.check() {
		let collection = nextCartelCap.borrow()!
		let items: [String] = []
		for id in collection.getIDs() {
			let nft = collection.borrowThe_Next_Cartel_NFT(id: id)!
			let metadata = The_Next_Cartel_NFT.getSetMetadata(setId: nft.setId)!
			let item = MetadataCollectionItem(
				id: id,
				name: metadata["name"]!,
				// we use "preview" and not "image" because of potential .glg and .mp4 file types
				image: metadata["preview"]!,
				url: metadata["external_url"]!,
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""
			)

			let itemId="The_Next_Cartel_NFT".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["The_Next_Cartel_NFT"] = items
		}
	}

	let motoGPCollection = account.getCapability<&MotoGPCard.Collection{MotoGPCard.ICardCollectionPublic}>(/public/motogpCardCollection)
	if motoGPCollection.check() {
		let motoGPNfts = motoGPCollection.borrow()!.getIDs()
		let items: [String] = []
		for id in motoGPNfts {
			let nft = motoGPCollection.borrow()!.borrowCard(id: id)!
			let metadata = nft.getCardMetadata()!
			let item=MetadataCollectionItem(
				id: id,
				name: metadata.name,
				image: metadata.imageUrl,
				url: "https://motogp-ignition.com/nft/card/".concat(id.toString()).concat("?owner=").concat(address.toString()),
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""

			)


			let itemId="MotoGP".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["MotoGP"] = items
		}
	}

	let gaiaCollection = account.getCapability<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath)
	if gaiaCollection.check() {

		let gaiaNfts = gaiaCollection.borrow()!.getIDs()
		let items: [String] = []
		for id in gaiaNfts {
			let nft = gaiaCollection.borrow()!.borrowGaiaNFT(id: id)!
			let metadata = Gaia.getTemplateMetaData(templateID: nft.data.templateID)!


			//For ballerz we can do this...
			var url="http://ongaia.com/ballerz/".concat(id.toString())
			var name=metadata["title"]!

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


			let item= MetadataCollectionItem(
				id: id,
				name: name,
				image: metadata["img"]!,
				url: url,
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""

			)

			let itemId="Gaia".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["Gaia"] = items
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
				listToken: nil,
				contentType: "image"
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
		let items: [String] = []
		for id in nfts {
			let nft = jambbCap.borrow()!.borrowMoment(id: id)!
			let metadata=nft.getMetadata()
			let item  =MetadataCollectionItem(
				id: id,
				name: metadata.contentName,
				image: metadata.previewImage,
				url: "http://jambb.com",
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""

			)
			let itemId="Jambb".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["Jambb"] = items
		}
	}

	let mw = MatrixWorldFlowFestNFT.getNft(address:address)
	if mw.length > 0 {
		let items: [String] = []
		for nft in mw {
			let metadata=nft.metadata
			let item=MetadataCollectionItem(
				id: nft.id,
				name: metadata.name,
				image: metadata.animationUrl,
				url: "https://matrixworld.org/",
				listPrice: nil,
				listToken: nil,
				contentType: "image",
				rarity: ""

			)
			let itemId="MatrixWorldFlowFest".concat(nft.id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["MatrixWorld"] = items
		}
	}

	let sturdyCollectionCap = account
	.getCapability<&SturdyItems.Collection{SturdyItems.SturdyItemsCollectionPublic}>(SturdyItems.CollectionPublicPath)
	if sturdyCollectionCap.check() {
		let sturdyNfts = sturdyCollectionCap.borrow()!.getIDs()
		let items: [String] = []
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
				let item=MetadataCollectionItem(
					id: id,
					name: nft.tokenTitle,
					image: "https://hoodlumsnft.com/_next/image?url=%2Fthumbs%2FsomeHoodlum_".concat(hoodlumId).concat(".png&w=1920&q=75"),
					url: "https://hoodlumsnft.com/",
					listPrice:nil,
					listToken:nil,
					contentType:"image",
				rarity: ""

				)
				let itemId="Hoodlums".concat(id.toString())
				items.append(itemId)
				resultMap[itemId] = item
			}
		}
		if items.length != 0 {
			results["Hoodlums"] = items
		}
	}

	let charityCap = account.getCapability<&{CharityNFT.CollectionPublic}>(/public/findCharityNFTCollection)
	if charityCap.check() {
		let items: [String] = []
		let collection = charityCap.borrow()!
		for id in collection.getIDs() {
			let nft = collection.borrowCharity(id: id)!
			let metadata = nft.getMetadata()
			let item=MetadataCollectionItem(
				id: id,
				name: metadata["name"]!,
				image: metadata["thumbnail"]!,
				url: metadata["originUrl"]!,
				listPrice: nil,
				listToken: nil,
				contentType:"image",
				rarity: ""

			)
			let itemId="Charity".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item

		}
		if items.length != 0 {
			results["Find"] = items
		}
	}

	let evolutionCap=account.getCapability<&{Evolution.EvolutionCollectionPublic}>(/public/f4264ac8f3256818_Evolution_Collection)
	if evolutionCap.check() {
		let evolution=evolutionCap.borrow()!
		let nfts = evolution.getIDs()
		let items: [String] = []
		for id in nfts{
			// the metadata is a JSON stored on IPFS at the address nft.tokenURI
			let nft = evolution.borrowCollectible(id: id)!
			let metadata = Evolution.getItemMetadata(itemId: nft.data.itemId)!
			let item=MetadataCollectionItem(
				id: id,
				name: metadata["Title"]!,
				image: "https://storage.viv3.com/0xf4264ac8f3256818/mv/".concat(nft.data.itemId.toString()),
				url: "https://www.evolution-collect.com/",
				listPrice: nil,
				listToken: nil,
				contentType:"video",
				rarity: ""

			)

			let itemId="Evolution".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["Evolution"] = items
		}
	}


  let geniaceCap = account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.CollectionPublic, GeniaceNFT.GeniaceNFTCollectionPublic}>(GeniaceNFT.CollectionPublicPath)

	if geniaceCap.check() {
		let geniace=geniaceCap.borrow()!
		let nfts = geniace.getIDs()
		let items: [String] = []
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
				name: metadata.name,
				image: metadata.imageUrl,
				url: "https://www.geniace.com/product/".concat(metadata.name),
				listPrice: nil,
				listToken: nil,
				contentType: metadata.data["mimetype"]!,
				rarity: rarity,
			)

			let itemId="Geniace".concat(id.toString())
			items.append(itemId)
			resultMap[itemId] = item
		}

		if items.length != 0 {
			results["Geniace"] = items
		}
	}

	if results.keys.length == 0 {
		return nil
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
