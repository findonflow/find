import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"
import Artifact from "../contracts/Artifact.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(user: Address) {
	prepare(account: AuthAccount) {

		let adminClient=account.borrow<&FIND.AdminProxy>(from: FIND.AdminProxyStoragePath)!


		let userAccount=getAccount(user)
		let adminReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		let userReceiver = userAccount.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)


		let adminRoyalty = TypedMetadata.Royalty(wallet: adminReceiver, cut: 0.025, type: Type<@FUSD.Vault>(), percentage:true)
		let userRoyalty = TypedMetadata.Royalty(wallet: userReceiver, cut: 0.05, type: Type<@FUSD.Vault>(), percentage:true)

		let cap = userAccount.getCapability<&{TypedMetadata.ViewResolverCollection}>(Artifact.ArtifactPublicPath)

		let schemas : [AnyStruct] = [
			TypedMetadata.Editioned(edition: 1, maxEdition:3),
			TypedMetadata.WebMedia(url:"https://res.cloudinary.com/dxra4agvf/image/upload/c_fill,w_auto/f_auto/maincache5" , contentType: "image/png"),
			TypedMetadata.CreativeWork(artist:"Versus", name:"VS", description: "Early adopter tester reward NFT", type:"image"),
			TypedMetadata.Royalties(royalty: { "minter" : adminRoyalty, "artist" : userRoyalty})
		]
		let nft  <- adminClient.mintArtifact(name: "test art0", schemas: schemas)

		cap.borrow()!.deposit(token: <- nft)


	}
}
