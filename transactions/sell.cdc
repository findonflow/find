import FiNS from "../contracts/FiNS.cdc"

transaction(tag: String, amount: UFix64) {
	prepare(acct: AuthAccount) {

		let finLeases= acct.borrow<&FiNS.LeaseCollection>(from:FiNS.LeaseStoragePath)!
		finLeases.listForSale(tag: tag, amount: amount)

	}
}
