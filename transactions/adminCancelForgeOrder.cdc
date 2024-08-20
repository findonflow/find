import "FindForge"
import "Admin"
import "MetadataViews"


transaction(name: String, mintType:String) {

	let admin : &Admin.AdminProxy

	prepare(account: auth(BorrowValue) &Account) {
        self.admin = account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

	}

	execute {
		self.admin.cancelForgeOrder(leaseName: name, mintType: mintType)
	}
}

