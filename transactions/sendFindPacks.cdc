import FindPack from "../contracts/FindPack.cdc"
import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FindAirdropper from "../contracts/FindAirdropper.cdc"
import Admin from "../contracts/Admin.cdc"

transaction(packInfo: FindPack.AirdropInfo) {

	prepare(account: AuthAccount) {

		let pathIdentifier = "FindPack_".concat(packInfo.packTypeName).concat("_").concat(packInfo.packTypeId.toString())

		let pathCollection = FindPack.getPacksCollection(packTypeName: packInfo.packTypeName, packTypeId: packInfo.packTypeId)
        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

		let ids = pathCollection.getIDs()
		for i, user in packInfo.users {
			let id = ids[i]

			let address = FIND.resolve(user)
			if address == nil {
				panic("User cannot be resolved : ".concat(user))
			}

			let uAccount = getAccount(address!)
			let userPacks=uAccount.getCapability<&FindPack.Collection{NonFungibleToken.Receiver}>(FindPack.CollectionPublicPath).borrow() ?? panic("Could not find userPacks for ".concat(user))
			let pointer = adminRef.getAuthPointer(pathIdentifier: pathIdentifier, id: id)
			FindAirdropper.airdrop(pointer: pointer, receiver: address!, path: FindPack.CollectionPublicPath, context: {"message" : packInfo.message})
		}
	}
}

