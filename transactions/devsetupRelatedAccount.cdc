import "FindRelatedAccounts"

transaction() {

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {

        let relatedAccounts= account.storage.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        if relatedAccounts == nil {
            let relatedAccounts <- FindRelatedAccounts.createEmptyAccounts()
            account.storage.save(<- relatedAccounts, to: FindRelatedAccounts.storagePath)
            var cap = account.capabilities.storage.issue<&FindRelatedAccounts.Accounts>(FindRelatedAccounts.storagePath)
            account.capabilities.publish(cap, at: FindRelatedAccounts.publicPath)
        }

    }

}
