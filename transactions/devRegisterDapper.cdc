import "DapperUtilityCoin"
import "FIND"
import "FungibleToken"
import "Profile"

transaction(merchAccount: Address, name: String, amount: UFix64) {

    let finLeases : auth(FIND.LeaseOwner) &FIND.LeaseCollection?
    let mainDapperUtilityCoinVault: auth(FungibleToken.Withdraw) &DapperUtilityCoin.Vault
    let balanceBeforeTransfer: UFix64
    let price : UFix64

    prepare(dapper: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account, account: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {

        self.price=FIND.calculateCost(name)
        log("The cost for registering this name is ".concat(self.price.toString()))
        self.mainDapperUtilityCoinVault = dapper.storage.borrow<auth(FungibleToken.Withdraw) &DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage".concat(dapper.address.toString()))
        self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.balance
        var finLeasesRef = account.storage.borrow<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
        if finLeasesRef == nil {
            account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
            let cap = account.capabilities.storage.issue<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(FIND.LeaseStoragePath)
            account.capabilities.publish(cap, at: FIND.LeasePublicPath)
            finLeasesRef = cap.borrow()
        }
        self.finLeases = finLeasesRef!
    }

    pre{


        merchAccount ==  0x179b6b1cb6755e31 : "Merchant accuont is not .find"
        self.price == amount : "Calculated cost : ".concat(self.price.toString()).concat(" does not match expected cost : ").concat(amount.toString())
    }

    execute{
        let payVault <- self.mainDapperUtilityCoinVault.withdraw(amount: self.price)
        self.finLeases!.registerDapper(merchAccount: merchAccount, name: name, vault: <- payVault)
    }

    post {
        self.mainDapperUtilityCoinVault.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
    }
}
