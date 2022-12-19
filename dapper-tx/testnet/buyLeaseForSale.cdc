import FindMarket from 0x35717efbbce11c74
import FTRegistry from 0x35717efbbce11c74
import FungibleToken from 0x9a0766d93b6608b7
import FIND from 0x35717efbbce11c74
import FindLeaseMarketSale from 0x35717efbbce11c74
import FindLeaseMarket from 0x35717efbbce11c74

transaction(leaseName: String, amount: UFix64) {

    let to : Address
    let walletReference : &FungibleToken.Vault

    let saleItemsCap: Capability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>
    let mainDapperCoinVault: &FungibleToken.Vault
    let balanceBeforeTransfer: UFix64

    prepare(dapper: AuthAccount, account: AuthAccount) {

        let resolveAddress = FIND.resolve(leaseName)
        if resolveAddress == nil {
            panic("The address input is not a valid name nor address. Input : ".concat(leaseName))
        }
        let address = resolveAddress!
        let leaseMarketplace = FindMarket.getTenantAddress("findLease")!
        let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!

        let leaseSaleItemType= Type<@FindLeaseMarketSale.SaleItemCollection>()
        let leasePublicPath=FindMarket.getPublicPath(leaseSaleItemType, name: "findLease")
        let leaseStoragePath= FindMarket.getStoragePath(leaseSaleItemType, name:"findLease")
        let leaseSaleItemCap= account.getCapability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath) 
        if !leaseSaleItemCap.check() {
            //The link here has to be a capability not a tenant, because it can change.
            account.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
            account.link<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath, target: leaseStoragePath)
        }

        self.saleItemsCap= getAccount(address).getCapability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath) 
        let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketSale.SaleItemCollection>())

        let item= FindLeaseMarket.assertOperationValid(tenant: leaseMarketplace, name: leaseName, marketOption: marketOption)

        let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
    
        self.mainDapperCoinVault = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("Cannot borrow DapperCoin vault from account storage".concat(dapper.address.toString()))
        self.balanceBeforeTransfer = self.mainDapperCoinVault.balance

        self.to= account.address

        self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
    }

    execute {
        let vault <- self.walletReference.withdraw(amount: amount) 
        self.saleItemsCap.borrow()!.buy(name:leaseName, vault: <- vault, to: self.to)
    }

    // Check that all dapper Coin was routed back to Dapper
    post {
        self.mainDapperCoinVault.balance == self.balanceBeforeTransfer: "Dapper Coin leakage"
    }
}
