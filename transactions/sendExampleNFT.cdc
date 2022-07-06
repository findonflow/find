import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"

transaction(user: String, id: UInt64) {
	let address : Address
	let cap : Capability<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>
	let senderRef : &ExampleNFT.Collection

	prepare(account: AuthAccount) {
		self.address = FIND.resolve(user) ?? panic("Cannot find user with this name / address")
		self.cap = getAccount(self.address).getCapability<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>(ExampleNFT.CollectionPublicPath)

		self.senderRef = account.borrow<&ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath) ?? panic("Cannot borrow reference to sender Collection.")
	}

	pre{
		self.cap.check() : "Cannot borrow reference to receiver Collection. Receiver account : ".concat(self.address.toString())
		self.senderRef != nil : "Cannot borrow reference to sender Collection."
	}

	execute{
		self.cap.borrow()!.deposit(token: <- self.senderRef!.withdraw(withdrawID: id))
	}
}
