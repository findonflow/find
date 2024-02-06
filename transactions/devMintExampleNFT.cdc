
import "FIND"
import "NonFungibleToken"
import "FungibleToken"
import "ExampleNFT"
import "Profile"
import "MetadataViews"
import "FindViews"
import "FindForge"

transaction(name: String, artist:String, nftName:String, nftDescription:String, traits: [UInt64], nftUrl:String, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String, collectionBannerImage: String) {
	prepare(account: auth(BorrowValue) &Account) {

		let collectionCap= account.getCapability<&{NonFungibleToken.Collection}>(ExampleNFT.CollectionPublicPath)
		if !collectionCap.check() {
			account.storage.save<@NonFungibleToken.Collection>(<- ExampleNFT.createEmptyCollection(), to: ExampleNFT.CollectionStoragePath)
			account.link<&ExampleNFT.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, ExampleNFT.ExampleNFTCollectionPublic}>(
				ExampleNFT.CollectionPublicPath,
				target: ExampleNFT.CollectionStoragePath
			)
			account.link<&ExampleNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, ExampleNFT.ExampleNFTCollectionPublic}>(
				ExampleNFT.CollectionPrivatePath,
				target: ExampleNFT.CollectionStoragePath
			)
		}

		let finLeases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(name)
		let forgeType = ExampleNFT.getForgeType()
		if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										forgeType: forgeType, 
										minterCut: 0.05, 
										description: collectionDescription, 
										externalURL: collectionExternalURL, 
										squareImage: collectionSquareImage, 
										bannerImage: collectionBannerImage, 
										socials: {
											"Twitter" : "https://twitter.com/home" ,
											"Discord" : "discord.gg/"
										})
		}

		let creativeWork=
		FindViews.CreativeWork(artist: artist, name: nftName, description: nftDescription, type:"image")

		let receiver=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let nftReceiver=account.getCapability<&{NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(ExampleNFT.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to ExampleNFT collection.")

		let collection=collectionCap.borrow()!
		let description=creativeWork.description.concat( " edition ").concat("1 of 1")
		
		let mintData = ExampleNFT.ExampleNFTInfo(name: "Neo", description: description, soulBound: false,traits: traits, thumbnail: nftUrl)
		
		FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)

	}
}
