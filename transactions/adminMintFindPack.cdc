import FindPack from "../contracts/FindPack.cdc"
import Admin from "../contracts/Admin.cdc"

transaction(packTypeName: String, typeId: UInt64, hashes: [String]) {
	let admin: &Admin.AdminProxy
	prepare(account: auth(BorrowValue) &Account) {
		self.admin =account.storage.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Could not borrow admin")
	}

	execute {
		for hash in hashes {
			self.admin.mintFindPack(packTypeName: packTypeName, typeId:typeId,hash: hash)
		}
	}
}
