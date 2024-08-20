import "FungibleToken"
import "FUSD"

transaction(receiver: Address, amount:UFix64) {
    prepare(acct: auth(BorrowValue) &Account) {
        let receiver = getAccount(receiver).getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver).borrow() ?? panic("Cannot borrow FUSD receiver")

        let sender = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault)
            ?? panic("Cannot borrow FUSD vault from authAcct storage")

        receiver.deposit(from: <- sender.withdraw(amount:amount))
    }
}
