
import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NFGv3 from "../contracts/NFGv3.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"

transaction(name: String, minterCut: UFix64, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String, collectionBannerImage: String, socials: {String: String}) {
	prepare(account: AuthAccount) {

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(name)
		let forgeType = NFGv3.getForgeType()
		if !FindForge.checkMinterPlatform(name: lease.getName(), forgeType: forgeType ) {
			/* set up minterPlatform */
			FindForge.setMinterPlatform(lease: lease, 
										forgeType: forgeType, 
										minterCut: minterCut, 
										//these values will be replaced with what we have from NFG contract
										description: collectionDescription, 
										externalURL: collectionExternalURL, 
										squareImage: collectionSquareImage, 
										bannerImage: collectionBannerImage, 
										socials: socials
									)
		}
	}
}
