import FindMarket from 0x35717efbbce11c74
import FTRegistry from 0x35717efbbce11c74
import FungibleToken from 0x9a0766d93b6608b7
import FIND from 0x35717efbbce11c74
import Profile from 0x35717efbbce11c74
import FindLeaseMarketSale from 0x35717efbbce11c74
import FindLeaseMarket from 0x35717efbbce11c74

transaction(sellerAccount: Address, leaseName: String, amount: UFix64) {

    let to : Address
    let walletReference : &FungibleToken.Vault

    let saleItemCollection: &FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}
    let balanceBeforeTransfer: UFix64

    prepare(dapper: AuthAccount, account: AuthAccount) {

        let profile=account.borrow<&Profile.User>(from: Profile.storagePath) ?? panic("You do not have a profile set up, initialize the user first")

        let address = FIND.resolve(leaseName) ?? panic("The address input is not a valid name nor address. Input : ".concat(leaseName))

        if address != sellerAccount {
            panic("address does not resolve to seller")
        }

        let leaseMarketplace = FindMarket.getTenantAddress("findLease") ?? panic("Cannot find findLease tenant")
        let saleItemsCap= FindLeaseMarketSale.getSaleItemCapability(marketplace: leaseMarketplace, user:address) ?? panic("cannot find sale item cap for findLease")

        self.to= account.address

        self.saleItemCollection = saleItemsCap.borrow()!
        let item = self.saleItemCollection.borrowSaleItem(leaseName)
        let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
        self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
        self.balanceBeforeTransfer = self.walletReference.balance
    }

    execute {
        let vault <- self.walletReference.withdraw(amount: amount)
        self.saleItemCollection.buy(name:leaseName, vault: <- vault, to: self.to)
    }

    // Check that all dapper Coin was routed back to Dapper
    post {
        self.walletReference.balance == self.balanceBeforeTransfer: "Dapper Coin leakage"
    }
}
