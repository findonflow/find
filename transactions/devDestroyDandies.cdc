import Dandy from "../contracts/Dandy.cdc"


transaction(ids: [UInt64]) {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {

		let dandyRef= account.borrow<&Dandy.Collection>(from: Dandy.CollectionStoragePath) ?? panic("Cannot borrow reference to Dandy Collection")
		for id in ids {
			destroy dandyRef.withdraw(withdrawID: id)
		}
	}
}
