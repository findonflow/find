import "FungibleToken"
import "FUSD"

transaction(recipient: Address, amount: UFix64) {
    let tokenAdmin: &FUSD.Minter
    let tokenReceiver: &{FungibleToken.Receiver}

    prepare(signer: auth (BorrowValue) &Account) {

        self.tokenAdmin = signer.storage.borrow<&FUSD.Minter>(from: FUSD.AdminStoragePath) ?? panic("Signer is not the token admin")

        self.tokenReceiver = getAccount(recipient).capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)!.borrow() ?? panic("Unable to borrow receiver reference")
    }

    execute {

        let mintedVault <- self.tokenAdmin.mintTokens(amount: amount)

        self.tokenReceiver.deposit(from: <-mintedVault)
    }
}
