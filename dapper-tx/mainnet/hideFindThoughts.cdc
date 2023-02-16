import FindThoughts from 0x097bafa4e0b48eef
import FIND from 0x097bafa4e0b48eef

transaction(ids: [UInt64], hide: [Bool]) {

    let collection : &FindThoughts.Collection

    prepare(account: AuthAccount) {
        self.collection=account.borrow<&FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
    }

    execute {
        for i, id in ids {
            self.collection.hide(id: id, hide: hide[i])
        }

    }
}
