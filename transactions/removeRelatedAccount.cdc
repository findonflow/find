import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

transaction(name: String, network: String, address: String) {

    var relatedAccounts : &FindRelatedAccounts.Accounts?

    prepare(account: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, UnpublishCapability, PublishCapability) &Account) {

        self.relatedAccounts= account.storage.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        if self.relatedAccounts == nil {
            let relatedAccounts <- FindRelatedAccounts.createEmptyAccounts()
            account.storage.save(<- relatedAccounts, to: FindRelatedAccounts.storagePath)

            let cap = account.capabilities.storage.issue<&{FindRelatedAccounts.Public}>(FindRelatedAccounts.storagePath)
            account.capabilities.publish(cap, at: FindRelatedAccounts.publicPath)
            self.relatedAccounts = account.storage.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        }

        let cap = account.capabilities.get<&{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath)
        if cap == nil {
            account.capabilities.unpublish(FindRelatedAccounts.publicPath)
            let cap = account.capabilities.storage.issue<&{FindRelatedAccounts.Public}>(FindRelatedAccounts.storagePath)
            account.capabilities.publish(cap, at: FindRelatedAccounts.publicPath)
        }
    }

    execute {
        self.relatedAccounts!.removeRelatedAccount(name:name, network:network, address: address)
    }

}
