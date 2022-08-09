
import FindForge from "../contracts/FindForge.cdc"
import Admin from "../contracts/Admin.cdc"

transaction(storagePath: StoragePath, name: String) {

	prepare(provider: AuthAccount, admin:AuthAccount) {

		let forge <- provider.load<@{FindForge.Forge}>(from: storagePath)!

		let client= admin.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		client.addPrivateForgeType(name: name, forge: <- forge)

	}

}
