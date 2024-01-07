import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, target: String) {

    var relatedAccounts : auth(FindRelatedAccounts.Owner) &FindRelatedAccounts.Accounts?
    let address : Address?

    prepare(account: auth(SaveValue, BorrowValue, PublishCapability, UnpublishCapability,IssueStorageCapabilityController) &Account) {


        self.address = FIND.resolve(target)

        self.relatedAccounts= account.storage.borrow<auth(FindRelatedAccounts.Owner) &FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        if self.relatedAccounts == nil {
            let relatedAccounts <- FindRelatedAccounts.createEmptyAccounts()
            account.storage.save(<- relatedAccounts, to: FindRelatedAccounts.storagePath)

            let cap = account.capabilities.storage.issue<&{FindRelatedAccounts.Public}>(FindRelatedAccounts.storagePath)
            account.capabilities.publish(cap, at: FindRelatedAccounts.publicPath)
            self.relatedAccounts= account.storage.borrow<auth(FindRelatedAccounts.Owner) &FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        }

        let cap = account.capabilities.get<&{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath)
        if cap == nil {
            account.capabilities.unpublish(FindRelatedAccounts.publicPath)
            let cap = account.capabilities.storage.issue<&{FindRelatedAccounts.Public}>(FindRelatedAccounts.storagePath)
            account.capabilities.publish(cap, at: FindRelatedAccounts.publicPath)
        }
    }

    pre{
        self.address != nil : "The input pass in is not a valid name or address. Input : ".concat(target)
    }

    execute{
        self.relatedAccounts!.addFlowAccount(name: name, address: self.address!)
    }
}
