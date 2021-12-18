import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

//mainnet
import Art from 0xd796ff17107bbff6
import Marketplace from 0xd796ff17107bbff6
import GooberXContract from 0x34f2bf4a80bb0f69
import Flovatar from 0x921ea449dffec68a
import RareRooms_NFT from 0x329feb3ab062d289
import MotoGPCard from 0xa49cc0ee46c54bfb
import Gaia from 0x8b148183c28ff88f


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


	init(id:UInt64, name:String, image:String, url:String) {
		self.id=id
		self.name=name
		self.url=url
		self.image=image
	}
}

pub fun main(address: Address) : {String : MetadataCollection}? {

	let account = getAccount(address)
	let results : {String :  MetadataCollection}={}

	let versusImageUrlPrefix = "https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_600/f_auto/maincache"
	let artList = Art.getArt(address: address)
	if artList.length > 0 {
		let items: [MetadataCollectionItem] = []
		for art in artList {
			items.append(MetadataCollectionItem(
				id: art.id, 
				name: art.metadata.name.concat(" edition ").concat(art.metadata.edition.toString()).concat("/").concat(art.metadata.maxEdition.toString()).concat(" by ").concat(art.metadata.artist),  
				image: versusImageUrlPrefix.concat(art.cacheKey), 
				url: "https://www.versus.auction/piece/".concat(address.toString()).concat("/").concat(art.id.toString()).concat("/")
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
				name: saleItem.art.name.concat(" edition ").concat(saleItem.art.edition.toString()).concat("/").concat(saleItem.art.maxEdition.toString()).concat(" by ").concat(saleItem.art.artist).concat(" for sale for ").concat(saleItem.price.toString()).concat(" Flow"),  
				image: versusImageUrlPrefix.concat(saleItem.cacheKey), 
				url: "https://www.versus.auction/listing/".concat(saleItem.id.toString()).concat("/")
			))
		}
		results["versusSale"]= MetadataCollection(type: Type<@Marketplace.SaleCollection>().identifier, items: items)
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
				url: "https://partymansion.io/gooberz/".concat(id.toString())
			))

		}
		results["goobers"] = MetadataCollection(type: Type<@GooberXContract.Collection>().identifier, items: items)
	}

	let flovatarList= Flovatar.getFlovatars(address: address)
	if flovatarList.length > 0 {
		let items: [MetadataCollectionItem] = []
		for flovatar in flovatarList  {
			let flovatarDetails = Flovatar.getFlovatar(address: address, flovatarId: flovatar.id)
			var name = flovatar.name
			if name == "" {
				name="Flovatar #".concat(flovatar.id.toString())
			}
			items.append(MetadataCollectionItem(
				id: flovatar.id, 
				name: name, 
				image: "https://flovatar.com/api/image/".concat(flovatar.id.toString()),
				url: "https://flovatar.com/flovatars/".concat(flovatar.id.toString()).concat("/").concat(address.toString()),
			))
		}
		results["flovatar"] = MetadataCollection(type: Type<@Flovatar.Collection>().identifier, items: items)
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
				url: "https://rarerooms.io/tokens/".concat(id.toString())
			))
		}
		results["RareRooms"] = MetadataCollection(type: Type<@RareRooms_NFT.Collection>().identifier, items: items)
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
			))
		}
		results["MotoGP"] = MetadataCollection(type: Type<@MotoGPCard.Collection>().identifier, items: items)
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
				url: metadata["uri"]!
			))
		}
		results["Gaia"] = MetadataCollection(type: Type<@Gaia.Collection>().identifier, items: items)
	}

	let chainmonstersRewardsCollection = account
		.getCapability<&{ChainmonstersRewards.ChainmonstersRewardCollectionPublic}>(/public/ChainmonstersRewardCollection)
	if chainmonstersRewardsCollection.check() {
		let nfts = chainmonstersRewardsCollection.borrow()!.getIDs()
		let items: [MetadataCollectionItem] = []
		for id in nfts {
			let nft = chainmonstersRewardsCollection.borrow()!.borrowReward(id: id)!
			let rewardID = nft.data.rewardID
			// Other interesting metadata available are:
			// 		- serialNumber: nft.data.serialNumber
			// 		- totalMinted: ChainmonstersRewards.getNumRewardsMinted(rewardID: nft.data.rewardID)!
			items.append(MetadataCollectionItem(
				id: id,
				name: ChainmonstersRewards.getRewardMetaData(rewardID: nft.data.rewardID)!,
				image: "https://chainmonsters.com/_next/image?w=384&q=75&url=/images/rewards/closedbeta/".concat(rewardID.toString()).concat(".png"),
				url: "https://chainmonsters.com/inventory/".concat(id.toString())
			))
		}
		results["ChainmonstersRewards"] = MetadataCollection(type: Type<@ChainmonstersRewards.Collection>().identifier, items: items)
	}


	if results.keys.length == 0 {
		return nil
	}
	return results
}
