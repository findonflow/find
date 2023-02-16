import FindThoughts from 0x097bafa4e0b48eef

transaction(ids: [UInt64]) {

    let collection : &FindThoughts.Collection

    prepare(account: AuthAccount) {

        self.collection=account.borrow<&FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
    }

    execute {
        for id in ids {
            self.collection.delete(id)
        }
    }
}
