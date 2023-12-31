import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

transaction(name: String, network: String, oldAddress:String, address: String) {

    var relatedAccounts : &FindRelatedAccounts.Accounts?

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue, IssueStorageCapabilityController) &Account) {

        let relatedAccounts= account.storage.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        if relatedAccounts == nil {
            let relatedAccounts <- FindRelatedAccounts.createEmptyAccounts()
            account.storage.save(<- relatedAccounts, to: FindRelatedAccounts.storagePath)
            var cap = account.capabilities.storage.issue<&FindRelatedAccounts.Accounts>(FindRelatedAccounts.storagePath)
            account.capabilities.publish(cap, at: FindRelatedAccounts.publicPath)
            self.relatedAccounts = account.storage.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        }else {
            self.relatedAccounts=relatedAccounts
        }

    }

    execute {
        self.relatedAccounts!.updateRelatedAccount(name:name, network:network, oldAddress: oldAddress, address: address)
    }

}
