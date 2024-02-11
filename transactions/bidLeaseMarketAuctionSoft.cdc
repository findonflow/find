import "FungibleToken"
import "Profile"
import "FTRegistry"
import "FindMarket"
import "FIND"
import "FindLeaseMarket"
import "FindLeaseMarketAuctionSoft"

transaction(leaseName: String, amount: UFix64) {

    let saleItemsCap: Capability<&{FindLeaseMarketAuctionSoft.SaleItemCollectionPublic}>
    let walletReference : auth(FungibleToken.Withdraw) &{FungibleToken.Vault}
    let bidsReference: auth(FindLeaseMarketAuctionSoft.Buyer) &FindLeaseMarketAuctionSoft.MarketBidCollection?
    let balanceBeforeBid: UFix64
    let ftVaultType: Type

    prepare(account: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {

        let resolveAddress = FIND.resolve(leaseName)
        if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(leaseName))}
        let address = resolveAddress!

        let leaseMarketplace = FindMarket.getFindTenantAddress()
        let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
        let leaseTenant = leaseTenantCapability.borrow()!

        let receiverCap=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
        let leaseASBidType= Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>()
        let leaseASBidPublicPath=leaseTenant.getPublicPath(leaseASBidType)
        let leaseASBidStoragePath= leaseTenant.getStoragePath(leaseASBidType)
        let leaseASBidCap= account.capabilities.get<&FindLeaseMarketAuctionSoft.MarketBidCollection>(leaseASBidPublicPath)
        if leaseASBidCap == nil{
            account.storage.save<@FindLeaseMarketAuctionSoft.MarketBidCollection>(<- FindLeaseMarketAuctionSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseASBidStoragePath)
            let leaseBidCap = account.capabilities.storage.issue<&FindLeaseMarketAuctionSoft.MarketBidCollection>(leaseASBidStoragePath)
            account.capabilities.publish(leaseBidCap, at: leaseASBidPublicPath)
        }

        self.saleItemsCap= FindLeaseMarketAuctionSoft.getSaleItemCapability(marketplace:leaseMarketplace, user:address) ?? panic("cannot find sale item cap")
        let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketAuctionSoft.SaleItemCollection>())

        let item = FindLeaseMarket.assertOperationValid(tenant: leaseMarketplace, name: leaseName, marketOption: marketOption)

        let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

        self.walletReference = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account. Account address : ".concat(account.address.toString()))
        self.ftVaultType = ft.type

        let bidStoragePath=leaseTenant.getStoragePath(Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>())

        self.bidsReference= account.storage.borrow<auth(FindLeaseMarketAuctionSoft.Buyer) &FindLeaseMarketAuctionSoft.MarketBidCollection>(from: bidStoragePath)
        self.balanceBeforeBid=self.walletReference.balance
    }

    pre {
        self.bidsReference != nil : "This account does not have a bid collection"
        self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
    }

    execute {
        self.bidsReference!.bid(name:leaseName, amount: amount, vaultType: self.ftVaultType, bidExtraField: {})
    }
}
