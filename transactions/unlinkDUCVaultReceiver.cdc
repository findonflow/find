import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"


transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		account.unlink(/public/dapperUtilityCoinReceiver)
	}
}
