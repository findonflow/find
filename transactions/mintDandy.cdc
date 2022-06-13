
import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
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

		let httpFile=MetadataViews.HTTPFile(url:nftUrl)
		let media=MetadataViews.Media(file: httpFile, mediaType: "image/png")

		let receiver=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let minterRoyalty=MetadataViews.Royalties(cutInfos:[MetadataViews.Royalty(receiver: receiver, cut: 0.05, description: "artist")])
		let tag=FindViews.Tag({"NeoMotorCycleTag":"Tag1"})
		let scalar=FindViews.Scalar({"Speed" : 100.0})

		let collection=dandyCap.borrow()!
		var i:UInt64=1

		let lease=finLeases.borrow(name)


		/*
		if !finLeases.borrow(name).containsForgeMinter(Type<@Dandy.ForgeMinter>().identifier) {
			finLeases.addForgeMinter(name: name, forgeMinterType: Type<@Dandy.ForgeMinter>().identifier, description: collectionDescription, externalURL: collectionExternalURL, squareImage: collectionSquareImage, bannerImage: collectionBannerImage)
		}
		*/
		//TODO: psudo code
		//TODO; if your lease cannot mint this type then panic with good error message?
		//TODO: add method to check if you can mint with lease/type
		/*
		FindForge.mint(lease: lease, type: Type<@Dandy.ForgeMinte>(), function(minter:&{FindForge.Minter}){

			while i <= maxEdition {

				let editioned= MetadataViews.Edition(name: nil, number:i, max:maxEdition)
				let set= MetadataViews.Edition(name: "set", number:i, max:maxEdition)
				let editions = MetadataViews.Editions([editioned, set])
				let description=creativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
				let schemas: [AnyStruct] = [ editions, creativeWork, media, minterRoyalty, tag, scalar ]
				
				let mintData = Dandy.DandyInfo(name: "Neo Motorcycle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
												 description: creativeWork.description, 
												 thumbnail: media, 
												 schemas: schemas, 
												 externalUrlPrefix:"https://find.xyz/collection/".concat(name).concat("/dandy"))
				
				let token <- minter.mint(minter: name, forgeMinter: Type<@Dandy.ForgeMinter>().identifier, mintData: mintData)
				
				collection.deposit(token: <- token)
				i=i+1
			}

			let token <- minter.mint(mintData: mintData)
		})
		*/

	}
}
