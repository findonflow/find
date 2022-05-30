
import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"

transaction(name: String, maxEdition:UInt64, artist:String, nftName:String, nftDescription:String, nftUrl:String, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String, collectionBannerImage: String) {
	prepare(account: AuthAccount) {

		let dandyCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			account.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
			account.link<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPublicPath,
				target: Dandy.CollectionStoragePath
			)
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!

		let creativeWork=
		FindViews.CreativeWork(artist: artist, name: nftName, description: nftDescription, type:"image")

		//TODO: use Image/Video here.
		let media=MetadataViews.HTTPFile(url:nftUrl)

		let receiver=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let minterRoyalty=MetadataViews.Royalties(cutInfos:[MetadataViews.Royalty(receiver: receiver, cut: 0.05, description: "artist")])
		let tag=FindViews.Tag({"NeoMotorCycleTag":"Tag1"})
		let scalar=FindViews.Scalar({"Speed" : 100.0})

		let collection=dandyCap.borrow()!
		var i:UInt64=1
		while i <= maxEdition {

			let editioned= MetadataViews.Edition(edition:i, maxEdition:maxEdition)
			let description=creativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let schemas: [AnyStruct] = [ editioned, creativeWork, media, minterRoyalty, tag, scalar ]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "Neo Motorcycle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: creativeWork.description,
				schemas: schemas, 
				externalUrlPrefix: "https://find.xyz/collection/".concat(name).concat("/dandy"),
				collectionDescription: collectionDescription,
				collectionExternalURL: collectionExternalURL, 
				collectionSquareImage: collectionSquareImage,
				collectionBannerImage: collectionBannerImage
				)

			collection.deposit(token: <- token)
			i=i+1
		}

	}
}
