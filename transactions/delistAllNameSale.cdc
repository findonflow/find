import FIND from "../contracts/FIND.cdc"

transaction() {

	let finLeases : &FIND.LeaseCollection?

	prepare(acct: AuthAccount) {
		self.finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)

	}

	pre{
		self.finLeases != nil : "Cannot borrow reference to find lease collection"
	}

	execute{
		let leases = self.finLeases!.getLeaseInformation()
		for lease in leases {
			if lease.salePrice != nil {
				self.finLeases!.delistSale(lease.name)
			}
		}
	}
}