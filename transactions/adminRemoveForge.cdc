
import Admin from "../contracts/Admin.cdc"

transaction(type: String) {

	prepare(admin:AuthAccount) {

		let client= admin.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		client.removeForgeType(CompositeType(type)!)

	}

}
