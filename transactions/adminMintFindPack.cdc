import "FindPack"
import "Admin"

transaction(packTypeName: String, typeId: UInt64, hashes: [String]) {
	let admin: auth(Admin.Owner) &Admin.AdminProxy
	prepare(account: auth(BorrowValue) &Account) {
		self.admin =account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Could not borrow admin")
	}

	execute {
		for hash in hashes {
			self.admin.mintFindPack(packTypeName: packTypeName, typeId:typeId,hash: hash)
		}
	}
}
