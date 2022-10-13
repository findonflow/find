import FindMarket from 0x097bafa4e0b48eef
import FIND from 0x097bafa4e0b48eef
import Profile from 0x097bafa4e0b48eef
import DapperUtilityCoin from 0xead892083b3e2c6c
import FindLeaseMarketSale from 0x097bafa4e0b48eef
import FindLeaseMarket from 0x097bafa4e0b48eef

//TODO: test, and rename to Dapper, repeat for other tx
transaction(leaseName: String, amount: UFix64) {

    let to : Address
    let saleItemsCap: Capability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>
    let mainDapperUtilityCoinVault: &DapperUtilityCoin.Vault
    let balanceBeforeTransfer: UFix64

    prepare(dapper: AuthAccount, account: AuthAccount) {

        let profile=account.borrow<&Profile.User>(from: Profile.storagePath) ?? panic("You do not have a profile set up, initialize the user first")
    
        let address = FIND.resolve(leaseName) ?? panic("The address input is not a valid name nor address. Input : ".concat(leaseName))
        let leaseMarketplace = FindMarket.getTenantAddress("findLease") ?? panic("Cannot find findLease tenant")
        self.saleItemsCap= FindLeaseMarketSale.getSaleItemCapability(marketplace: leaseMarketplace, user:address) ?? panic("cannot find sale item cap for findLease")

        self.mainDapperUtilityCoinVault = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage".concat(dapper.address.toString()))
        self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.balance
        self.to= account.address
    }

    execute {
        let vault <- self.mainDapperUtilityCoinVault.withdraw(amount: amount) 
        self.saleItemsCap.borrow()!.buy(name:leaseName, vault: <- vault, to: self.to)
    }

    // Check that all dapperUtilityCoin was routed back to Dapper
    post {
        self.mainDapperUtilityCoinVault.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
    }
}
