import FIND from "../contracts/FIND.cdc"

transaction(tag: String, amount: UFix64) {
	prepare(acct: AuthAccount) {

		let finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		finLeases.listForSale(tag: tag, amount: amount)

	}
}
