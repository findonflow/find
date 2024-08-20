import "FindForge"
import "FIND"
import "MetadataViews"


transaction(name: String, mintType:String, minterCut: UFix64, collectionDisplay: MetadataViews.NFTCollectionDisplay) {

	let leases : &FIND.LeaseCollection?

	prepare(account: auth(BorrowValue) &Account) {

		self.leases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)

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

