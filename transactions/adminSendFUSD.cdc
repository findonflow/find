import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(receiver: Address, amount:UFix64) {
    prepare(acct: auth(BorrowValue)  AuthAccountAccount) {
        let receiver = getAccount(receiver).getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver).borrow() ?? panic("Cannot borrow FUSD receiver")

        let sender = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault)
            ?? panic("Cannot borrow FUSD vault from authAcct storage")

        receiver.deposit(from: <- sender.withdraw(amount:amount))
    }
}
