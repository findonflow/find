import Dandy from "../contracts/Dandy.cdc"


transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		destroy account.load<@Dandy.Collection>(from: Dandy.CollectionStoragePath)
	}
}
