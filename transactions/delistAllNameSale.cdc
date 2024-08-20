import "FIND"

transaction() {

	let finLeases : auth(FIND.LeaseOwner) &FIND.LeaseCollection?

	prepare(acct: auth(BorrowValue) &Account) {
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
