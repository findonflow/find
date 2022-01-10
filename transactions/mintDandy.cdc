import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

transaction(name: String) {
	prepare(account: AuthAccount) {

		let dandyCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			account.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
			account.link<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				Dandy.CollectionPublicPath,
				target: Dandy.CollectionStoragePath
			)
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!

		let creativeWork=
		TypedMetadata.CreativeWork(artist:"Neo Motorcycles", name:"Neo Bike ", description: "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK", type:"image")

		let media=TypedMetadata.GenericMedia(data:"https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp" , contentType: "image/webp", protocol: "http")



		let receiver=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let minterRoyalty=Dandy.Royalties(royalty: {"artist" : Dandy.RoyaltyItem(receiver: receiver, cut: 0.05)})

		let collection=dandyCap.borrow()!
		var i:UInt64=1
		let maxEdition:UInt64=3
		while i <= maxEdition {

			let editioned= TypedMetadata.Editioned(edition:i, maxEdition:maxEdition)
			let description=creativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			//TODO: do not send in Display but calculate it, send in thumbnail url if you do not have explicit media
			let schemas: [AnyStruct] = [ editioned, creativeWork, media, minterRoyalty]
			let token <- finLeases.mintDandy(minter: name, nftName: "Neo Motorcycle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), schemas: schemas)

			collection.deposit(token: <- token)
			i=i+1
		}

	}
}

