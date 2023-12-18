import WearablesDev from "../contracts/community/WearablesDev.cdc"

transaction(receiver: Address,) {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		WearablesDev.mintWearablesForTest(receiver: receiver)
	}
}
