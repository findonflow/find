
import Admin from "../contracts/Admin.cdc"

transaction(mintType: String) {

	prepare(admin:AuthAccount) {

		let client= admin.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		client.addForgeMintType(mintType)

	}

}
