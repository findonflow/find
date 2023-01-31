import MetadataViews from 0x1d7e57aa55817448
import FindThoughts from 0x097bafa4e0b48eef
import FIND from 0x097bafa4e0b48eef

transaction(users: [String], ids: [UInt64] , reactions: [String], undoReactionUsers: [String], undoReactionIds: [UInt64]) {

    let collection : &FindThoughts.Collection

    prepare(account: AuthAccount) {
        let thoughtsCap= account.getCapability<&{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath)
        if !thoughtsCap.check() {
            account.save(<- FindThoughts.createEmptyCollection(), to: FindThoughts.CollectionStoragePath)
            account.link<&FindThoughts.Collection{FindThoughts.CollectionPublic , MetadataViews.ResolverCollection}>(
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
