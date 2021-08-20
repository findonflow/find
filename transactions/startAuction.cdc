import FIN from "../contracts/FIN.cdc"

transaction(tag: String) {
	prepare(account: AuthAccount) {

		let finLeases= account.borrow<&FIN.LeaseCollection>(from:FIN.LeaseStoragePath)!
		finLeases.startAuction(tag)

	}
}
