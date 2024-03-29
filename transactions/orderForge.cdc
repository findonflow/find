import FindForge from "../contracts/FindForge.cdc"
import FIND from "../contracts/FIND.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"


transaction(name: String, mintType:String, minterCut: UFix64, collectionDisplay: MetadataViews.NFTCollectionDisplay) {

	let leases : &FIND.LeaseCollection?

	prepare(account: AuthAccount) {

		self.leases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)

	}

	pre{
		self.leases != nil : "Could not borrow reference to the leases collection"
	}

	execute {
		let lease = self.leases!.borrow(name)
		var mintCut : UFix64? = minterCut
		if minterCut == 0.0 {
			mintCut = nil
		} 
		FindForge.orderForge(lease: lease, mintType: mintType, minterCut: mintCut, collectionDisplay: collectionDisplay)
	}
}

