import "WearablesDev"

transaction(receiver: Address,) {
	prepare(account: auth(BorrowValue) &Account) {
		WearablesDev.mintWearablesForTest(receiver: receiver)
	}
}
