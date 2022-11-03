import FindThoughts from "../contracts/FindThoughts.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(users: [String], ids: [UInt64] , reactions: [String], undoReactionUsers: [String], undoReactionIds: [UInt64]) {

	let collection : &FindThoughts.Collection

	prepare(account: AuthAccount) {

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
