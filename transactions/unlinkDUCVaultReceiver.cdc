import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"


transaction() {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		account.unlink(/public/dapperUtilityCoinReceiver)
	}
}
