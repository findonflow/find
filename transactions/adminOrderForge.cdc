import "FindForge"
import "Admin"
import "MetadataViews"


transaction(name: String, mintType:String, minterCut: UFix64, collectionDisplay: MetadataViews.NFTCollectionDisplay) {

	let admin : &Admin.AdminProxy

	prepare(account: auth(BorrowValue) &Account) {
        self.admin = account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

	}

	execute {
		var minterCut : UFix64? = minterCut 
		if minterCut == 0.0 {
			minterCut = nil
		}

		self.admin.orderForge(leaseName: name, mintType: mintType, minterCut: minterCut, collectionDisplay: collectionDisplay)
	}
}

