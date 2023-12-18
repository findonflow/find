// Mainnet
import FungibleToken from 0xf233dcee88fe0abe
import FUSD from 0x3c5959b568896393

// Testnet
// import FungibleToken from 0x9a0766d93b6608b7
// import FUSD from 0xe223d8a629e49c68

transaction() {

	// The Vault resource that holds the tokens that are being transfered
	let sentVault: @FungibleToken.Vault

	prepare(signer: auth(BorrowValue)  AuthAccountAccount) {
		// Get a reference to the signer's stored vault
		let vaultRef = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
		?? panic("Could not borrow reference to the owner's Vault!")

		// Withdraw tokens from the signer's stored vault
		self.sentVault <- vaultRef.withdraw(amount: vaultRef.balance)
	}

	execute {

		let recipient: Address = 0x936851d3e331acd4
		// Get the recipient's public account object
		let recipientAccount = getAccount(recipient)

		// Get a reference to the recipient's Receiver
		let receiverRef = recipientAccount.getCapability(/public/fusdReceiver)!.borrow<&{FungibleToken.Receiver}>()
		?? panic("Could not borrow receiver reference to the recipient's Vault")

		// Deposit the withdrawn tokens in the recipient's receiver
		receiverRef.deposit(from: <-self.sentVault)
	}
}
