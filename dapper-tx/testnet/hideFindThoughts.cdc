import FindThoughts from 0x35717efbbce11c74
import FIND from 0x35717efbbce11c74

transaction(ids: [UInt64], hide: [Bool]) {

    let collection : &FindThoughts.Collection

    prepare(account: auth(BorrowValue)  AuthAccountAccount) {
        self.collection=account.borrow<&FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
    }

    execute {
        for i, id in ids {
            self.collection.hide(id: id, hide: hide[i])
        }

    }
}
