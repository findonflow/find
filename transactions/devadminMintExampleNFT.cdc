import Admin from "../contracts/Admin.cdc"
import FIND from "../contracts/FIND.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FindForge from "../contracts/FindForge.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(name: String, artist:String, nftName:String, nftDescription:String, traits: [UInt64], nftUrl:String, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String, collectionBannerImage: String) {
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
		
		let address = FIND.lookupAddress(name) ?? panic("Cannot find user with name : ".concat(name))

		let forgeType = ExampleNFT.getForgeType()
		if !FindForge.checkMinterPlatform(name: name, forgeType: forgeType ) {
			/* set up minterPlatform */
			adminRef.adminSetMinterPlatform(name: name, 
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

		let nftReceiver=getAccount(address).getCapability<&{NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(ExampleNFT.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to ExampleNFT collection.")

		let description=creativeWork.description.concat( " edition ").concat("1 of 1")
		
		let mintData = ExampleNFT.ExampleNFTInfo(name: "Neo", description: description, soulBound: false,traits: traits, thumbnail: nftUrl)
		
		adminRef.mintForge(name: name, forgeType: forgeType, data: mintData, receiver: nftReceiver)
    }
}

