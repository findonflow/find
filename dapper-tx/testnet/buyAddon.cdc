import DapperUtilityCoin from 0x82ec283f88a62e65
import FIND from 0x35717efbbce11c74


transaction(merchAccount: Address, name: String, addon:String, amount:UFix64) {

    let finLeases : &FIND.LeaseCollection
    let mainDapperUtilityCoinVault: &DapperUtilityCoin.Vault
    let balanceBeforeTransfer: UFix64

    prepare(dapper: auth(BorrowValue)  AuthAccountAccount, account: auth(BorrowValue)  AuthAccountAccount) {
        self.mainDapperUtilityCoinVault = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage".concat(dapper.address.toString()))
        self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.balance
        self.finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath) ?? panic("Could not borrow reference to find lease collection")

    }

    execute {
        let vault <- self.mainDapperUtilityCoinVault.withdraw(amount: amount) as! @DapperUtilityCoin.Vault
        self.finLeases.buyAddonDapper(merchAccount: merchAccount, name: name, addon: addon, vault: <- vault)
    }

    post {
        self.mainDapperUtilityCoinVault.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
    }
}
