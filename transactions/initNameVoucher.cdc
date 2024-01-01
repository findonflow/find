import NameVoucher from "../contracts/NameVoucher.cdc"

transaction() {
    prepare(account: auth (StorageCapabilities, SaveValue, PublishCapability, BorrowValue) &Account) {
        let col= account.storage.borrow<&NameVoucher.Collection>(from: NameVoucher.CollectionStoragePath)
        if col == nil {
            account.storage.save( <- NameVoucher.createEmptyCollection(), to: NameVoucher.CollectionStoragePath)
            let cap = account.capabilities.storage.issue<&NameVoucher.Collection>(NameVoucher.CollectionStoragePath)
            account.capabilities.publish(cap, at: NameVoucher.CollectionPublicPath)
        }
    }
}
