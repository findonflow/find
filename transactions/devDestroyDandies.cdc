import "Dandy"
import "NonFungibleToken"


transaction(ids: [UInt64]) {
    prepare(account: auth(BorrowValue, NonFungibleToken.Withdraw) &Account) {

        let dandyRef= account.storage.borrow<auth(NonFungibleToken.Withdraw) &Dandy.Collection>(from: Dandy.CollectionStoragePath) ?? panic("Cannot borrow reference to Dandy Collection")
        for id in ids {
            destroy dandyRef.withdraw(withdrawID: id)
        }
    }
}
