import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import GooberXContract from 0x34f2bf4a80bb0f69

import SturdyItems from 0x427ceada271aa0b1
import UFC_NFT from 0x329feb3ab062d289

import Gaia from 0x8b148183c28ff88f

import MatrixWorldFlowFestNFT from 0x2d2750f240198f91
import DGD_NFT from 0x329feb3ab062d289
import The_Next_Cartel_NFT from 0x329feb3ab062d289
import OneFootballCollectible from 0x6831760534292098
import MatrixWorldAssetsNFT from 0xf20df769e658c257
import Necryptolis from 0x718efe5e88fe48ea
import RareRooms_NFT from 0x329feb3ab062d289
import CNN_NFT from 0x329feb3ab062d289
import Evolution from 0xf4264ac8f3256818
import MintStoreItem from 0x20187093790b9aef
import MotoGPCard from 0xa49cc0ee46c54bfb
import SomePlaceCollectible from 0x667a16294a089ef8
import Canes_Vault_NFT from 0x329feb3ab062d289
import RaceDay_NFT from 0x329feb3ab062d289
import GeniaceNFT from 0xabda6627c70c7f52
import GoatedGoats from 0x2068315349bdfce5
import HaikuNFT from 0xf61e40c19db2a9e2
import KlktnNFT from 0xabd6e80be7e9682c
import Mynft from 0xf6fcbef550d97aa5
import BarterYardPackNFT from 0xa95b021cf8a30d80
import Moments from 0xd4ad4740ee426334
import CryptoPiggo from 0xd3df824bf81910a4
import GoatedGoatsVouchers from 0xdfc74d9d561374c0
import TraitPacksVouchers from 0xdfc74d9d561374c0
import GoatedGoatsTrait from 0x2068315349bdfce5
import GoatedGoatsTraitPack from 0x2068315349bdfce5
import Art from 0xd796ff17107bbff6
import Marketplace from 0xd796ff17107bbff6
import Flovatar from 0x921ea449dffec68a
import FlovatarMarketplace from  0x921ea449dffec68a
import CharityNFT from "../contracts/CharityNFT.cdc"
import FIND from "../contracts/FIND.cdc"


import NeoAvatar from 0xb25138dbf45e5801
import NeoVoucher from 0xb25138dbf45e5801
import NeoMember from 0xb25138dbf45e5801
import NeoViews from 0xb25138dbf45e5801
import MetadataViews from 0x1d7e57aa55817448
import BarterYardClubWerewolf from  0x28abb9f291cadaf2

//Jambb
import Vouchers from 0x444f5ea22c6ea12c

//xtingles
import Collectible from 0xf5b0eb433389ac3f

import Momentables from 0x9d21537544d9123d
import ZeedzINO from 0x62b3063fbe672fc8
import PartyMansionDrinksContract from 0x34f2bf4a80bb0f69

import DayNFT from 0x1600b04bf033fb99
import RaribleNFT from 0x01ab36aaf654a13e

import FLOAT from 0x2d4c3caffbeab845

import Bl0x from 0x7620acf6d7f2468a
import Bl0xPack from 0x7620acf6d7f2468a


pub fun getNFTIDs(ownerAddress: Address): {String: [UInt64]} {
	let account = getAccount(ownerAddress)
	if account.balance == 0.0 {
		return {}
	}
	let ids: {String: [UInt64]} = {}


	let flovatarCap = account.getCapability<&{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath)  
	if flovatarCap.check() {
		ids["Flovatar"]=flovatarCap.borrow()!.getIDs()
	}

	let flovatarMarketCap = account.getCapability<&{FlovatarMarketplace.SalePublic}>(FlovatarMarketplace.CollectionPublicPath)
	if flovatarMarketCap.check() {
		ids["FlovatarForSale"]=flovatarMarketCap.borrow()!.getFlovatarIDs()
	}

	let versusMarketplace = account.getCapability<&{Marketplace.SalePublic}>(Marketplace.CollectionPublicPath)
	if versusMarketplace.check() {
		ids["VersusForSale"]=versusMarketplace.borrow()!.getIDs()
	}

	let versusArtCap=account.getCapability<&{Art.CollectionPublic}>(Art.CollectionPublicPath)
	if versusArtCap.check() {
		ids["Versus"]=versusArtCap.borrow()!.getIDs()
	}

	let goobersCap = account.getCapability<&GooberXContract.Collection{NonFungibleToken.CollectionPublic, GooberXContract.GooberCollectionPublic}>(GooberXContract.CollectionPublicPath)
	if goobersCap.check() {
		ids["Gooberz"] = goobersCap.borrow()!.getIDs()
	}

	let partyMansionDrinksCap = account.getCapability<&{PartyMansionDrinksContract.DrinkCollectionPublic}>(PartyMansionDrinksContract.CollectionPublicPath)
	if partyMansionDrinksCap.check() {
		ids["PartyMansionDrinksContract"] = partyMansionDrinksCap.borrow()!.getIDs()
	}

	let rareRoomCap = account.getCapability<&RareRooms_NFT.Collection{RareRooms_NFT.RareRooms_NFTCollectionPublic}>(RareRooms_NFT.CollectionPublicPath)
	if rareRoomCap.check() {
		ids["RareRooms"] = rareRoomCap.borrow()!.getIDs()
	}

	let cnnCap = account.getCapability<&CNN_NFT.Collection{CNN_NFT.CNN_NFTCollectionPublic}>(CNN_NFT.CollectionPublicPath)
	if cnnCap.check() {
		ids["CNN"] = cnnCap.borrow()!.getIDs()
	}

	let canesVaultCap = account.getCapability<&Canes_Vault_NFT.Collection{Canes_Vault_NFT.Canes_Vault_NFTCollectionPublic}>(Canes_Vault_NFT.CollectionPublicPath)
	if canesVaultCap.check() {
		ids["Canes_Vault_NFT"] = canesVaultCap.borrow()!.getIDs()
	}
	let dgdCap = account.getCapability<&DGD_NFT.Collection{DGD_NFT.DGD_NFTCollectionPublic}>(DGD_NFT.CollectionPublicPath)
	if dgdCap.check() {
		ids["DGD_NFT"] = dgdCap.borrow()!.getIDs()
	}

	let raceDayCap = account.getCapability<&RaceDay_NFT.Collection{RaceDay_NFT.RaceDay_NFTCollectionPublic}>(RaceDay_NFT.CollectionPublicPath)
	if raceDayCap.check() {
		ids["RaceDay_NFT"] = raceDayCap.borrow()!.getIDs()
	}

	let nextCartelCap = account.getCapability<&The_Next_Cartel_NFT.Collection{The_Next_Cartel_NFT.The_Next_Cartel_NFTCollectionPublic}>(The_Next_Cartel_NFT.CollectionPublicPath)
	if nextCartelCap.check() {
		ids["The_Next_Cartel_NFT"] = nextCartelCap.borrow()!.getIDs()
	}
	let ufcCap = account.getCapability<&UFC_NFT.Collection{UFC_NFT.UFC_NFTCollectionPublic}>(UFC_NFT.CollectionPublicPath)
	if ufcCap.check() {
		ids["UFC"] = ufcCap.borrow()!.getIDs()
	}

	let motoGPCollectionCap = account.getCapability<&MotoGPCard.Collection{MotoGPCard.ICardCollectionPublic}>(/public/motogpCardCollection)
	if motoGPCollectionCap.check() {
		ids["MotoGPCard"] = motoGPCollectionCap.borrow()!.getIDs()
	}

	let gaiaCap = account.getCapability<&{Gaia.CollectionPublic}>(Gaia.CollectionPublicPath)
	if gaiaCap.check() {
		ids["Gaia"] = gaiaCap.borrow()!.getIDs()
	}

	let jambbCap = account.getCapability<&Moments.Collection{Moments.CollectionPublic}>(Moments.CollectionPublicPath)
	if jambbCap.check() {
		ids["Jambb"] = jambbCap.borrow()!.getIDs()
	}
	let voucherCap = account.getCapability<&{Vouchers.CollectionPublic}>(Vouchers.CollectionPublicPath)
	if voucherCap.check() {
		ids["JambbVoucher"] = voucherCap.borrow()!.getIDs()
	}

	let mwaCap = account.getCapability<&{MatrixWorldAssetsNFT.Metadata, NonFungibleToken.CollectionPublic}>(MatrixWorldAssetsNFT.collectionPublicPath)
	if mwaCap.check() {
		ids["MatrixWorldAssetsNFT"] = mwaCap.borrow()!.getIDs()
	}

	let mwffCap = account.getCapability<&{MatrixWorldFlowFestNFT.MatrixWorldFlowFestNFTCollectionPublic}>(MatrixWorldFlowFestNFT.CollectionPublicPath)
	if mwffCap.check() {
		ids["MatrixWorldFlowFest"] = mwffCap.borrow()!.getIDs()
	}

	let sturdyCap = account.getCapability<&SturdyItems.Collection{SturdyItems.SturdyItemsCollectionPublic}>(SturdyItems.CollectionPublicPath)
	if sturdyCap.check() {
		ids["SturdyItems"] = sturdyCap.borrow()!.getIDs()
	}

	let charityCap = account.getCapability<&{CharityNFT.CollectionPublic}>(/public/findCharityNFTCollection)
	if charityCap.check() {
		ids["FindCharity"] = charityCap.borrow()!.getIDs()
	}

	let evolutionCap=account.getCapability<&{Evolution.EvolutionCollectionPublic}>(/public/f4264ac8f3256818_Evolution_Collection)
	if evolutionCap.check() {
		ids["Evolution"] = evolutionCap.borrow()!.getIDs()
	}

	let geniaceCap = account.getCapability<&GeniaceNFT.Collection{NonFungibleToken.CollectionPublic, GeniaceNFT.GeniaceNFTCollectionPublic}>(GeniaceNFT.CollectionPublicPath)
	if geniaceCap.check() {
		ids["GeniaceNFT"] = geniaceCap.borrow()!.getIDs()
	}

	let ofCap = account.getCapability<&OneFootballCollectible.Collection{OneFootballCollectible.OneFootballCollectibleCollectionPublic}>(OneFootballCollectible.CollectionPublicPath)
	if ofCap.check() {
		ids["OneFootballCollectible"] = ofCap.borrow()!.getIDs()
	}

	let cryptoPiggoCap = account.getCapability<&{CryptoPiggo.CryptoPiggoCollectionPublic}>(CryptoPiggo.CollectionPublicPath)
	if cryptoPiggoCap.check() {
		ids["CryptoPiggo"] = cryptoPiggoCap.borrow()!.getIDs()
	}

	let xtinglesCap= account.getCapability<&{Collectible.CollectionPublic}>(Collectible.CollectionPublicPath)
	if xtinglesCap.check() {
		ids["Xtingles"] = xtinglesCap.borrow()!.getIDs()
	}

	let goatsVoucherCap = account.getCapability<&{GoatedGoatsVouchers.GoatsVoucherCollectionPublic}>(GoatedGoatsVouchers.CollectionPublicPath)
	if goatsVoucherCap.check() {
		ids["GoatedGoatsVoucher"] = goatsVoucherCap.borrow()!.getIDs()
	}

	let goatsTraitVoucherCap = account.getCapability<&{TraitPacksVouchers.PackVoucherCollectionPublic}>(TraitPacksVouchers.CollectionPublicPath)
	if goatsTraitVoucherCap.check() {
		ids["GoatedGoatsTraitVoucher"] = goatsTraitVoucherCap.borrow()!.getIDs()
	}

	let goatsCap = account.getCapability<&{MetadataViews.ResolverCollection}>(GoatedGoats.CollectionPublicPath)
	if goatsCap.check() {
		ids["GoatedGoats"] = goatsCap.borrow()!.getIDs()
	}

	let goatsTraitCap = account.getCapability<&{MetadataViews.ResolverCollection}>(GoatedGoatsTrait.CollectionPublicPath)
	if goatsTraitCap.check() {
		ids["GoatedGoatsTrait"] = goatsTraitCap.borrow()!.getIDs()
	}

	let goatsTraitPackCap = account.getCapability<&{MetadataViews.ResolverCollection}>(GoatedGoatsTraitPack.CollectionPublicPath)
	if goatsTraitPackCap.check() {
		ids["GoatedGoatsTraitPack"] = goatsTraitPackCap.borrow()!.getIDs()
	}


	let bitkuCap = account.getCapability<&{HaikuNFT.HaikuCollectionPublic}>(HaikuNFT.HaikuCollectionPublicPath)
	if bitkuCap.check() {
		ids["Bitku"] = bitkuCap.borrow()!.getIDs()
	}

	let klktnCap = account.getCapability<&{KlktnNFT.KlktnNFTCollectionPublic}>(KlktnNFT.CollectionPublicPath)
	if klktnCap.check() {
		ids["KLKTN"] = klktnCap.borrow()!.getIDs()
	}

	let mynftCap = account.getCapability<&{Mynft.MynftCollectionPublic}>(Mynft.CollectionPublicPath)
	if mynftCap.check() {
		ids["Mynft"] = mynftCap.borrow()!.getIDs()
	}

	let neoAvatarCap = account.getCapability<&{MetadataViews.ResolverCollection}>(NeoAvatar.CollectionPublicPath)
	if neoAvatarCap.check() {
		ids["NeoAvatar"] = neoAvatarCap.borrow()!.getIDs()
	}

	let neoVoucherCap = account.getCapability<&{MetadataViews.ResolverCollection}>(NeoVoucher.CollectionPublicPath)
	if neoVoucherCap.check() {
		ids["NeoVoucher"] = neoVoucherCap.borrow()!.getIDs()
	}

	let neoMemberCap = account.getCapability<&{MetadataViews.ResolverCollection}>(NeoMember.CollectionPublicPath)
	if neoMemberCap.check() {
		ids["NeoMember"] = neoMemberCap.borrow()!.getIDs()
	}

	let barterYardPackCap= account.getCapability<&{BarterYardPackNFT.BarterYardPackNFTCollectionPublic}>(BarterYardPackNFT.CollectionPublicPath)
	if barterYardPackCap.check() {
		ids["BarterYardClubPack"] = barterYardPackCap.borrow()!.getIDs()
	}

	let byCap = account.getCapability<&{MetadataViews.ResolverCollection}>(BarterYardClubWerewolf.CollectionPublicPath)
	if byCap.check() {
		ids["BarterYardClubWerewolf"] = byCap.borrow()!.getIDs()
	}

	let momentablesCap = account.getCapability<&{Momentables.MomentablesCollectionPublic}>(Momentables.CollectionPublicPath)
	if momentablesCap.check(){
		ids["Momentables"] = momentablesCap.borrow()!.getIDs()
	}

	let zeedzCap = account.getCapability<&{ZeedzINO.ZeedzCollectionPublic}>(ZeedzINO.CollectionPublicPath)
	if zeedzCap.check(){
		ids["ZeedzINO"]=zeedzCap.borrow()!.getIDs()
	}

	let dayCap = account.getCapability<&{MetadataViews.ResolverCollection}>(DayNFT.CollectionPublicPath)
	if dayCap.check() {
		ids["DayNFT"] = dayCap.borrow()!.getIDs()
	}

	let necroCap = account.getCapability<&{MetadataViews.ResolverCollection}>(Necryptolis.ResolverCollectionPublicPath)
	if necroCap.check() {
		ids["Necryptolis"] = necroCap.borrow()!.getIDs()
	}


	let sockIds : [UInt64] = [14813, 15013, 14946, 14808, 14899, 14792, 15016, 14961, 14816, 14796, 14992, 14977, 14815, 14863, 14817, 14814, 14875, 14960, 14985, 14850, 14849, 14966, 14826, 14972, 14795, 15021, 14950, 14847, 14970, 14833, 14786, 15010, 14953, 14799, 14883, 14947, 14844, 14801, 14886, 15015, 15023, 15027, 15029, 14802, 14810, 14948, 14955, 14957, 14988, 15007, 15009, 14837, 15024, 14803, 14973, 14969, 15002, 15017, 14797, 14894, 14881, 15025, 14791, 14979, 14789, 14993, 14873, 14939, 15005, 15006, 14869, 14889, 15004, 15008, 15026, 14990, 14998, 14898, 14819, 14840, 14974, 15019, 14856, 14838, 14787, 14876, 14996, 14798, 14855, 14824, 14843, 14959, 15020, 14862, 14822, 14897, 14830, 14790, 14867, 14878, 14991, 14835, 14818, 14892, 14800, 15000, 14857, 14986, 14805, 14812, 14962]


	let raribleCap = account.getCapability<&{NonFungibleToken.CollectionPublic}>(RaribleNFT.collectionPublicPath)

	if raribleCap.check() {
	let mySockIds : [UInt64] = []
	for id in raribleCap.borrow()!.getIDs() {
		if sockIds.contains(id) {
			mySockIds.append(id)
		}
	}
	ids["FlowverseSocks"] = mySockIds
	}


	let floatCap = account.getCapability<&{MetadataViews.ResolverCollection}>(FLOAT.FLOATCollectionPublicPath)
	if floatCap.check() {
		ids["FLOAT"] = floatCap.borrow()!.getIDs()
	}

  let mintStoreCap = account.getCapability<&{MintStoreItem.MintStoreItemCollectionPublic}>(MintStoreItem.CollectionPublicPath)
	if mintStoreCap.check() {
		ids["MintStore"] = mintStoreCap.borrow()!.getIDs()
	}

	let somePlaceCap =account.getCapability<&{SomePlaceCollectible.CollectibleCollectionPublic}>(SomePlaceCollectible.CollectionPublicPath)
	if somePlaceCap.check(){
		ids["SomePlace"] = somePlaceCap.borrow()!.getIDs()
	}

	let bl0xCap = account.getCapability<&{MetadataViews.ResolverCollection}>(Bl0x.CollectionPublicPath)
	if bl0xCap.check() {
		ids["Bl0x"] = bl0xCap.borrow()!.getIDs()
	}

	let bl0xPackCap = account.getCapability<&{MetadataViews.ResolverCollection}>(Bl0xPack.CollectionPublicPath)
	if bl0xPackCap.check() {
		ids["Bl0xPack"] = bl0xPackCap.borrow()!.getIDs()
	}

	for key in ids.keys {
		if ids[key]!.length == 0 {
			ids.remove(key: key)
		}
	}
	return ids
}


pub fun main(user: String) : {String: [UInt64]} {
	let resolvingAddress = FIND.resolve(user)
	if resolvingAddress == nil {
		return {}
	}
	let address = resolvingAddress!

	return getNFTIDs(ownerAddress: address)
}

