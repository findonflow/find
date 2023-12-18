import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import PartyFavorz from "../contracts/PartyFavorz.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"


transaction(name: String, startFrom: UInt64, number: Int, maxEditions:UInt64, nftName:String, nftDescription:String, imageHash:String, fullSizeHash: String, artist: String, season: UInt64, royaltyReceivers: [Address], royaltyCuts: [UFix64], royaltyDescs: [String], squareImage: String, bannerImage: String) {
	prepare(account: auth(BorrowValue) &Account) {

		let collectionCap= account.getCapability<&{NonFungibleToken.Collection}>(PartyFavorz.CollectionPublicPath)
		if !collectionCap.check() {
			account.save<@NonFungibleToken.Collection>(<- PartyFavorz.createEmptyCollection(), to: PartyFavorz.CollectionStoragePath)
			account.link<&PartyFavorz.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				PartyFavorz.CollectionPublicPath,
				target: PartyFavorz.CollectionStoragePath
			)
			account.link<&PartyFavorz.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				PartyFavorz.CollectionPrivatePath,
				target: PartyFavorz.CollectionStoragePath
			)
		}

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(name)
		let forgeType = PartyFavorz.getForgeType()

		let nftReceiver=account.getCapability<&{NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(PartyFavorz.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to PartyFavorz collection.")

		let royalties : [MetadataViews.Royalty] = []
		for i , rec in royaltyReceivers {
			var cap = getAccount(rec).getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
			if !cap.check() {
				cap = getAccount(rec).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
			}
			royalties.append(MetadataViews.Royalty(receiver: cap, cut: royaltyCuts[i], description: royaltyDescs[i]))
		}

		var i = 0
		let collection=collectionCap.borrow()!
		while  i < number {
			let mintData: {String : AnyStruct} = {
			
				"info" : PartyFavorz.Info(
					name: nftName,
					description: nftDescription, 
					thumbnailHash: imageHash,
					edition: startFrom + UInt64(i), 
					maxEdition: maxEditions, 
					fullSizeHash: fullSizeHash, 
					artist: artist
				), 
				"royalties" : royalties, 
				"season" : season, 
				"squareImage" : squareImage, 
				"bannerImage" : bannerImage 
			}
			FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)
			i=i+1
		}

	}
}
