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
		let adminReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		let userReceiver = userAccount.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		let adminRoyalty = TypedMetadata.Royalty(wallet: adminReceiver, cut: 0.025, type: Type<@FUSD.Vault>(), percentage:true)
		let userRoyalty = TypedMetadata.Royalty(wallet: userReceiver, cut: 0.05, type: Type<@FUSD.Vault>(), percentage:true)



		let profileCap =account.getCapability<&{Profile.Public}>(Profile.publicPath)
		let minter <- adminClient.createMinter(platform: Artifact.MinterPlatform(name: "Example",  owner: profileCap, minter: profileCap, ownerPercentCut: 0.025))
	

		let sharedSchemas : [AnyStruct] = [
			TypedMetadata.Media(data:"https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_auto/f_auto/maincache5" , contentType: "image/png", protocol: "http"),
			TypedMetadata.CreativeWork(artist:"Versus", name:"VS", description: "Early adopter tester reward NFT", type:"image"),
			TypedMetadata.Royalties(royalty: { "minter" : adminRoyalty, "artist" : userRoyalty})
		]

		let sharedNFT <- minter.mintNFT(name: "Art", schemas: sharedSchemas)

		let sharedPointer= Artifact.Pointer(collection: sharedContentCap, id: sharedNFT.id)
		sharedContentCap.borrow()!.deposit(token: <- sharedNFT)
	
		let cap = userAccount.getCapability<&{TypedMetadata.ViewResolverCollection}>(Artifact.ArtifactPublicPath)

		let schemas : [AnyStruct] = [
			TypedMetadata.Editioned(edition: 1, maxEdition:3)
		]

		let nft  <- minter.mintNFTWithSharedData(name: "Art0", schemas: schemas, sharedPointer: sharedPointer)

		cap.borrow()!.deposit(token: <- nft)

		//you should really store this, but this is a demo
		destroy minter
	}
}
