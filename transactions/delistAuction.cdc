import FIND from "../contracts/FIND.cdc"

transaction(name: String) {
	prepare(acct: AuthAccount) {
		let finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		finLeases.delistAuction(name)
	}
}
