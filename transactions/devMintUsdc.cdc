import "FungibleToken"
import "FiatToken"

transaction(recipient: Address, amount: UFix64) {
    let tokenAdmin: &FiatToken.Administrator
    let tokenReceiver: &{FungibleToken.Receiver}

    prepare(signer: auth(BorrowValue) &Account) {

        self.tokenAdmin = signer.storage.borrow<&FiatToken.Administrator>(from: FiatToken.AdminStoragePath) ?? panic("Signer is not the token admin")

        self.tokenReceiver = getAccount(recipient).capabilities.borrow<&{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath) ?? panic("Unable to borrow receiver reference")
    }

    execute {
        let minter <- self.tokenAdmin.createNewMinter()
        let mintedVault <- minter.mintTokens(amount: amount)

        self.tokenReceiver.deposit(from: <-mintedVault)

        destroy minter
    }
}
