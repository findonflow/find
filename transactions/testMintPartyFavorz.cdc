import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import PartyFavorz from "../contracts/PartyFavorz.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"


transaction(name: String, maxEditions:UInt64, nftName:String, nftDescription:String, imageHash:String) {
	prepare(account: AuthAccount) {

		let collectionCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(PartyFavorz.CollectionPublicPath)
		if !collectionCap.check() {
			account.save<@NonFungibleToken.Collection>(<- PartyFavorz.createEmptyCollection(), to: PartyFavorz.CollectionStoragePath)
			account.link<&PartyFavorz.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				PartyFavorz.CollectionPublicPath,
				target: PartyFavorz.CollectionStoragePath
			)
			account.link<&PartyFavorz.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				PartyFavorz.CollectionPrivatePath,
				target: PartyFavorz.CollectionStoragePath
			)
		}

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(name)
		let forgeType = PartyFavorz.getForgeType()

		let nftReceiver=account.getCapability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(PartyFavorz.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to PartyFavorz collection.")

		var i = UInt64(1)
		let collection=collectionCap.borrow()!
		while  i <= maxEditions {
			let mintData = PartyFavorz.Info(
				name: nftName,
				description: nftDescription, 
				thumbnailHash: imageHash,
				edition: i, 
				maxEdition: maxEditions
			)
			FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)
			i=i+1
		}

	}
}
