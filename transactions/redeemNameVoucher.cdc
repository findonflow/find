
import NameVoucher from "../contracts/NameVoucher.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import LostAndFound from "../contracts/standard/LostAndFound.cdc"
import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"

transaction(id: UInt64, name: String) {

	var collection : &NameVoucher.Collection
	let addr : Address

	prepare(account:AuthAccount) {

		var nameVoucherRef= account.borrow<&NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)
		if nameVoucherRef == nil {
			account.save<@NonFungibleToken.Collection>(<- NameVoucher.createEmptyCollection(), to: NameVoucher.CollectionStoragePath)
			account.unlink(NameVoucher.CollectionPublicPath)
			account.link<&NameVoucher.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NameVoucher.CollectionPublicPath,
				target: NameVoucher.CollectionStoragePath
			)
			account.unlink(NameVoucher.CollectionPrivatePath)
			account.link<&NameVoucher.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NameVoucher.CollectionPrivatePath,
				target: NameVoucher.CollectionStoragePath
			)
			nameVoucherRef= account.borrow<&NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)
		}


		let nameVoucherCap= account.getCapability<&NameVoucher.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(NameVoucher.CollectionPublicPath)
		if !nameVoucherCap.check() {
			account.unlink(NameVoucher.CollectionPublicPath)
			account.link<&NameVoucher.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NameVoucher.CollectionPublicPath,
				target: NameVoucher.CollectionStoragePath
			)
		}

		let nameVoucherProviderCap= account.getCapability<&NameVoucher.Collection{NonFungibleToken.Provider,NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(NameVoucher.CollectionPrivatePath)
		if !nameVoucherProviderCap.check() {
			account.unlink(NameVoucher.CollectionPrivatePath)
			account.link<&NameVoucher.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				NameVoucher.CollectionPrivatePath,
				target: NameVoucher.CollectionStoragePath
			)
		}
		self.collection = nameVoucherRef!
		self.addr = account.address
	}

	execute{
		// check if it is there in collection
		if self.collection.contains(id) {
			self.collection.redeem(id: id, name: name)
			return
		}

		// check if it is there on L&F
		let tickets = LostAndFound.borrowAllTicketsByType(addr: self.addr, type: Type<@NameVoucher.NFT>())
		for ticket in tickets {
			if ticket.uuid == id {
				let tokenId = ticket.getNonFungibleTokenID()!
				FindLostAndFoundWrapper.redeemNFT(type: Type<@NameVoucher.NFT>(), ticketID: id, receiverAddress: self.addr, collectionPublicPath: NameVoucher.CollectionPublicPath)

				self.collection.redeem(id: tokenId, name: name)
				return
			}
		}

		panic("There is no ID or Ticket ID : ".concat(id.toString()))
	}

}
