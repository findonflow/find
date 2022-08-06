
import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFunGerbilsNFT from "../contracts/NonFunGerbilsNFT.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"

transaction(name: String, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String, collectionBannerImage: String) {
	prepare(account: AuthAccount) {


		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(name)
		let forgeType = NonFunGerbilsNFT.getForgeType()
		if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										forgeType: forgeType, 
										//LUKE: how much royalty do you want to take on secondaries? 
										minterCut: 0.025, 
										//these values will be replaced with what we have from NFG contract
										description: collectionDescription, 
										externalURL: collectionExternalURL, 
										squareImage: collectionSquareImage, 
										bannerImage: collectionBannerImage, 
										socials: {
											"Twitter" : "https://twitter.com/home" ,
											"Discord" : "discord.gg/"
										})
		}
	}
}
