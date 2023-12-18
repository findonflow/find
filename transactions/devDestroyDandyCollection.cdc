import Dandy from "../contracts/Dandy.cdc"


transaction() {
	prepare(account: AuthAccount) {
		destroy account.load<@Dandy.Collection>(from: Dandy.CollectionStoragePath)
	}
}
