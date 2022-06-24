import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Dandy from "../contracts/Dandy.cdc"

transaction(user: String, id: UInt64) {
	prepare(account: AuthAccount) {
		let address = FIND.resolve(user) ?? panic("Cannot find user with this name / address")
		let cap = getAccount(address).getCapability<&Dandy.Collection{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
		let ref = cap.borrow() ?? panic("Cannot borrow reference to receiver Collection. Receiver account : ".concat(address.toString()))

		let senderRef = account.borrow<&Dandy.Collection>(from: Dandy.CollectionStoragePath) ?? panic("Cannot borrow reference to sender Collection.")
		ref.deposit(token: <- senderRef.withdraw(withdrawID: id))
	}
}
