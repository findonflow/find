import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"


transaction() {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		account.unlink(/public/dapperUtilityCoinReceiver)
		account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinVault)
	}
}
