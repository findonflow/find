import FindMarket from 0x35717efbbce11c74
import FIND from 0x35717efbbce11c74
import Profile from 0x35717efbbce11c74
import DapperUtilityCoin from 0x82ec283f88a62e65
import FindLeaseMarketSale from 0x35717efbbce11c74
import FindLeaseMarket from 0x35717efbbce11c74

transaction(sellerAccount: Address, leaseName: String, amount: UFix64) {

    let to : Address
    let saleItemsCap: Capability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>
    let mainDapperUtilityCoinVault: &DapperUtilityCoin.Vault
    let balanceBeforeTransfer: UFix64

    prepare(dapper: AuthAccount, account: AuthAccount) {

        let profile=account.borrow<&Profile.User>(from: Profile.storagePath) ?? panic("You do not have a profile set up, initialize the user first")
    
        let address = FIND.resolve(leaseName) ?? panic("The address input is not a valid name nor address. Input : ".concat(leaseName))

        if address != sellerAccount {
            panic("address does not resolve to seller")
        }

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
