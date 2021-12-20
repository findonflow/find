import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"
import Admin from "../contracts/Admin.cdc"


//mint an art and add it to a users collection
transaction(
	name: String,
	image: String,
	recipient: Address
) {
	let receiverCap: Capability<&{NonFungibleToken.CollectionPublic}>
	let client: &Admin.AdminProxy

	prepare(account: AuthAccount) {
		self.client= account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
		self.receiverCap= getAccount(recipient).getCapability<&{NonFungibleToken.CollectionPublic}>(CharityNFT.CollectionPublicPath)
	}

	execute {
		let metadata = {"name" : name, "image" : image}
		self.client.mintCharity(metadata: metadata, recipient: self.receiverCap)
	}
}

