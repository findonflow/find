import Admin from "../contracts/Admin.cdc"
import FIND from "../contracts/FIND.cdc"
import GeneratedExperience from "../contracts/GeneratedExperience.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"

transaction(name: String, info: [GeneratedExperience.Info]) {
    prepare(account: AuthAccount){

		// setup Collection
		if account.borrow<&GeneratedExperience.Collection>(from: GeneratedExperience.CollectionStoragePath) == nil {
			let collection <- GeneratedExperience.createEmptyCollection()
			account.save(<-collection, to: GeneratedExperience.CollectionStoragePath)
			account.link<&GeneratedExperience.Collection{NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(GeneratedExperience.CollectionPublicPath, target: GeneratedExperience.CollectionStoragePath)
			account.link<&GeneratedExperience.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(GeneratedExperience.CollectionPrivatePath, target: GeneratedExperience.CollectionStoragePath)
		}

        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

		let forgeType = GeneratedExperience.getForgeType()
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

		let nftReceiver=account.getCapability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(GeneratedExperience.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to ExampleNFT collection.")

		for i in info {
			adminRef.mintForge(name: name, forgeType: forgeType, data: i, receiver: nftReceiver)
		}
    }
}

