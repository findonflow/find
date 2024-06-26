import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"

transaction(recipient: Address, amount: UFix64) {
	let tokenAdmin: &FiatToken.Administrator
	let tokenReceiver: &{FungibleToken.Receiver}

	prepare(signer: AuthAccount) {

		self.tokenAdmin = signer.borrow<&FiatToken.Administrator>(from: FiatToken.AdminStoragePath)
		?? panic("Signer is not the token admin")

		self.tokenReceiver = getAccount(recipient)
		.getCapability(FiatToken.VaultReceiverPubPath)
		.borrow<&{FungibleToken.Receiver}>()
		?? panic("Unable to borrow receiver reference")
	}

	execute {
		let minter <- self.tokenAdmin.createNewMinter()
		let mintedVault <- minter.mintTokens(amount: amount)

		self.tokenReceiver.deposit(from: <-mintedVault)

		destroy minter
	}
}
