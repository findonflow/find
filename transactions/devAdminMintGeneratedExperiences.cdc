import Admin from "../contracts/Admin.cdc"
import FIND from "../contracts/FIND.cdc"
import GeneratedExperiences from "../contracts/GeneratedExperiences.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"

transaction(name: String, info: [GeneratedExperiences.Info]) {
    prepare(account: AuthAccount){

		// setup Collection
		if account.borrow<&GeneratedExperiences.Collection>(from: GeneratedExperiences.CollectionStoragePath) == nil {
			let collection <- GeneratedExperiences.createEmptyCollection()
			account.save(<-collection, to: GeneratedExperiences.CollectionStoragePath)
			account.link<&GeneratedExperiences.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(GeneratedExperiences.CollectionPublicPath, target: GeneratedExperiences.CollectionStoragePath)
			account.link<&GeneratedExperiences.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(GeneratedExperiences.CollectionPrivatePath, target: GeneratedExperiences.CollectionStoragePath)
		}

        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

		let forgeType = GeneratedExperiences.getForgeType()
		if !FindForge.checkMinterPlatform(name: name, forgeType: forgeType ) {
			/* set up minterPlatform */
			adminRef.adminSetMinterPlatform(name: name,
										forgeType: forgeType,
										minterCut: 0.00,
										description: "setup for minter platform",
										externalURL: "setup for minter platform",
										squareImage: "setup for minter platform",
										bannerImage: "setup for minter platform",
										socials: {})
		}

		let nftReceiver=account.getCapability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(GeneratedExperiences.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to ExampleNFT collection.")

		for i in info {
			adminRef.mintForge(name: name, forgeType: forgeType, data: i, receiver: nftReceiver)
		}
    }
}

