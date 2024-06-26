import FindForge from "../contracts/FindForge.cdc"
import Admin from "../contracts/Admin.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"


transaction(name: String, mintType:String, minterCut: UFix64, collectionDisplay: MetadataViews.NFTCollectionDisplay) {

	let admin : &Admin.AdminProxy

	prepare(account: AuthAccount) {
        self.admin = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

	}

	execute {
		var minterCut : UFix64? = minterCut 
		if minterCut == 0.0 {
			minterCut = nil
		}

		self.admin.orderForge(leaseName: name, mintType: mintType, minterCut: minterCut, collectionDisplay: collectionDisplay)
	}
}

