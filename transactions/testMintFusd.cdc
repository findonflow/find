

import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(recipient: Address, amount: UFix64) {
	let tokenAdmin: &FUSD.Administrator
	let tokenReceiver: &{FungibleToken.Receiver}

	prepare(signer: AuthAccount) {

		self.tokenAdmin = signer
		.borrow<&FUSD.Administrator>(from: /storage/fusdAdmin)
		?? panic("Signer is not the token admin")

		self.tokenReceiver = getAccount(recipient)
		.getCapability(/public/fusdReceiver)
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
