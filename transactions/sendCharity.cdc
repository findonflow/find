import "NonFungibleToken"
import "CharityNFT"

//mint an art and add it to a users collection
transaction(
	id: UInt64,
	recipient: Address
) {
	let receiverCap: Capability<&{NonFungibleToken.Collection}>
	let charityCollection: &NonFungibleToken.Collection

	prepare(account: auth(BorrowValue) &Account) {
		self.charityCollection =account.storage.borrow<&NonFungibleToken.Collection>(from: CharityNFT.CollectionStoragePath)!
		self.receiverCap= getAccount(recipient).getCapability<&{NonFungibleToken.Collection}>(CharityNFT.CollectionPublicPath)
	}

	pre{
		self.receiverCap.check() : "Receiver doesn't have receiving vault set up properly."
	}

	execute {
		let nft <- self.charityCollection.withdraw(withdrawID: id)
		self.receiverCap.borrow()!.deposit(token: <- nft)
	}
}

