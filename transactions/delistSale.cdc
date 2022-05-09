import FIND from "../contracts/FIND.cdc"

transaction(names: [String]) {
	prepare(acct: AuthAccount) {
		let finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		for name in names {
			finLeases.delistSale(name)
		}
	}
}
