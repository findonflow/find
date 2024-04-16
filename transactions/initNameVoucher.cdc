import "NameVoucher"

transaction() {
    prepare(account: auth (StorageCapabilities, SaveValue, PublishCapability, BorrowValue) &Account) {
        let col= account.storage.borrow<&NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)
        if col == nil {
            account.storage.save( <- NameVoucher.createEmptyCollection(nftType:Type<@NameVoucher.NFT>()), to: NameVoucher.CollectionStoragePath)
            let cap = account.capabilities.storage.issue<&NameVoucher.Collection>(NameVoucher.CollectionStoragePath)
            account.capabilities.publish(cap, at: NameVoucher.CollectionPublicPath)
        }
    }
}
