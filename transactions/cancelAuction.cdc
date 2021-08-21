import FiNS from "../contracts/FiNS.cdc"

transaction(tag: String) {
	prepare(account: AuthAccount) {

		let finLeases= account.borrow<&FiNS.LeaseCollection>(from:FiNS.LeaseStoragePath)!
		finLeases.cancel(tag)

	}
}
