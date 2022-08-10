
import Admin from "../contracts/Admin.cdc"

transaction(name: String, type: String) {

	prepare(admin:AuthAccount) {

		let client= admin.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		client.addPrivateForgeType(name: name, forgeType: CompositeType(type)!)

	}

}
