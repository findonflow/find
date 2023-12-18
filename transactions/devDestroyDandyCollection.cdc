import Dandy from "../contracts/Dandy.cdc"


transaction() {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		destroy account.load<@Dandy.Collection>(from: Dandy.CollectionStoragePath)
	}
}
