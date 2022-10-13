import RelatedAccounts from 0x097bafa4e0b48eef
import FIND from 0x097bafa4e0b48eef

transaction(name: String, target: String) {

    var relatedAccounts : &RelatedAccounts.Accounts?
    let address : Address?

    prepare(account: AuthAccount) {


        self.address = FIND.resolve(target)

        self.relatedAccounts= account.borrow<&RelatedAccounts.Accounts>(from:RelatedAccounts.storagePath)
        if self.relatedAccounts == nil {
            let relatedAccounts <- RelatedAccounts.createEmptyAccounts()
            account.save(<- relatedAccounts, to: RelatedAccounts.storagePath)
            account.link<&RelatedAccounts.Accounts{RelatedAccounts.Public}>(RelatedAccounts.publicPath, target: RelatedAccounts.storagePath)
            self.relatedAccounts= account.borrow<&RelatedAccounts.Accounts>(from:RelatedAccounts.storagePath)
        }

        let cap = account.getCapability<&RelatedAccounts.Accounts{RelatedAccounts.Public}>(RelatedAccounts.publicPath)
        if !cap.check() {
            account.unlink(RelatedAccounts.publicPath)
            account.link<&RelatedAccounts.Accounts{RelatedAccounts.Public}>(RelatedAccounts.publicPath, target: RelatedAccounts.storagePath)
        }
    }

    pre{
        self.address != nil : "The input pass in is not a valid name or address. Input : ".concat(target)
    }

    execute{
        self.relatedAccounts!.setFlowAccount(name: name, address: self.address!)
    }
}
