// This transaction withdraws FUSD from the signer's account and deposits it into a recipient account. 
// This transaction will fail if the recipient does not have an FUSD receiver. 
// No funds are transferred or lost if the transaction fails.
//
// Parameters:
// - amount: The amount of FUSD to transfer (e.g. 10.0)
// - to: The recipient account address.
//
// This transaction will fail if either the sender or recipient does not have
// an FUSD vault stored in their account. To check if an account has a vault
// or initialize a new vault, use check_fusd_vault_setup.cdc and setup_fusd_vault.cdc
// respectively.

import FungibleToken from 0x9a0766d93b6608b7
import FUSD from 0xe223d8a629e49c68

transaction(amount: UFix64, to: Address) {

    // The Vaut resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {
        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&FUSD.Vault>(from: /storage/fusdVault)
            ?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
        // Get the recipient's public account object
        let recipient = getAccount(to)

        // Get a reference to the recipient's Receiver
        let receiverRef = recipient.getCapability(/public/fusdReceiver)!.borrow<&{FungibleToken.Receiver}>()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")

        // Deposit the withdrawn tokens in the recipient's receiver
        receiverRef.deposit(from: <-self.sentVault)
    }
}
