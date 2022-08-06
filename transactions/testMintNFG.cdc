import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFunGerbilsNFT from "../contracts/NonFunGerbilsNFT.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"


transaction(name: String, nftName:String, nftDescription:String, nftUrl:String, externalURL: String, traits: {String: String}, birthday: UFix64?, values: {String: UFix64}) {
	prepare(account: AuthAccount) {

		let collectionCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(NonFunGerbilsNFT.CollectionPublicPath)
		if !collectionCap.check() {
			account.save<@NonFungibleToken.Collection>(<- NonFunGerbilsNFT.createEmptyCollection(), to: NonFunGerbilsNFT.CollectionStoragePath)
			account.link<&NonFunGerbilsNFT.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NonFunGerbilsNFT.CollectionPublicPath,
				target: NonFunGerbilsNFT.CollectionStoragePath
			)
			account.link<&NonFunGerbilsNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NonFunGerbilsNFT.CollectionPrivatePath,
				target: NonFunGerbilsNFT.CollectionStoragePath
			)
		}

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(name)
		let forgeType = NonFunGerbilsNFT.getForgeType()

		let nftReceiver=account.getCapability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(NonFunGerbilsNFT.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to NonFunGerbilsNFT collection.")

		let collection=collectionCap.borrow()!
		//TOOD: fix adding all data from transaction
		let mintData = NonFunGerbilsNFT.NonFunGerbilsNFTInfo(name: "Neo", description: "Non Fun Gerbil", thumbnail: nftUrl)
		
		FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)

	}
}
