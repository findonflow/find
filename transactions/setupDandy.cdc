import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Dandy from "../contracts/Dandy.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"

transaction(name: String, minterCut: UFix64, description:String, externalUrl:String, squareImage:String, bannerImage:String, socials:{String:String}) {
	prepare(account: AuthAccount) {

		let dandyCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			account.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
			account.link<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPublicPath,
				target: Dandy.CollectionStoragePath
			)
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(name)
		let forgeType = Dandy.getForgeType()
		if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
			FindForge.setMinterPlatform(lease: lease, 
										forgeType: forgeType, 
										minterCut: minterCut, 
										description: description, 
										externalURL: externalUrl,
										squareImage: squareImage, 
										bannerImage: bannerImage, 
										socials: socials)
		}
	}
}
