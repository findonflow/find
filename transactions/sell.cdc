import FIN from "../contracts/FIN.cdc"

transaction(tag: String, amount: UFix64) {
	prepare(acct: AuthAccount) {

		let finLeases= acct.borrow<&FIN.LeaseCollection>(from:FIN.LeaseStoragePath)!
		finLeases.listForSale(tag: tag, amount: amount)

	}
}
