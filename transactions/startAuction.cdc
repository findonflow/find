import FIND from "../contracts/FIND.cdc"

transaction(tag: String) {
	prepare(account: AuthAccount) {

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		finLeases.startAuction(tag)

	}
}
