import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"
import Artifact from "../contracts/Artifact.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(name: String) {
	prepare(account: AuthAccount) {

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!

		let sharedContentCap =account.getCapability<&{TypedMetadata.ViewResolverCollection}>(/private/sharedContent)
		if !sharedContentCap.check() {
			account.save<@NonFungibleToken.Collection>(<- Artifact.createEmptyCollection(), to: /storage/sharedContent)
			account.link<&{TypedMetadata.ViewResolverCollection}>(/private/sharedContent, target: /storage/sharedContent)
		}

		let sharedSchemas : [AnyStruct] = [
			TypedMetadata.Media(data:"https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp" , contentType: "image/webp", protocol: "http"),
			TypedMetadata.CreativeWork(artist:"Neo Motorcycles", name:"Neo Bike ", description: "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK", type:"image"),
			TypedMetadata.Royalties(royalty: {"artist" : TypedMetadata.createPercentageRoyalty(user: account.address , cut: 0.05)})
		]

		let sharedNFT <- finLeases.mintArtifact(name: name, nftName: "NeoBike", schemas:sharedSchemas)
		let sharedPointer= Artifact.Pointer(collection: sharedContentCap, id: sharedNFT.id, views: [Type<TypedMetadata.Media>(), Type<TypedMetadata.CreativeWork>(), Type<TypedMetadata.Royalties>()])
		sharedContentCap.borrow()!.deposit(token: <- sharedNFT)
	
		let cap = account.getCapability<&{TypedMetadata.ViewResolverCollection}>(Artifact.ArtifactPublicPath)

		cap.borrow()!.deposit(token: <- finLeases.mintNFTWithSharedData(name: name, nftName: "Neo Motorcycle 1 of 3", schemas: [ TypedMetadata.Editioned(edition:1, maxEdition: 3)], sharedPointer: sharedPointer))
		cap.borrow()!.deposit(token: <- finLeases.mintNFTWithSharedData(name: name, nftName: "Neo Motorcycle 2 of 3", schemas: [ TypedMetadata.Editioned(edition:2, maxEdition: 3)], sharedPointer: sharedPointer))
		cap.borrow()!.deposit(token: <- finLeases.mintNFTWithSharedData(name: name, nftName: "Neo Motorcycle 3 of 3", schemas: [ TypedMetadata.Editioned(edition:3, maxEdition: 3)], sharedPointer: sharedPointer))

	}
}
