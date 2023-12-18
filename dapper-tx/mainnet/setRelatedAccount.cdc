import FindRelatedAccounts from 0x097bafa4e0b48eef
import FIND from 0x097bafa4e0b48eef

transaction(name: String, target: String) {

    var relatedAccounts : &FindRelatedAccounts.Accounts?
    let address : Address?

    prepare(account: auth(BorrowValue) &Account) {


        self.address = FIND.resolve(target)

        self.relatedAccounts= account.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        if self.relatedAccounts == nil {
            let relatedAccounts <- FindRelatedAccounts.createEmptyAccounts()
            account.storage.save(<- relatedAccounts, to: FindRelatedAccounts.storagePath)
            account.link<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath, target: FindRelatedAccounts.storagePath)
            self.relatedAccounts= account.borrow<&FindRelatedAccounts.Accounts>(from:FindRelatedAccounts.storagePath)
        }

        let cap = account.getCapability<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath)
        if !cap.check() {
            account.unlink(FindRelatedAccounts.publicPath)
            account.link<&FindRelatedAccounts.Accounts{FindRelatedAccounts.Public}>(FindRelatedAccounts.publicPath, target: FindRelatedAccounts.storagePath)
        }
    }

    pre{
        self.address != nil : "The input pass in is not a valid name or address. Input : ".concat(target)
    }

    execute{
        self.relatedAccounts!.addFlowAccount(name: name, address: self.address!)
    }
}
