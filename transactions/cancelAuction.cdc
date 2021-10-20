import FIND from "../contracts/FIND.cdc"

transaction(name: String) {
	prepare(account: AuthAccount) {

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		finLeases.cancel(name)
		finLeases.delistAuction(name)

	}
}
