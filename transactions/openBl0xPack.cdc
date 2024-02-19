import "Bl0x"
import "Bl0xPack"
import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"

/// A transaction to open a pack with a given id
/// @param packId: The id of the pack to open
transaction(packId:UInt64) {

	let packs: &Bl0xPack.Collection
	var receiver: Capability<&{NonFungibleToken.Receiver}>?

	prepare(account: auth(BorrowValue) &Account) {
		self.packs=account.storage.borrow<&Bl0xPack.Collection>(from: Bl0xPack.CollectionStoragePath)!
		self.receiver = account.capabilities.get<&{NonFungibleToken.Receiver}>(Bl0x.CollectionPublicPath)
		if self.receiver == nil {
			account.storage.save<@{NonFungibleToken.Collection}>(<- Bl0x.createEmptyCollection(), to: Bl0x.CollectionStoragePath)
			let cap = account.capabilities.storage.issue<&Bl0x.Collection>(
				Bl0x.CollectionStoragePath,
			)
			account.capabilities.publish(cap, at: Bl0x.CollectionPublicPath)
			self.receiver = account.capabilities.get<&{NonFungibleToken.Receiver}>(Bl0x.CollectionPublicPath)
		}

	}
	pre {
		self.receiver!.check() : "The receiver collection for the packs is not set up properly"
	}
	execute {
		self.packs.open(packId: packId, receiverCap: self.receiver!)
	}
	post {
		!self.packs.getIDs().contains(packId) : "The pack is still present in the users collection"
	}
}
