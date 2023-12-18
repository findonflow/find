import MetadataViews from 0x631e88ae7f1d7c20
import FindThoughts from 0x35717efbbce11c74
import FIND from 0x35717efbbce11c74

transaction(users: [String], ids: [UInt64] , reactions: [String], undoReactionUsers: [String], undoReactionIds: [UInt64]) {

    let collection : &FindThoughts.Collection

    prepare(account: auth(BorrowValue)  AuthAccountAccount) {
        let thoughtsCap= account.getCapability<&{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath)
        if !thoughtsCap.check() {
            account.save(<- FindThoughts.createEmptyCollection(), to: FindThoughts.CollectionStoragePath)
            account.link<&FindThoughts.Collection{FindThoughts.CollectionPublic , ViewResolver.ResolverCollection}>(
                FindThoughts.CollectionPublicPath,
                target: FindThoughts.CollectionStoragePath
            )
        }
        self.collection=account.borrow<&FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
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
