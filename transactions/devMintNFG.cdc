import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NFGv3 from "../contracts/NFGv3.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"


transaction(name: String, maxEditions:UInt64, nftName:String, nftDescription:String, imageHash:String, externalURL: String, traits: {String: String}, birthday: UFix64, levels: {String: UFix64}, scalars : {String:UFix64}, medias:{String:String}) {
	prepare(account: AuthAccount) {

		let collectionCap= account.getCapability<&{NonFungibleToken.Collection}>(NFGv3.CollectionPublicPath)
		if !collectionCap.check() {
			account.save<@NonFungibleToken.Collection>(<- NFGv3.createEmptyCollection(), to: NFGv3.CollectionStoragePath)
			account.link<&NFGv3.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				NFGv3.CollectionPublicPath,
				target: NFGv3.CollectionStoragePath
			)
			account.link<&NFGv3.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				NFGv3.CollectionPrivatePath,
				target: NFGv3.CollectionStoragePath
			)
		}

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(name)
		let forgeType = NFGv3.getForgeType()

		let nftReceiver=account.getCapability<&{NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(NFGv3.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to NFGv3 collection.")

		var i = UInt64(1)
		let collection=collectionCap.borrow()!
		while  i <= maxEditions {
			let mintData = NFGv3.Info(
				name: nftName,
				description: nftDescription, 
				thumbnailHash: imageHash,
				edition: i, 
				maxEdition: maxEditions,
				externalURL: externalURL,
				traits: traits,
				levels: levels, 
				scalars: scalars, 
				birthday: birthday, 
				medias: medias
			)
			FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)
			i=i+1
		}

	}
}
