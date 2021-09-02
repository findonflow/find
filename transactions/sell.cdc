import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {
	prepare(acct: AuthAccount) {

		let finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		finLeases.listForSale(name: name, amount: amount)

	}
}
