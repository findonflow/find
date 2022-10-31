import FindPack from "../contracts/FindPack.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

transaction(users: [Address]) {

	prepare(account: AuthAccount) {

		let packTypeName = "partyfavorz"
		let packTypeId = 2

		let pathIdentifier = "FindPack_".concat(packTypeName).concat("_").concat(packTypeId.toString())
		let storagePath = StoragePath(identifier: pathIdentifier) ?? panic("Cannot create path from identifier : ".concat(pathIdentifier))

		let pathCollection = account.borrow<&FindPack.Collection>(from: storagePath)!

		let ids = pathCollection.getIDs()
		for i, user in users {
			let id = ids[i]!

			let uAccount = getAccount(user)
			let userPacks=uAccount.getCapability<&FindPack.Collection{NonFungibleToken.Receiver}>(FindPack.CollectionPublicPath).borrow() ?? panic("Could not find userPacks for account".concat(user.toString()))
			userPacks.deposit(token: <- pathCollection.withdraw(withdrawID: id))
		}
	}
}
