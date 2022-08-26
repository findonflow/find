import Bl0x from "../contracts/Bl0x.cdc"
import Bl0xPack from "../contracts/Bl0xPack.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

/// A transaction to open a pack with a given id
/// @param packId: The id of the pack to open
transaction(packId:UInt64) {

	let packs: &Bl0xPack.Collection
	let receiver: Capability<&{NonFungibleToken.Receiver}>

	prepare(account: AuthAccount) {
		self.packs=account.borrow<&Bl0xPack.Collection>(from: Bl0xPack.CollectionStoragePath)!
		self.receiver = account.getCapability<&{NonFungibleToken.Receiver}>(Bl0x.CollectionPublicPath)
	}

	pre {
		self.receiver.check() : "The receiver collection for the packs is not present"
	}
	execute {
		self.packs.open(packId: packId, receiverCap:self.receiver)
	}

	post {
		!self.packs.getIDs().contains(packId) : "The pack is still present in the users collection"
	}
}
