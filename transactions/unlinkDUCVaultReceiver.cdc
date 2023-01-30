import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"


transaction() {
	prepare(account: AuthAccount) {
		account.unlink(/public/dapperUtilityCoinReceiver)
	}
}
