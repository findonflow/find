
import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FindForge from "../contracts/FindForge.cdc"

transaction(name: String, maxEdition:UInt64, nftName:String, nftDescription:String, nftImage:String) {
	prepare(account: AuthAccount) {

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(name)
		let forgeType = Dandy.getForgeType()

		let dandyCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
		let httpFile=MetadataViews.HTTPFile(url:nftImage)
		let media=MetadataViews.Media(file: httpFile, mediaType: "image/png")

		let receiver=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let nftReceiver=account.getCapability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(Dandy.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to Dandy collection.")

		let traits = MetadataViews.Traits([])
		traits.addTrait(MetadataViews.Trait(name: "forger", value: "Find", displayType:"String", rarity:nil))

		let collection=dandyCap.borrow()!
		var i:UInt64=1

		while i <= maxEdition {

			let editioned= MetadataViews.Edition(name: nil, number:i, max:maxEdition)
			let set= MetadataViews.Edition(name: "set", number:i, max:maxEdition)
			let editions = MetadataViews.Editions([editioned, set])
			let schemas: [AnyStruct] = [ editions, MetadataViews.Medias([media]), traits ]
			
			let mintData = Dandy.DandyInfo(name: nftName, 
												description: nftDescription, 
												thumbnail: media, 
												schemas: schemas, 
												externalUrlPrefix:"https://find.xyz/collection/".concat(name).concat("/dandy"))
			
			FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)
		
			i=i+1
		}

	}
}
