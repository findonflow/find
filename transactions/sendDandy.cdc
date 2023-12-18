import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Dandy from "../contracts/Dandy.cdc"

transaction(user: String, id: UInt64) {

	let address : Address
	let cap : Capability<&Dandy.Collection{NonFungibleToken.Collection}>
	let senderRef : &Dandy.Collection

	prepare(account: auth(BorrowValue) &Account) {
		self.address = FIND.resolve(user) ?? panic("Cannot find user with this name / address")
		self.cap = getAccount(self.address).getCapability<&Dandy.Collection{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)

		self.senderRef = account.borrow<&Dandy.Collection>(from: Dandy.CollectionStoragePath) ?? panic("Cannot borrow reference to sender Collection.")
	}

	pre{
		self.cap.check() : "Cannot borrow reference to receiver Collection. Receiver account : ".concat(self.address.toString())
		self.senderRef != nil : "Cannot borrow reference to sender Collection."
	}

	execute{
		self.cap.borrow()!.deposit(token: <- self.senderRef!.withdraw(withdrawID: id))
	}
}
