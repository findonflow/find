import "FIND"
import "NonFungibleToken"
import "FungibleToken"
import "Dandy"
import "MetadataViews"
import "FindForge"

transaction(name: String, minterCut: UFix64, description:String, externalUrl:String, squareImage:String, bannerImage:String, socials:{String:String}) {
	prepare(account: auth(BorrowValue) &Account) {

		let dandyCap= account.getCapability<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			account.storage.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
			account.link<&Dandy.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPublicPath,
				target: Dandy.CollectionStoragePath
			)
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

		let finLeases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
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
