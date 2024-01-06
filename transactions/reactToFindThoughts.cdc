import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindThoughts from "../contracts/FindThoughts.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(users: [String], ids: [UInt64] , reactions: [String], undoReactionUsers: [String], undoReactionIds: [UInt64]) {

    let collection : auth(FindThoughts.Owner) &FindThoughts.Collection

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue, UnpublishCapability) &Account) {

        let col= account.storage.borrow<auth(FindThoughts.Owner) &FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath)
        if col == nil {
            account.storage.save( <- FindThoughts.createEmptyCollection(), to: FindThoughts.CollectionStoragePath)
            account.capabilities.unpublish(FindThoughts.CollectionPublicPath)
            let cap = account.capabilities.storage.issue<auth(FindThoughts.Owner) &FindThoughts.Collection>(FindThoughts.CollectionStoragePath)
            account.capabilities.publish(cap, at: FindThoughts.CollectionPublicPath)
            self.collection=account.storage.borrow<auth(FindThoughts.Owner) &FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
        }else {
            self.collection=col!
        }

    }

    execute {
        for i, user in users {
            let address = FIND.resolve(user) ?? panic("Cannot resolve user : ".concat(user))
            self.collection.react(user: address, id: ids[i], reaction: reactions[i])
        }

        for i, user in undoReactionUsers {
            let address = FIND.resolve(user) ?? panic("Cannot resolve user : ".concat(user))
            self.collection.react(user: address, id: undoReactionIds[i], reaction: nil)
        }
    }
}
