import "FindMarket"
import "DapperUtilityCoin"
import "FlowUtilityToken"
import "FungibleToken"
import "FIND"
import "Profile"
import "FindLeaseMarketSale"
import "FindLeaseMarket"

transaction(sellerAccount: Address, leaseName: String, amount: UFix64) {

    let to : Address
    let walletReference : auth(FungibleToken.Withdraw) &{FungibleToken.Vault}

    let saleItemCollection: &{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}
    let balanceBeforeTransfer: UFix64

    prepare(dapper: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account, account: auth(BorrowValue, SaveValue, IssueStorageCapabilityController) &Account) {

        let profile=account.storage.borrow<&Profile.User>(from: Profile.storagePath) ?? panic("You do not have a profile set up, initialize the user first")

        let address = FIND.resolve(leaseName) ?? panic("The address input is not a valid name nor address. Input : ".concat(leaseName))

        if address != sellerAccount {
            panic("address does not resolve to seller")
        }

        let leaseMarketplace = FindMarket.getTenantAddress("find") ?? panic("Cannot find find tenant")
        let saleItemsCap= FindLeaseMarketSale.getSaleItemCapability(marketplace: leaseMarketplace, user:address) ?? panic("cannot find sale item cap for find")

        let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
        let leaseTenant = leaseTenantCapability.borrow()!

        let leaseSaleItemType= Type<@FindLeaseMarketSale.SaleItemCollection>()
        let leasePublicPath=FindMarket.getPublicPath(leaseSaleItemType, name: "find")
        let leaseStoragePath= FindMarket.getStoragePath(leaseSaleItemType, name:"find")
        var leaseSaleItemCap= account.capabilities.get<&{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath)
        if !leaseSaleItemCap.check(){
            //The link here has to be a capability not a tenant, because it can change.
            account.storage.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
            leaseSaleItemCap= account.capabilities.storage.issue<&{FindLeaseMarket.SaleItemCollectionPublic, FindLeaseMarketSale.SaleItemCollectionPublic}>(leaseStoragePath)
        }

        self.to= account.address

        self.saleItemCollection = saleItemsCap.borrow()!
        let item = self.saleItemCollection.borrowSaleItem(leaseName)

        var ftVaultPath : StoragePath? = nil
        switch item.getFtType() {
        case Type<@DapperUtilityCoin.Vault>() :
            ftVaultPath = /storage/dapperUtilityCoinVault

        case Type<@FlowUtilityToken.Vault>() :
            ftVaultPath = /storage/flowUtilityTokenVault

            default :
            panic("This FT is not supported by the Find Market in Dapper Wallet. Type : ".concat(item.getFtType().identifier))
        }


        self.walletReference = dapper.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: ftVaultPath!) ?? panic("No suitable wallet linked for this account")
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
