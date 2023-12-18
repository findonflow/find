import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"


transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		account.unlink(/public/dapperUtilityCoinReceiver)
		account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinVault)
	}
}
