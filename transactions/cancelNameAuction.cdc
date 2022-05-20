import FIND from "../contracts/FIND.cdc"

transaction(names: [String]) {
	prepare(account: AuthAccount) {

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		for name in names {
			finLeases.cancel(name)
			finLeases.delistAuction(name)
		}
	}
}
