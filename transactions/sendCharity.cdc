import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"

//mint an art and add it to a users collection
transaction(
	id: UInt64,
	recipient: Address
) {
	let receiverCap: Capability<&{NonFungibleToken.CollectionPublic}>
	let charityCollection: &NonFungibleToken.Collection

	prepare(account: AuthAccount) {
		self.charityCollection =account.borrow<&NonFungibleToken.Collection>(from: CharityNFT.CollectionStoragePath)!
		self.receiverCap= getAccount(recipient).getCapability<&{NonFungibleToken.CollectionPublic}>(CharityNFT.CollectionPublicPath)
	}

	pre{
		self.receiverCap.check() : "Receiver doesn't have receiving vault set up properly."
	}

	execute {
		let nft <- self.charityCollection.withdraw(withdrawID: id)
		self.receiverCap.borrow()!.deposit(token: <- nft)
	}
}

