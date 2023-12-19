import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from 0x1d7e57aa55817448

//are in alchemy
import Mynft from 0xf6fcbef550d97aa5
import GooberXContract from 0x34f2bf4a80bb0f69
import RareRooms_NFT from 0x329feb3ab062d289
import CNN_NFT from 0x329feb3ab062d289
import Canes_Vault_NFT from 0x329feb3ab062d289
import DGD_NFT from 0x329feb3ab062d289
import RaceDay_NFT from 0x329feb3ab062d289
import The_Next_Cartel_NFT from 0x329feb3ab062d289
import MatrixWorldFlowFestNFT from 0x2d2750f240198f91
import GeniaceNFT from 0xabda6627c70c7f52
import OneFootballCollectible from 0x6831760534292098
import GoatedGoats from 0x2068315349bdfce5
import GoatedGoatsTrait from 0x2068315349bdfce5
import HaikuNFT from 0xf61e40c19db2a9e2
import KlktnNFT from 0xabd6e80be7e9682c
import BarterYardPackNFT from 0xa95b021cf8a30d80
import Evolution from 0xf4264ac8f3256818
import UFC_NFT from 0x329feb3ab062d289
import Moments from 0xd4ad4740ee426334
import CryptoPiggo from 0xd3df824bf81910a4
import Momentables from 0x9d21537544d9123d
import ZeedzINO from 0x62b3063fbe672fc8
import PartyMansionDrinksContract from 0x34f2bf4a80bb0f69
import DayNFT from 0x1600b04bf033fb99
import RaribleNFT from 0x01ab36aaf654a13e
import SomePlaceCollectible from 0x667a16294a089ef8
import SturdyItems from 0x427ceada271aa0b1

//we have better url
import MotoGPCard from 0xa49cc0ee46c54bfb

//we have sent pr
import Gaia from 0x8b148183c28ff88f

import FIND from "../contracts/FIND.cdc"

//They are lacking this one
import MatrixWorldAssetsNFT from 0xf20df769e658c257

//Will have Views!
import NeoAvatar from 0xb25138dbf45e5801
import NeoVoucher from 0xb25138dbf45e5801
import NeoMember from 0xb25138dbf45e5801
import NeoViews from 0xb25138dbf45e5801
import Art from 0xd796ff17107bbff6
import Marketplace from 0xd796ff17107bbff6
import Flovatar from 0x921ea449dffec68a
import FlovatarMarketplace from  0x921ea449dffec68a
import CharityNFT from "../contracts/CharityNFT.cdc"
import GoatedGoatsVouchers from 0xdfc74d9d561374c0
import TraitPacksVouchers from 0xdfc74d9d561374c0
import GoatedGoatsTraitPack from 0x2068315349bdfce5
import BarterYardClubWerewolf from  0x28abb9f291cadaf2
import Necryptolis from 0x718efe5e88fe48ea
import FLOAT from 0x2d4c3caffbeab845
import Bl0x from 0x7620acf6d7f2468a
import Bl0xPack from 0x7620acf6d7f2468a

//Jambb, not called Jambb Vouchers
import Vouchers from 0x444f5ea22c6ea12c

//xtingles
//urls is wrong in alchemy to media
import Collectible from 0xf5b0eb433389ac3f

//They do not have external url correct
import MintStoreItem from 0x20187093790b9aef




access(all) struct MetadataCollectionItem {
	access(all) let id:UInt64
	access(all) let name: String
	access(all) let image: String
	access(all) let url: String
	access(all) let listPrice: UFix64?
	access(all) let listToken: String?
	access(all) let contentType:String
	access(all) let rarity:String


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

//TODO:missing some from mainnet

// Same method signature as getNFTs.cdc for backwards-compatability.
access(all) getNFTs(ownerAddress: Address, ids: {String:[UInt64]}): [MetadataCollectionItem] {
	let NFTs: [MetadataCollectionItem] = []
	let owner = getAccount(ownerAddress)
	if owner.balance == 0.0 {
		return []
	}

	for key in ids.keys {
		for id in ids[key]! {
			var d: MetadataCollectionItem? = nil


			switch key {
				case "CNN": d  = getCNN(owner:owner, id:id) 
				case "Mynft": d  = getMynft(owner:owner, id:id)
				case "Flovatar": d = getFlovatar(owner:owner, id:id)
				case "FlovatarForSale": d = getFlovatarSale(owner:owner, id:id)
				case "VersusForSale": d = getVersusSale(owner:owner, id:id)
				case "Versus": d = getVersus(owner:owner, id:id)
				case "Gooberz": d  = getGoober(owner:owner, id:id) 
				case "PartyMansionDrinksContract": d  = getPartyBeers(owner:owner, id:id) 
				case "RareRooms": d  = getRareRooms(owner:owner, id:id) 
				case "Canes_Vault_NFT": d  = getCanesVault(owner:owner, id:id)
				case "DGD_NFT": d  = getDGD(owner:owner, id:id) 
				case "RaceDay_NFT": d  = getRaceDay(owner:owner, id:id) 
				case "The_Next_Cartel_NFT": d  = getTheNextCartel(owner:owner, id:id)
				case "UFC": d  = getUFC(owner:owner, id:id)
				case "MotoGPCard": d  = getMotoGP(owner:owner, id:id)
				case "Gaia": d  = getGaia(owner:owner, id:id) 
				case "Jambb": d  = getJambb(owner:owner, id:id) 
				case "JambbVoucher": d  = getJambbVoucher(owner:owner, id:id) 
				case "MatrixWorldAssetsNFT": d  = getMatrixWorldAssets(owner:owner, id:id) 
				case "MatrixWorldFlowFest": d  = getMatrixWorldFlowFest(owner:owner, id:id) 
				case "SturdyItems": d  = getSturdyItems(owner:owner, id:id) 
				case "FindCharity": d  = getFindCharity(owner:owner, id:id)
				case "Evolution": d  = getEvolution(owner:owner, id:id) 
				case "GeniaceNFT": d  = getGeniace(owner:owner, id:id) 
				case "OneFootballCollectible": d  = getOneFootballCollectible(owner:owner, id:id) 
				case "CryptoPiggo": d  = getCryptoPiggoes(owner:owner, id:id) 
				case "Xtingles": d  = getXtingles(owner:owner, id:id) 
				case "GoatedGoatsVoucher": d  = getGGVouhcer(owner:owner, id:id)
				case "GoatedGoatsTraitVoucher": d  = getGGTraitVoucher(owner:owner, id:id) 
				case "GoatedGoats": d  = getGG(owner:owner, id:id) 
				case "GoatedGoatsTrait": d  = getGGT(owner:owner, id:id) 
				case "GoatedGoatsTraitPack": d  = getGGTP(owner:owner, id:id) 
				case "Bitku": d  = getBitku(owner:owner, id:id) 
				case "KLKTN": d  = getKLKNT(owner:owner, id:id)
				case "NeoAvatar": d  = getNeoA(owner:owner, id:id)
				case "NeoVoucher": d  = getNeoV(owner:owner, id:id)
				case "NeoMember": d  = getNeoM(owner:owner, id:id) 
				case "BarterYardClubPack": d  = getBYCP(owner:owner, id:id) 
				case "BarterYardClubWerewolf": d  = getBYCW(owner:owner, id:id) 
				case "Momentables": d  = getMomentables(owner:owner, id:id) 
				case "ZeedsINO": d = getZeeds(owner:owner, id:id)
				case "DayNFT" : d = getDayNFT(owner:owner, id:id)
				case "Necryptolis" : d = getNecryptolis(owner:owner, id:id)
				case "FlowverseSocks" : d = getFlowverseSocks(owner:owner, id:id)
				case "FLOAT" : d = getFloat(owner:owner, id:id)
				case "MintStore" : d = getMintStore(owner:owner, id:id)
				case "SomePlace" : d = getSomePlace(owner:owner, id:id)
				case "Bl0x" : d = getBl0x(owner: owner, id: id)
				case "Bl0xPack" : d = getBl0xPack(owner: owner, id: id)

			default:
				panic("adapter for NFT not found: ".concat(key))
			}

			if d!= nil {
				NFTs.append(d!)
			}
		}
	}

	return NFTs
}

access(all)	getFlovatar(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {

	let flovatarCap = owner.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)  
	if !flovatarCap.check(){
		return nil
	}

	let flovatars=flovatarCap.borrow()!
	let flovatar = flovatars.borrowFlovatar(id: id)!

	let metadata=flovatar.getMetadata()
	var name = flovatar.getName()
	if name == "" {
		name="Flovatar #".concat(flovatar.id.toString())
	}

	var rarity="common"
	if metadata.legendaryCount > 0 {
		rarity="legendary"
	} else if metadata.epicCount > 0 {
		rarity="epic"
	} else if metadata.rareCount > 0 {
		rarity="rare"
	}


	return MetadataCollectionItem(
		id: flovatar.id, 
		name: name, 
		image: "https://flovatar.com/api/image/".concat(flovatar.id.toString()),
		url: "https://flovatar.com/flovatars/".concat(flovatar.id.toString()).concat("/"),
		listPrice:nil,
		listToken:nil,
		contentType: "image",
		rarity: rarity
	)
}

access(all)	getFlovatarSale(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let flovatarMarketCap = owner.getCapability<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath)  
	if !flovatarMarketCap.check(){
		return nil
	}

	let saleCollection=flovatarMarketCap.borrow()!
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

	let price = saleCollection.getFlovatarPrice(tokenId: id)



	return MetadataCollectionItem(
		id: flovatar.id, 
		name: name, 
		image: "https://flovatar.com/api/image/".concat(flovatar.id.toString()),
		url: "https://flovatar.com/flovatars/".concat(flovatar.id.toString()).concat("/"),
		listPrice: price,
		listToken: "Flow",
		contentType: "image",
		rarity: rarity
	)
}

access(all)	getVersusSale(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {

	let versusImageUrlPrefix = "https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_600/f_auto/maincache"
	let versusMarketplace = owner.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
	if !versusMarketplace.check() {
		return nil
	}

	let versusMarket = versusMarketplace.borrow()!
	let saleItem =versusMarket.getSaleItem(tokenID: id)
	return  MetadataCollectionItem(
		id: saleItem.id,
		name: saleItem.art.name.concat(" edition ").concat(saleItem.art.edition.toString()).concat("/").concat(saleItem.art.maxEdition.toString()).concat(" by ").concat(saleItem.art.artist),
		image: versusImageUrlPrefix.concat(saleItem.cacheKey), 
		url: "https://www.versus.auction/listing/".concat(saleItem.id.toString()).concat("/"),
		listPrice: saleItem.price,
		listToken: "Flow",
		contentType: "image",
		rarity: ""
	)
}

access(all)	getVersus(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let versusArtCap=owner.getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
	let versusImageUrlPrefix = "https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_600/f_auto/maincache"
	if !versusArtCap.check(){
		return nil
	}
	let address=owner.address!

	let artCollection= versusArtCap.borrow()!
	var art=artCollection.borrowArt(id: id)!
	return MetadataCollectionItem(
		id: id,
		name: art.metadata.name.concat(" edition ").concat(art.metadata.edition.toString()).concat("/").concat(art.metadata.maxEdition.toString()).concat(" by ").concat(art.metadata.artist),  
		image: versusImageUrlPrefix.concat(art.cacheKey()), 
		url: "https://www.versus.auction/piece/".concat(address.toString()).concat("/").concat(art.id.toString()).concat("/"),
		listPrice:nil,
		listToken:nil,
		contentType: "image",
		rarity: ""
	)
}

access(all)	getGoober(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {

	let goobersCap = owner.getCapability<&GooberXContract.Collection{NonFungibleToken.Collection, GooberXContract.GooberCollectionPublic}>(GooberXContract.CollectionPublicPath)
	if !goobersCap.check() {
		return nil
	}

	let goobers = goobersCap.borrow()!
	let goober= goobers.borrowGoober(id:id)!
	return MetadataCollectionItem(
		id: id,
		name: "Goober #".concat(id.toString()),
		image: goober.data.uri,
		url: "https://partymansion.io/gooberz/".concat(id.toString()),
		listPrice:nil,
		listToken:nil,
		contentType: "image",
		rarity: ""
	)
} 

access(all)	getPartyBeers(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {

	let partyMansionDrinksCap = owner.getCapability<&{PartyMansionDrinksContract.DrinkCollectionPublic}>(PartyMansionDrinksContract.CollectionPublicPath)
	if !partyMansionDrinksCap.check() {
		return nil
	}

	let collection = partyMansionDrinksCap.borrow()!
	let nft = collection.borrowDrink(id: id)!
	return MetadataCollectionItem(
		id: id,
		name: nft.data.description,
		image: "ipfs://".concat(nft.imageCID()),
		url: "https://partymansion.io",
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: PartyMansionDrinksContract.rarityToString(rarity:nft.data.rarity)
	)
} 

access(all)	getRareRooms(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let rareRoomCap = owner.getCapability<&RareRooms_NFT.Collection{RareRooms_NFT.RareRooms_NFTCollectionPublic}>(RareRooms_NFT.CollectionPublicPath)
	if !rareRoomCap.check() {
		return nil
	}
	let collection = rareRoomCap.borrow()!
	let nft = collection.borrowRareRooms_NFT(id: id)!
	let metadata = RareRooms_NFT.getSetMetadata(setId: nft.setId)!
	return MetadataCollectionItem(
		id: id,
		name: metadata["name"]!,
		image: metadata["preview"]!,
		url: "https://rarerooms.io/tokens/".concat(id.toString()),
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: ""
	)


} 
access(all)	getCNN(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let cnnCap = owner.getCapability<&CNN_NFT.Collection{CNN_NFT.CNN_NFTCollectionPublic}>(CNN_NFT.CollectionPublicPath)
	if !cnnCap.check() {
		return nil

	}
	let collection = cnnCap.borrow()!
	let nft = collection.borrowCNN_NFT(id: id)!
	let metadata = CNN_NFT.getSetMetadata(setId: nft.setId)!

	var image= metadata["preview"]!
	var contentType="image"

	return MetadataCollectionItem(
		id: id,
		name: metadata["name"]!,
		image: image,
		url: "http://vault.cnn.com",
		listPrice: nil,
		listToken: nil,
		contentType: contentType,
		rarity: ""
	)
} 

access(all)	getCanesVault(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let canesVaultCap = owner.getCapability<&Canes_Vault_NFT.Collection{Canes_Vault_NFT.Canes_Vault_NFTCollectionPublic}>(Canes_Vault_NFT.CollectionPublicPath)
	if !canesVaultCap.check() {
		return nil
	}
	let collection = canesVaultCap.borrow()!
	let nft = collection.borrowCanes_Vault_NFT(id: id)!
	let metadata = Canes_Vault_NFT.getSetMetadata(setId: nft.setId)!
	var image= metadata["preview"]!
	var contentType="image"
	return MetadataCollectionItem(
		id: id,
		name: metadata["name"]!,
		image: image,
		url: "https://canesvault.com/",
		listPrice: nil,
		listToken: nil,
		contentType: contentType,
		rarity: ""
	)
}

access(all)	getDGD(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let dgdCap = owner.getCapability<&DGD_NFT.Collection{DGD_NFT.DGD_NFTCollectionPublic}>(DGD_NFT.CollectionPublicPath)
	if !dgdCap.check() {
		return nil
	}
	let collection = dgdCap.borrow()!
	let nft = collection.borrowDGD_NFT(id: id)!
	let metadata = DGD_NFT.getSetMetadata(setId: nft.setId)!
	var image= metadata["preview"]!
	var contentType="image"

	return MetadataCollectionItem(
		id: id,
		name: metadata["name"]!,
		image: image,
		url: "https://www.theplayerslounge.io/",
		listPrice: nil,
		listToken: nil,
		contentType: contentType,
		rarity: ""
	)
} 

access(all)	getRaceDay(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let raceDayCap = owner.getCapability<&RaceDay_NFT.Collection{RaceDay_NFT.RaceDay_NFTCollectionPublic}>(RaceDay_NFT.CollectionPublicPath)
	if !raceDayCap.check() {
		return nil
	}
	let collection = raceDayCap.borrow()!
	let nft = collection.borrowRaceDay_NFT(id: id)!
	let metadata = RaceDay_NFT.getSetMetadata(setId: nft.setId)!
	var image= metadata["preview"]!
	var contentType="image"

	return MetadataCollectionItem(
		id: id,
		name: metadata["name"]!,
		image: image, 
		url: "https://www.racedaynft.com",
		listPrice: nil,
		listToken: nil,
		contentType: contentType,
		rarity: ""
	)
} 

access(all)	getTheNextCartel(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let nextCartelCap = owner.getCapability<&The_Next_Cartel_NFT.Collection{The_Next_Cartel_NFT.The_Next_Cartel_NFTCollectionPublic}>(The_Next_Cartel_NFT.CollectionPublicPath)
	if !nextCartelCap.check() {
		return nil
	}
	let collection = nextCartelCap.borrow()!
	let nft = collection.borrowThe_Next_Cartel_NFT(id: id)!
	let metadata = The_Next_Cartel_NFT.getSetMetadata(setId: nft.setId)!
	var image= metadata["preview"]!
	var contentType="image"
	return MetadataCollectionItem(
		id: id,
		name: metadata["name"]!,
		// we use "preview" and not "image" because of potential .glg and .mp4 file types
		image: image,
		url: "https://thenextcartel.com/",
		listPrice: nil,
		listToken: nil,
		contentType: contentType,
		rarity: ""
	)
}

access(all)	getUFC(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let ufcCap = owner.getCapability<&UFC_NFT.Collection{UFC_NFT.UFC_NFTCollectionPublic}>(UFC_NFT.CollectionPublicPath)
	if !ufcCap.check() {
		return nil
	}

	let collection = ufcCap.borrow()!
	let nft = collection.borrowUFC_NFT(id: id)!
	let metadata = UFC_NFT.getSetMetadata(setId: nft.setId)!
	var image= metadata["image"]!
	var contentType="video"
	return MetadataCollectionItem(
		id: id,
		name: metadata["name"]!,
		image: image,
		url: "https://www.ufcstrike.com",
		listPrice: nil,
		listToken: nil,
		contentType: contentType,
		rarity: ""
	)


}
access(all)	getMotoGP(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let motoGPCollection = owner.getCapability<&MotoGPCard.Collection{MotoGPCard.ICardCollectionPublic}>(/public/motogpCardCollection)
	if !motoGPCollection.check() {
		return nil
	}
	let address=owner.address!
	let motoGPNfts = motoGPCollection.borrow()!.getIDs()
	let nft = motoGPCollection.borrow()!.borrowCard(id: id)!
	let metadata = nft.getCardMetadata()!
	return MetadataCollectionItem(
		id: id,
		name: metadata.name,
		image: metadata.imageUrl,
		url: "https://motogp-ignition.com/nft/card/".concat(id.toString()).concat("?owner=").concat(address.toString()),
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: ""
	)
}
access(all)	getGaia(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let gaiaCollection = owner.getCapability<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath)
	if !gaiaCollection.check() {
		return nil
	}

	let gaiaNfts = gaiaCollection.borrow()!.getIDs()
	let nft = gaiaCollection.borrow()!.borrowGaiaNFT(id: id)!
	let metadata = Gaia.getTemplateMetaData(templateID: nft.data.templateID)!

	//For ballerz we can do this...
	var url="http://ongaia.com/"
	var name=metadata["title"]!

	if let seriesFullName=metadata["series"] {
		if seriesFullName=="Bryson DeChambeau - Vegas, Baby!" {
			//For golf there is yet another way
			url="http://ongaia.com/bryson/".concat(nft.data.mintNumber.toString())
			name=metadata["title"]!.concat(" #").concat(nft.data.mintNumber.toString())
		} else {
			//If the series is basketball with shareef we can do this
			url="http://ongaia.com/shareef/nft/".concat(id.toString())
			name=metadata["title"]!.concat(" #").concat(nft.data.mintNumber.toString())
		}
	}

	let newCollections= ["ballerz", "sneakerz"]
	if let mid = metadata["id"] {
		if let uri = metadata["uri"] {
			for c in newCollections {
				if uri == "/collection/".concat(c).concat("//").concat(mid) {
				url="http://ongaia.com/".concat(c).concat("/").concat(mid)
			}
		}
	}
}


return MetadataCollectionItem(
	id: id,
	name: name,
	image: metadata["img"]!,
	url: url,
	listPrice: nil,
	listToken: nil,
	contentType: "image",
	rarity: ""
)
} 

access(all)	getJambb(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let jambbCap = owner.getCapability<&Moments.Collection{Moments.CollectionPublic}>(Moments.CollectionPublicPath)
	if !jambbCap.check() {
		return nil
	}
	let jambb = jambbCap.borrow()!
	let nft = jambb.borrowMoment(id: id)!
	let metadata=nft.getMetadata()
	return MetadataCollectionItem(
		id: id,
		name: metadata.contentName,
		image: "ipfs://".concat(metadata.videoHash),
		url: "https://www.jambb.com/c/moment/".concat(id.toString()),
		listPrice: nil,
		listToken: nil,
		contentType: "video",
		rarity: ""
	)
} 

access(all)	getJambbVoucher(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let voucherCap = owner.getCapability<&{Vouchers.CollectionPublic}>(Vouchers.CollectionPublicPath)
	if !voucherCap.check() {
		return nil
	}
	let collection = voucherCap.borrow()!
	let nft = collection.borrowVoucher(id: id)!
	let metadata=nft.getMetadata()!

	let url="https://jambb.com"
	return  MetadataCollectionItem(
		id: id,
		name: metadata.name,
		image: "ipfs://".concat(metadata.mediaHash),
		url: url,
		listPrice: nil,
		listToken: nil,
		contentType: metadata.mediaType,
		rarity: ""
	)
} 

access(all)	getMatrixWorldFlowFest(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let mwaCap = owner.getCapability<&{MatrixWorldFlowFestNFT.MatrixWorldFlowFestNFTCollectionPublic}>(MatrixWorldFlowFestNFT.CollectionPublicPath)
	if !mwaCap.check() {
		return nil
	}

	let mwa=mwaCap.borrow()!
	let nft = mwa.borrowVoucher(id: id)!
	let metadata=nft.metadata
	return MetadataCollectionItem(
		id: nft.id,
		name: metadata.name,
		image: metadata.animationUrl,
		url: "https://matrixworld.org/",
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: ""
	)
} 

access(all)	getMatrixWorldAssets(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {

	let matrixworldAsset = owner.getCapability<&{MatrixWorldAssetsNFT.Metadata, NonFungibleToken.Collection}>(MatrixWorldAssetsNFT.collectionPublicPath)
	if !matrixworldAsset.check() {
		return nil
	}
	let collection = matrixworldAsset.borrow()!
	let metadata = collection.getMetadata(id: id)!
	return  MetadataCollectionItem(
		id: id,
		name: metadata["name"]!,
		image: metadata["image"]!,
		url: metadata["external_url"]!,
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: ""
	)
} 

access(all)	getSturdyItems(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {

	let sturdyCollectionCap = owner.getCapability<&SturdyItems.Collection{SturdyItems.SturdyItemsCollectionPublic}>(SturdyItems.CollectionPublicPath)
	if !sturdyCollectionCap.check() {
		return nil
	}
	let sturdyNfts = sturdyCollectionCap.borrow()!.getIDs()
	let nft = sturdyCollectionCap.borrow()!.borrowSturdyItem(id: id)!
	// the only thing we can play with is the nft title which is for example:
	// 	- "HOODLUM#10"
	// 	- "HOLIDAY MYSTERY BADGE 2021"
	//  - "EXCALIBUR"
	let isHoodlum = nft.tokenTitle.slice(from: 0, upTo: 7) == "HOODLUM"
	if !isHoodlum {
		return nil
	}
	// the hoodlum id is needed to retrieve the image but is not in the nft
	let hoodlumId = nft.tokenTitle.slice(from: 8, upTo: nft.tokenTitle.length)
	return  MetadataCollectionItem(
		id: id,
		name: nft.tokenTitle,
		image: "https://hoodlumsnft.com/_next/image?url=%2Fthumbs%2FsomeHoodlum_".concat(hoodlumId).concat(".png&w=1920&q=75"),
		url: "https://hoodlumsnft.com/",
		listPrice:nil,
		listToken:nil,
		contentType:"image",
		rarity: ""
	)
} 

access(all)	getFindCharity(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let charityCap = owner.getCapability<&{CharityNFT.CollectionPublic}>(/public/findCharityNFTCollection)
	if !charityCap.check() {
		return nil
	}
	let collection = charityCap.borrow()!
	let nft = collection.borrowCharity(id: id)!
	let metadata = nft.getMetadata()
	return MetadataCollectionItem(
		id: id,
		name: metadata["name"]!,
		image: metadata["thumbnail"]!,
		url: metadata["originUrl"]!,
		listPrice: nil,
		listToken: nil,
		contentType:"image",
		rarity: ""
	)
}

access(all)	getEvolution(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let evolutionCap=owner.getCapability<&{Evolution.EvolutionCollectionPublic}>(/public/f4264ac8f3256818_Evolution_Collection)
	if !evolutionCap.check() {
		return nil
	}
	let evolution=evolutionCap.borrow()!
	let nfts = evolution.getIDs()
	// the metadata is a JSON stored on IPFS at the address nft.tokenURI
	let nft = evolution.borrowCollectible(id: id)!
	let metadata = Evolution.getItemMetadata(itemId: nft.data.itemId)!
	return MetadataCollectionItem(
		id: id,
		name: metadata["Title"]!.concat(" #").concat(nft.data.serialNumber.toString()),
		image: "https://storage.viv3.com/0xf4264ac8f3256818/mv/".concat(nft.data.itemId.toString()),
		url: "https://www.evolution-collect.com/",
		listPrice: nil,
		listToken: nil,
		contentType:"video",
		rarity: ""
	)
}

access(all)	getGeniace(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let geniaceCap = owner.getCapability<&GeniaceNFT.Collection{NonFungibleToken.Collection, GeniaceNFT.GeniaceNFTCollectionPublic}>(GeniaceNFT.CollectionPublicPath)
	if !geniaceCap.check() {
		return nil
	}

	let geniace=geniaceCap.borrow()!
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

	return MetadataCollectionItem(
		id: id,
		name: metadata.name,
		image: metadata.imageUrl,
		url: "https://www.geniace.com/product/".concat(id.toString()),
		listPrice: nil,
		listToken: nil,
		contentType: metadata.data["mimetype"]!,
		rarity: rarity,
	)
} 

access(all)	getOneFootballCollectible(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let address=owner.address!
	let oneFootballCollectibleCap = owner.getCapability<&OneFootballCollectible.Collection{OneFootballCollectible.OneFootballCollectibleCollectionPublic}>(OneFootballCollectible.CollectionPublicPath)
	if !oneFootballCollectibleCap.check() {
		return nil
	}
	let collection = oneFootballCollectibleCap.borrow()!
	let nft = collection.borrowOneFootballCollectible(id: id)!
	let metadata = nft.getTemplate()!
	return MetadataCollectionItem(
		id: id,
		name: metadata.name,
		image: "ipfs://".concat(metadata.media),
		url: "https://xmas.onefootball.com/".concat(owner.address.toString()),
		listPrice: nil,
		listToken: nil,
		contentType: "video",
		rarity: ""

	)
} 

access(all)	getCryptoPiggoes(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let cryptoPiggoCap = owner.getCapability<&{CryptoPiggo.CryptoPiggoCollectionPublic}>(CryptoPiggo.CollectionPublicPath)
	if !cryptoPiggoCap.check() {
		return nil
	}
	let collection = cryptoPiggoCap.borrow()!
	let nft = collection.borrowItem(id: id)!
	return MetadataCollectionItem(
		id: id,
		name: "CryptoPiggo #".concat(id.toString()),
		image: "https://s3.us-west-2.amazonaws.com/crypto-piggo.nft/piggo-".concat(id.toString()).concat(".png"),
		url: "https://rareworx.com/piggo/details/".concat(id.toString()),
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: ""
	)
} 

access(all)	getXtingles(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let xtinglesCap= owner.getCapability<&{Collectible.CollectionPublic}>(Collectible.CollectionPublicPath)
	if !xtinglesCap.check() {
		return nil
	}
	let collection = xtinglesCap.borrow()!

	let nft=collection.borrowCollectible(id:id)!
	var image=nft.metadata.link

	let prefix="https://"
	if image.slice(from:0, upTo:prefix.length) != prefix {
		image="ipfs://".concat(image)
	}
	return MetadataCollectionItem(
		id: nft.id,
		name: nft.metadata.name.concat(" #").concat(nft.metadata.edition.toString()),
		image: image,
		url: "http://xtingles.com",
		listPrice: nil,
		listToken: nil,
		contentType: "video",
		rarity: ""
	)
} 

access(all)	getGGVouhcer(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let goatsCap = owner.getCapability<&{GoatedGoatsVouchers.GoatsVoucherCollectionPublic}>(GoatedGoatsVouchers.CollectionPublicPath)
	if !goatsCap.check() {
		return nil
	}
	let goatsImageUrl= GoatedGoatsVouchers.getCollectionMetadata()["mediaURL"]!
	let collection = goatsCap.borrow()!
	return MetadataCollectionItem(
		id: id,
		name: "Goated Goat Base Goat Voucher #".concat(id.toString()),
		image: goatsImageUrl, 
		url: "https://goatedgoats.com/",
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: ""

	)
}
access(all)	getGGTraitVoucher(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let goatsTraitCap = owner.getCapability<&{TraitPacksVouchers.PackVoucherCollectionPublic}>(TraitPacksVouchers.CollectionPublicPath)
	if !goatsTraitCap.check() {
		return nil
	}
	let goatsImageUrl= TraitPacksVouchers.getCollectionMetadata()["mediaURL"]!
	let collection = goatsTraitCap.borrow()!
	return MetadataCollectionItem(
		id: id,
		name: "Goated Goat Trait Pack Voucher #".concat(id.toString()),
		image: goatsImageUrl, 
		url: "https://goatedgoats.com/",
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: ""

	)

} 

access(all)	getGG(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	return getItemForMetadataStandard(path: GoatedGoats.CollectionPublicPath, owner: owner, externalFixedUrl: "https://goatedgoats.com", id:id)
} 

access(all)	getGGT(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	return getItemForMetadataStandard(path: GoatedGoatsTrait.CollectionPublicPath, owner: owner, externalFixedUrl: "https://goatedgoats.com", id:id)
} 

access(all)	getGGTP(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	return  getItemForMetadataStandard(path: GoatedGoatsTraitPack.CollectionPublicPath, owner: owner, externalFixedUrl: "https://goatedgoats.com", id:id)
} 

access(all)	getBitku(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {

	let address=owner.address!
	let bitkuCap = owner.getCapability<&{HaikuNFT.HaikuCollectionPublic}>(HaikuNFT.HaikuCollectionPublicPath)
	if !bitkuCap.check() {
		return nil
	}
	let collection = bitkuCap.borrow()!
	let nft = collection.borrowHaiku(id: id)!
	return MetadataCollectionItem(
		id: id,
		name: "Bitku #".concat(id.toString()),
		image: nft.text,
		url: "https://bitku.art/#".concat(address.toString()).concat("/").concat(id.toString()),
		listPrice: nil,
		listToken: nil,
		contentType: "text",
		rarity: ""
	)
} 

access(all)	getKLKNT(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let klktnCap = owner.getCapability<&{KlktnNFT.KlktnNFTCollectionPublic}>(KlktnNFT.CollectionPublicPath)
	if !klktnCap.check() {
		return nil
	}
	let collection = klktnCap.borrow()!
	let nft = collection.borrowKlktnNFT(id: id)!

	let metadata=nft.getNFTMetadata()
	/*
	Result: {"uri": "ipfs://bafybeifsiousmtmcruuelgyiku3xa5hmw7ylsyqfdvpjsea7r4xa74bhym", "name": "Kevin Woo - What is KLKTN?", "mimeType": "video/mp4", "media": "https://ipfs.io/ipfs/bafybeifsiousmtmcruuelgyiku3xa5hmw7ylsyqfdvpjsea7r4xa74bhym/fb91ad34d61dde04f02ad240f0ca924902d8b4a3da25daaf0bb1ed769977848c.mp4", "description": "K-pop sensation Kevin Woo has partnered up with KLKTN to enhance his artist to fan interactions and experiences within his fandom. Join our chat to learn more: https://discord.gg/UJxb4erfUw"}

	*/
	return MetadataCollectionItem(
		id: id,
		name: metadata["name"]!,
		image: metadata["media"]!,
		url: "https://klktn.com/",
		listPrice: nil,
		listToken: nil,
		contentType: "video", //metadata["mimeType"]!,
		rarity: ""
	)
}

access(all)	getMynft(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let mynftCap = owner.getCapability<&{Mynft.MynftCollectionPublic}>(Mynft.CollectionPublicPath)
	if !mynftCap.check() {
		return nil
	}
	let collection = mynftCap.borrow()!
	let nft = collection.borrowArt(id: id)!
	let metadata=nft.metadata

	var image= metadata.ipfsLink
	if image == "" {
		image="https://arweave.net/".concat(metadata.arLink)
	}

	return MetadataCollectionItem(
		id: id,
		name: metadata.name,
		image: image,
		url: "http://mynft.io",
		listPrice: nil,
		listToken: nil,
		contentType: metadata.type,
		rarity: ""
	)
}

access(all)	getNeoA(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	return getItemForMetadataStandard(path: NeoAvatar.CollectionPublicPath, owner: owner, externalFixedUrl: "https://neocollectibles.xyz", id:id)
}
access(all)	getNeoV(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let address=owner.address!
	return getItemForMetadataStandard(path: NeoVoucher.CollectionPublicPath, owner: owner, externalFixedUrl: "https://neocollectibles.xyz/member/".concat(address.toString()), id:id)
}

access(all)	getNeoM(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let address=owner.address!
	return getItemForMetadataStandard(path: NeoMember.CollectionPublicPath, owner: owner, externalFixedUrl: "https://neocollectibles.xyz/member/".concat(address.toString()), id:id)
} 

access(all)	getBYCP(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let barterYardCap= owner.getCapability<&{BarterYardPackNFT.BarterYardPackNFTCollectionPublic}>(BarterYardPackNFT.CollectionPublicPath)
	if !barterYardCap.check() {
		return nil
	}
	let collection = barterYardCap.borrow()!
	let nft = collection.borrowBarterYardPackNFT(id: id)!

	if let displayView = nft.resolveView(Type<MetadataViews.Display>()) {
		let display = displayView as! MetadataViews.Display
		return MetadataCollectionItem(
			id: id,
			name: display.name,
			image: display.thumbnail.uri(),
			url: "https://www.barteryard.club",
			listPrice: nil,
			listToken: nil,
			contentType: "image",
			rarity: ""
		)
	}
	return nil
} 

access(all)	getBYCW(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	return getItemForMetadataStandard(path: BarterYardClubWerewolf.CollectionPublicPath, owner: owner, externalFixedUrl: "https://barteryard.club", id:id)
} 

access(all)	getMomentables(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let momentablesCap = owner.getCapability<&{Momentables.MomentablesCollectionPublic}>(Momentables.CollectionPublicPath)
	if !momentablesCap.check() {
		return nil
	}
	let collection = momentablesCap.borrow()!

	let nft = collection.borrowMomentables(id: id)!
	let traits=nft.getTraits()
	let commonTrait=traits["common"]!

	return MetadataCollectionItem(
		id: id,
		name: nft.name,
		image: "ipfs://".concat(nft.imageCID),
		url: "https://www.cryptopharaohs.world/",
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: commonTrait["type"] ?? "",
	)
} 

access(all)	getZeeds(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {

	let zeedzCap = owner.getCapability<&{ZeedzINO.ZeedzCollectionPublic}>(ZeedzINO.CollectionPublicPath)
	if !zeedzCap.check() {
		return nil
	}
	let collection = zeedzCap.borrow()!
	let nft = collection.borrowZeedle(id: id)!

	return MetadataCollectionItem(
		id: id,
		name: nft.name,
		image: "ipfs://".concat(nft.imageURI),
		url: "http://zeedz.io",
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: nft.rarity
	)
}


access(all)	getDayNFT(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	return getItemForMetadataStandard(path: DayNFT.CollectionPublicPath, owner: owner, externalFixedUrl: "https://day-nft.io", id:id)
} 

access(all)	getNecryptolis(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	return getItemForMetadataStandard(path: Necryptolis.ResolverCollectionPublicPath, owner: owner, externalFixedUrl: "https://www.necryptolis.com", id:id)
}

access(all)	getFlowverseSocks(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let raribleCap = owner.getCapability<&{NonFungibleToken.Collection}>(RaribleNFT.collectionPublicPath)
	if !raribleCap.check() {
		return nil
	}

	let sockIds : [UInt64] = [14813, 15013, 14946, 14808, 14899, 14792, 15016, 14961, 14816, 14796, 14992, 14977, 14815, 14863, 14817, 14814, 14875, 14960, 14985, 14850, 14849, 14966, 14826, 14972, 14795, 15021, 14950, 14847, 14970, 14833, 14786, 15010, 14953, 14799, 14883, 14947, 14844, 14801, 14886, 15015, 15023, 15027, 15029, 14802, 14810, 14948, 14955, 14957, 14988, 15007, 15009, 14837, 15024, 14803, 14973, 14969, 15002, 15017, 14797, 14894, 14881, 15025, 14791, 14979, 14789, 14993, 14873, 14939, 15005, 15006, 14869, 14889, 15004, 15008, 15026, 14990, 14998, 14898, 14819, 14840, 14974, 15019, 14856, 14838, 14787, 14876, 14996, 14798, 14855, 14824, 14843, 14959, 15020, 14862, 14822, 14897, 14830, 14790, 14867, 14878, 14991, 14835, 14818, 14892, 14800, 15000, 14857, 14986, 14805, 14812, 14962]

	if !sockIds.contains(id) {
		return nil
	}

	let collection = raribleCap.borrow()!
	collection.borrowNFT(id:id)!

	return MetadataCollectionItem(
		id: id,
		name: "Flowverse socks",
		image: "https://img.rarible.com/prod/video/upload/t_video_big/prod-itemAnimations/FLOW-A.01ab36aaf654a13e.RaribleNFT:15029/b1cedf3",
		url: "https://www.flowverse.co/socks",
		listPrice: nil,
		listToken: nil,
		contentType: "video",
		rarity: ""
	)
}

access(all)	getFloat(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let address=owner.address!
	return getItemForMetadataStandard(path: FLOAT.FLOATCollectionPublicPath, owner: owner, externalFixedUrl: "https://floats.city/".concat(address.toString()), id:id)
}

access(all)	getMintStore(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let mintStoreCap = owner.getCapability<&{MintStoreItem.MintStoreItemCollectionPublic}>(MintStoreItem.CollectionPublicPath)
	if !mintStoreCap.check() {
		return nil
	}
	let collection = mintStoreCap.borrow()!
	let nft = collection.borrowMintStoreItem(id: id)!
	let display= nft.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display

	let merchantName = MintStoreItem.getMerchant(merchantID:nft.data.merchantID)!
	let editionData = MintStoreItem.EditionData(editionID: nft.data.editionID)!
	var external_domain = ""
	switch merchantName {
	case "Bulls":
		external_domain =  "https://bulls.mint.store"
		break;
	case "Charlotte Hornets":
		external_domain =  "https://hornets.mint.store"
		break;
	default:
		external_domain =  ""
	}
	if editionData!.metadata["nftType"]! == "Type C" {
		external_domain =  "https://misa.art/collections/nft"
	}

	let name=editionData.name
	let image = editionData.metadata["thumbnail"] ?? ""
	return MetadataCollectionItem(
		id: id,
		name: name,
		image: image,
		url: external_domain,
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: ""
	)
}

access(all)	getSomePlace(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	let somePlaceCap =owner.getCapability<&{SomePlaceCollectible.CollectibleCollectionPublic}>(SomePlaceCollectible.CollectionPublicPath)
	if !somePlaceCap.check() {
		return nil
	}
	let collection = somePlaceCap.borrow()!
	let nft = collection.borrowCollectible(id: id)!
	let setID = nft.setID
	let setMetadata = SomePlaceCollectible.getMetadataForSetID(setID: setID)!
	let editionMetadata = SomePlaceCollectible.getMetadataForNFTByUUID(uuid: nft.id)!
	return MetadataCollectionItem(
		id: id,
		name: editionMetadata.getMetadata()["title"] ?? setMetadata.getMetadata()["title"] ?? "",
		image: editionMetadata.getMetadata()["mediaURL"] ?? setMetadata.getMetadata()["mediaURL"] ?? "",
		url: "https://some.place",
		listPrice: nil,
		listToken: nil,
		contentType: "image",
		rarity: ""
	)
}


access(all)	getBl0xPack(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	return getItemForMetadataStandard(path: Bl0xPack.CollectionPublicPath, owner: owner, externalFixedUrl: "http://bl0x.xyz", id:id)
}

access(all)	getBl0x(owner:PublicAccount, id:UInt64) : MetadataCollectionItem? {
	return getItemForMetadataStandard(path: Bl0x.CollectionPublicPath, owner: owner, externalFixedUrl: "http://bl0x.xyz", id:id)
}


//This uses a view from Neo until we agree on another for ExternalDomainViewUrl
access(all) getItemForMetadataStandard(path: PublicPath, owner:PublicAccount, externalFixedUrl: String, id:UInt64) : MetadataCollectionItem? {
	let resolverCollectionCap= owner.getCapability<&{ViewResolver.ResolverCollection}>(path)
	if !resolverCollectionCap.check() {
		return nil
	}
	let collection = resolverCollectionCap.borrow()!
	let nft = collection.borrowViewResolver(id: id)!

	if let displayView = nft.resolveView(Type<MetadataViews.Display>()) {
		let display = displayView as! MetadataViews.Display
		var externalUrl=externalFixedUrl
		if let externalUrlView = nft.resolveView(Type<MetadataViews.ExternalURL>()) {
			let url= externalUrlView! as! MetadataViews.ExternalURL
			externalUrl=url.url
		}

		return MetadataCollectionItem(
			id: id,
			name: display.name,
			image: display.thumbnail.uri(),
			url: externalUrl,
			listPrice: nil,
			listToken: nil,
			contentType: "image",
			rarity: ""
		)
	}
	return nil
}

/*
access(all) main(user: String) : {String: [UInt64]} {
	let resolvingAddress = FIND.resolve(user)
	if resolvingAddress == nil {
		return {}
	}
	let address = resolvingAddress!

	return getNFTIDs(ownerAddress: address)
}
*/


access(all) main(address: Address, ids: {String:[UInt64]}): [MetadataCollectionItem] {

	return getNFTs(ownerAddress:address, ids:ids)
}
