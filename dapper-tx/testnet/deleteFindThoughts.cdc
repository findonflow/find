import FindThoughts from 0x35717efbbce11c74

transaction(ids: [UInt64]) {

    let collection : &FindThoughts.Collection

    prepare(account: auth(BorrowValue) &Account) {

        self.collection=account.borrow<&FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
    }

    execute {
        for id in ids {
            self.collection.delete(id)
        }
    }
}
