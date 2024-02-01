import Dandy from "../contracts/Dandy.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"


transaction(ids: [UInt64]) {
    prepare(account: auth(BorrowValue, NonFungibleToken.Withdraw) &Account) {

        let dandyRef= account.storage.borrow<auth(NonFungibleToken.Withdraw) &Dandy.Collection>(from: Dandy.CollectionStoragePath) ?? panic("Cannot borrow reference to Dandy Collection")
        for id in ids {
            destroy dandyRef.withdraw(withdrawID: id)
        }
    }
}
