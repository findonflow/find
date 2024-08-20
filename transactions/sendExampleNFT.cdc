import "FIND"
import "NonFungibleToken"
import "ExampleNFT"

transaction(user: String, id: UInt64) {
	let address : Address
	let cap : Capability<&ExampleNFT.Collection{NonFungibleToken.Collection}>
	let senderRef : &ExampleNFT.Collection

	prepare(account: auth(BorrowValue) &Account) {
		self.address = FIND.resolve(user) ?? panic("Cannot find user with this name / address")
		self.cap = getAccount(self.address).getCapability<&ExampleNFT.Collection{NonFungibleToken.Collection}>(ExampleNFT.CollectionPublicPath)

		self.senderRef = account.storage.borrow<&ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath) ?? panic("Cannot borrow reference to sender Collection.")
	}

	pre{
		self.cap.check() : "Cannot borrow reference to receiver Collection. Receiver account : ".concat(self.address.toString())
		self.senderRef != nil : "Cannot borrow reference to sender Collection."
	}

	execute{
		self.cap.borrow()!.deposit(token: <- self.senderRef!.withdraw(withdrawID: id))
	}
}
