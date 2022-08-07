import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NFGv3 from "../contracts/NFGv3.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"


transaction(name: String, nftName:String, nftDescription:String, nftUrl:String, externalURL: String, traits: {String: String}, birthday: UFix64?, values: {String: UFix64}) {
	prepare(account: AuthAccount) {

		let collectionCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(NFGv3.CollectionPublicPath)
		if !collectionCap.check() {
			account.save<@NonFungibleToken.Collection>(<- NFGv3.createEmptyCollection(), to: NFGv3.CollectionStoragePath)
			account.link<&NFGv3.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NFGv3.CollectionPublicPath,
				target: NFGv3.CollectionStoragePath
			)
			account.link<&NFGv3.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NFGv3.CollectionPrivatePath,
				target: NFGv3.CollectionStoragePath
			)
		}

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(name)
		let forgeType = NFGv3.getForgeType()

		let nftReceiver=account.getCapability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(NFGv3.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to NFGv3 collection.")

		let collection=collectionCap.borrow()!
		//TOOD: fix adding all data from transaction
		let mintData = NFGv3.NFGv3Info(name: "Neo", description: "Non Fun Gerbil", thumbnail: nftUrl)
		
		FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)

	}
}
