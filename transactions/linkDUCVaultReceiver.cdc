import "TokenForwarding"
import "FungibleToken"


transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		account.unlink(/public/dapperUtilityCoinReceiver)
		account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinVault)
	}
}
