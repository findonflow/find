
import Admin from "../contracts/Admin.cdc"
import NameVoucher from "../contracts/NameVoucher.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

transaction(users: [Address], minCharLength: UInt64) {

	prepare(admin:AuthAccount) {

		let client= admin.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		for user in users {
			let cap = getAccount(user).getCapability<&{NonFungibleToken.Receiver}>(NameVoucher.CollectionPublicPath)
			let receiver = cap.borrow() ?? panic(user.toString().concat(" did not setup name voucher collection."))
			client.mintNameVoucher(receiver: receiver, minCharLength: minCharLength)
		}
	}

}
