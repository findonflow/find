import FindRelatedAccounts from 0x35717efbbce11c74

transaction(name: String, network: String, address: String){

    var relatedAccounts : &FindRelatedAccounts.Accounts?

    prepare(account: AuthAccount) {

        self.relatedAccounts= account.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        if self.relatedAccounts == nil {
            let relatedAccounts <- FindRelatedAccounts.createEmptyAccounts()
            account.save(<- relatedAccounts, to: FindRelatedAccounts.storagePath)
            account.link<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath, target: FindRelatedAccounts.storagePath)
            self.relatedAccounts= account.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        }

        let cap = account.getCapability<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath)
        if !cap.check() {
            account.unlink(FindRelatedAccounts.publicPath)
            account.link<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath, target: FindRelatedAccounts.storagePath)
        }

    }

    execute{
        self.relatedAccounts!.removeRelatedAccount(name: name, network: network, address: address)
    }
}
