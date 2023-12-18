import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Dandy from "../contracts/Dandy.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindForge from "../contracts/FindForge.cdc"

transaction(name: String, maxEdition:UInt64, nftName:String, nftDescription:String, folderHash:String) {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let lease=finLeases.borrow(name)
		let forgeType = Dandy.getForgeType()

		let dandyCap= account.getCapability<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)
		let thumbNail=MetadataViews.IPFSFile(cid:folderHash, path: "thumbnail.webp")
		let fullsize=MetadataViews.IPFSFile(cid:folderHash, path: "fullsize.webp")
		let mediaFullsize=MetadataViews.Media(file: fullsize, mediaType: "image/webp")
		let mediaThumbnail=MetadataViews.Media(file: thumbNail, mediaType: "image/webp")

		let nftReceiver=account.getCapability<&{NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(Dandy.CollectionPublicPath).borrow() ?? panic("Cannot borrow reference to Dandy collection.")

		let traits = MetadataViews.Traits([])
		traits.addTrait(MetadataViews.Trait(name: "Creator", value: ".find", displayType:"Author", rarity:nil))

		let collection=dandyCap.borrow()!
		var i:UInt64=1

		while i <= maxEdition {

			let editioned= MetadataViews.Edition(name: nil, number:i, max:maxEdition)
			let set= MetadataViews.Edition(name: "set", number:i, max:maxEdition)
			let editions = MetadataViews.Editions([editioned, set])

			let schemas: [AnyStruct] = [ editions, MetadataViews.Medias([mediaFullsize, mediaThumbnail]), traits ]
			
			let mintData = Dandy.DandyInfo(name: nftName, 
												description: nftDescription, 
												thumbnail: mediaThumbnail, 
												schemas: schemas, 
												externalUrlPrefix:"https://find.xyz/".concat(name).concat("/collection/Dandy"))
			
			FindForge.mint(lease: lease, forgeType: forgeType, data: mintData, receiver: nftReceiver)
		
			i=i+1
		}
	}
}
