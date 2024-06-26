import DapperUtilityCoin from 0xead892083b3e2c6c
import FIND from 0x097bafa4e0b48eef

transaction(merchAccount: Address, name: String, amount: UFix64) {

    let finLeases : &FIND.LeaseCollection
    let mainDapperUtilityCoinVault: &DapperUtilityCoin.Vault
    let balanceBeforeTransfer: UFix64
    let price : UFix64

    prepare(dapper: AuthAccount, account: AuthAccount) {

        self.price=FIND.calculateCost(name)
        log("The cost for registering this name is ".concat(self.price.toString()))
        self.mainDapperUtilityCoinVault = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage".concat(dapper.address.toString()))
        self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.balance
        self.finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath) ?? panic("Could not borrow reference to find lease collection")
    }

    pre{
        self.price == amount : "Calculated cost : ".concat(self.price.toString()).concat(" does not match expected cost : ").concat(amount.toString())
        merchAccount == 0x55459409d30274ee : "Merchant account is not .find"
    }

    execute{
        let payVault <- self.mainDapperUtilityCoinVault.withdraw(amount: self.price) as! @DapperUtilityCoin.Vault
        self.finLeases.registerDapper(merchAccount: merchAccount, name: name, vault: <- payVault)
    }

    post {
        self.mainDapperUtilityCoinVault.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
    }
}
