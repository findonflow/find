
import "FIND"
import "NonFungibleToken"
import "FungibleToken"
import "NFGv3"
import "Profile"
import "MetadataViews"
import "FindForge"

transaction(name: String, minterCut: UFix64, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String, collectionBannerImage: String, socials: {String: String}) {
	prepare(account: auth(BorrowValue) &Account) {

		let finLeases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
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
