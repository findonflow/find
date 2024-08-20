import "FungibleToken"
import "Sender"
import "FIND"
import "FTRegistry"


transaction(name: String, amount: UFix64, ftAliasOrIdentifier: String, tag: String, message:String) {

    var token : &Sender.Token
    let walletReference : auth(FungibleToken.Withdraw) &{FungibleToken.Vault}? 

    prepare(account: auth(BorrowValue, SaveValue) &Account) {

        let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))
        self.walletReference = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: ft.vaultPath)

        if account.storage.borrow<&Sender.Token>(from: Sender.storagePath) == nil {
            account.storage.save(<- Sender.createToken(), to: Sender.storagePath)
        }

        self.token =account.storage.borrow<&Sender.Token>(from: Sender.storagePath)!
    }

    pre{
        self.walletReference != nil : "No suitable wallet linked for this account"
    }

    execute{
        let vault <- self.walletReference!.withdraw(amount: amount)
        FIND.depositWithTagAndMessage(to: name, message: message, tag: tag, vault: <- vault, from: self.token)
    }
}
