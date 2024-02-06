import "TokenForwarding"


transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		account.unlink(/public/dapperUtilityCoinReceiver)
	}
}
