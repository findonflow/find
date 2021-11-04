import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"
import Artifact from "../contracts/Artifact.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"


transaction(user: Address) {
	prepare(account: AuthAccount) {

		let adminClient=account.borrow<&FIND.AdminProxy>(from: FIND.AdminProxyStoragePath)!


		let sharedContentCap =account.getCapability<&{TypedMetadata.ViewResolverCollection}>(/private/sharedContent)
		if !sharedContentCap.check() {
			account.save<@NonFungibleToken.Collection>(<- Artifact.createEmptyCollection(), to: /storage/sharedContent)
			account.link<&{TypedMetadata.ViewResolverCollection}>(/private/sharedContent, target: /storage/sharedContent)
		}

		let userAccount=getAccount(user)
//		let adminReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		let userReceiver = userAccount.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
//		let adminRoyalty = TypedMetadata.Royalty(wallet: adminReceiver, cut: 0.025, type: Type<@FUSD.Vault>(), percentage:true)
		let userRoyalty = TypedMetadata.Royalty(wallet: userReceiver, cut: 0.05, type: Type<@FUSD.Vault>(), percentage:true)

		let profileCap =account.getCapability<&{Profile.Public}>(Profile.publicPath)
		let minter <- adminClient.createForge(platform: Artifact.MinterPlatform(name: "Example",  owner: profileCap, minter: profileCap, ownerPercentCut: 0.025))
	

		let sharedSchemas : [AnyStruct] = [
			TypedMetadata.Media(data:"https://neomotorcycles.co.uk/assets/img/neo_motorcycle_side.webp" , contentType: "image/webp", protocol: "http"),
			TypedMetadata.CreativeWork(artist:"Neo Motorcycles", name:"Neo Bike ", description: "Bringing the motorcycle world into the 21st century with cutting edge EV technology and advanced performance in a great classic British style, all here in the UK", type:"image"),
			TypedMetadata.Royalties(royalty: {"minter" : userRoyalty})
		]

		let sharedNFT <- minter.mintNFT(name: "NeoBike", schemas: sharedSchemas)

		let sharedPointer= Artifact.Pointer(collection: sharedContentCap, id: sharedNFT.id)
		sharedContentCap.borrow()!.deposit(token: <- sharedNFT)
	
		let cap = userAccount.getCapability<&{TypedMetadata.ViewResolverCollection}>(Artifact.ArtifactPublicPath)

		cap.borrow()!.deposit(token: <- minter.mintNFTWithSharedData(name: "Neo Motorcycle 1 of 3", schemas: [ TypedMetadata.Editioned(edition:1, maxEdition: 3)], sharedPointer: sharedPointer))
		cap.borrow()!.deposit(token: <- minter.mintNFTWithSharedData(name: "Neo Motorcycle 2 of 3", schemas: [ TypedMetadata.Editioned(edition:2, maxEdition: 3)], sharedPointer: sharedPointer))
		cap.borrow()!.deposit(token: <- minter.mintNFTWithSharedData(name: "Neo Motorcycle 3 of 3", schemas: [ TypedMetadata.Editioned(edition:3, maxEdition: 3)], sharedPointer: sharedPointer))

		//you should really store this, but this is a demo
		destroy minter
	}
}
