
import "NameVoucher"
import "NonFungibleToken"
import "MetadataViews"
import "LostAndFound"
import "FindLostAndFoundWrapper"

transaction(id: UInt64, name: String) {

    var collection : auth(NameVoucher.Owner) &NameVoucher.Collection
    let addr : Address

    prepare(account: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability) &Account) {

        var col= account.storage.borrow<auth(NameVoucher.Owner) &NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)
        if col == nil {
            account.storage.save( <- NameVoucher.createEmptyCollection(), to: NameVoucher.CollectionStoragePath)
            let cap = account.capabilities.storage.issue<&NameVoucher.Collection>(NameVoucher.CollectionStoragePath)
            account.capabilities.publish(cap, at: NameVoucher.CollectionPublicPath)
            col= account.storage.borrow<auth(NameVoucher.Owner) &NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)
        }
        self.collection = col!
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
