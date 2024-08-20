import "FIND"

transaction(name: String, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64) {

    let finLeases : auth(FIND.LeaseOwner) &FIND.LeaseCollection?

    prepare(acct: auth(BorrowValue) &Account) {
        self.finLeases= acct.storage.borrow<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
    }

    pre{
        self.finLeases != nil : "Cannot borrow reference to find lease collection"
    }

    execute{
        self.finLeases!.listForAuction(name: name, auctionStartPrice: auctionStartPrice, auctionReservePrice: auctionReservePrice, auctionDuration: auctionDuration,  auctionExtensionOnLateBid: auctionExtensionOnLateBid)
    }
}
