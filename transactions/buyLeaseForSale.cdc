import "FindMarket"
import "FTRegistry"
import "FungibleToken"
import "FIND"
import "Profile"
import "FindLeaseMarketSale"
import "FindLeaseMarket"

transaction(leaseName: String, amount: UFix64) {

    let buyer : Address
    let walletReference : auth(FungibleToken.Withdraw) &{FungibleToken.Vault}

    let saleItemCollection: &{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}

    prepare(account: auth(BorrowValue, SaveValue, IssueStorageCapabilityController) &Account) {

        let profile=account.storage.borrow<&Profile.User>(from: Profile.storagePath) ?? panic("You do not have a profile set up, initialize the user first")

        let address = FIND.resolve(leaseName) ?? panic("The address input is not a valid name nor address. Input : ".concat(leaseName))

        if address == nil {
            panic("The address input is not a valid name nor address. Input : ".concat(leaseName))
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

        self.saleItemCollection = saleItemsCap.borrow()!
        let item = self.saleItemCollection.borrowSaleItem(leaseName)

        let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))


        self.walletReference = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
        self.buyer = account.address
    }

    pre {
        self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
    }

    execute {
        let vault <- self.walletReference.withdraw(amount: amount)
        self.saleItemCollection.buy(name:leaseName, vault: <- vault, to: self.buyer)
    }
}
