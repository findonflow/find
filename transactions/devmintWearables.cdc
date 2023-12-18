import WearablesDev from "../contracts/community/WearablesDev.cdc"

transaction(receiver: Address,) {
	prepare(account: auth(BorrowValue) &Account) {
		WearablesDev.mintWearablesForTest(receiver: receiver)
	}
}
