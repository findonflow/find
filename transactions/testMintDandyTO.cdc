
import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"

transaction(name: String, maxEdition:UInt64, artist:String, nftName:String, nftDescription:String, nftUrl:String, rarity: String, rarityNum:UFix64, to: Address) {
	prepare(account: AuthAccount) {

		let dancyReceiver =getAccount(to)
		let dandyCap= dancyReceiver.getCapability<&{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			panic("need dandy receicer")
		}

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!

		let creativeWork=
		FindViews.CreativeWork(artist: artist, name: nftName, description: nftDescription, type:"image")

		//TODO: use Image/Video here.
		let media=MetadataViews.HTTPFile(url:nftUrl)

		let rarity = FindViews.Rarity(rarity: rarityNum, rarityName:rarity, parts: {})

		let receiver=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let minterRoyalty=MetadataViews.Royalties(cutInfos:[MetadataViews.Royalty(receiver: receiver, cut: 0.05, description: "artist")])

		let tag=FindViews.Tag({"NeoMotorCycleTag":"Tag1"})
		let scalar=FindViews.Scalar({"Speed" : 100.0})

		let collection=dandyCap.borrow()!
		var i:UInt64=1

		while i <= maxEdition {

			let editioned= FindViews.Edition(edition:i, maxEdition:maxEdition)
			let description=creativeWork.description.concat( " edition ").concat(i.toString()).concat( " of ").concat(maxEdition.toString())
			let schemas: [AnyStruct] = [ editioned, creativeWork, media, minterRoyalty, rarity, tag, scalar]
			let token <- finLeases.mintDandy(minter: name, 
			  nftName: "Neo Motorcycle ".concat(i.toString()).concat(" of ").concat(maxEdition.toString()), 
				description: creativeWork.description,
				schemas: schemas, 
				externalUrlPrefix: "https://find.xyz/collection/".concat(name).concat("/dandy"),
				collectionDescription: "Neo Collectibles FIND",
				collectionExternalURL: "https://neomotorcycles.co.uk/index.html",
				collectionSquareImage: "https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp",
				collectionBannerImage: "https://neomotorcycles.co.uk/assets/img/neo-logo-web-dark.png?h=5a4d226197291f5f6370e79a1ee656a1",
			)

			collection.deposit(token: <- token)
			i=i+1
		}

	}
}
