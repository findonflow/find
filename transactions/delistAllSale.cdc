import FIND from "../contracts/FIND.cdc"

transaction() {
	prepare(acct: AuthAccount) {
		let finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		let leases = finLeases.getLeaseInformation()
		for lease in leases {
			if lease.salePrice != nil {
				finLeases.delistSale(lease.name)
			}
		}
	}
}