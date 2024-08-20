import "FindMarketAuctionSoft"
import "NonFungibleToken"
import "FungibleToken"
import "MetadataViews"
import "FindViews"
import "FTRegistry"
import "FINDNFTCatalog"
import "FindMarket"
import "FIND"
import "Profile"

transaction(user: String, id: UInt64, amount: UFix64) {

    let saleItemsCap: Capability<&FindMarketAuctionSoft.SaleItemCollection>
    var targetCapability : Capability<&{NonFungibleToken.Receiver}>
    let walletReference : auth(FungibleToken.Withdraw) &{FungibleToken.Vault}
    let bidsReference: auth(FindMarketAuctionSoft.Buyer) &FindMarketAuctionSoft.MarketBidCollection?
    let balanceBeforeBid: UFix64
    let pointer: FindViews.ViewReadPointer
    let ftVaultType: Type

    prepare(account: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue, UnpublishCapability) &Account) {

        let marketplace = FindMarket.getFindTenantAddress()
        let resolveAddress = FIND.resolve(user)
        if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(user))}
        let address = resolveAddress!

        let tenantCapability= FindMarket.getTenantCapability(marketplace)!
        let tenant = tenantCapability.borrow()!

        let receiverCap=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
        let asBidType= Type<@FindMarketAuctionSoft.MarketBidCollection>()
        let asBidPublicPath=FindMarket.getPublicPath(asBidType, name: tenant.name)
        let asBidStoragePath= FindMarket.getStoragePath(asBidType, name:tenant.name)
        let asBidCap= account.capabilities.get<&FindMarketAuctionSoft.MarketBidCollection>(asBidPublicPath)
        if !asBidCap.check() {
            account.storage.save<@FindMarketAuctionSoft.MarketBidCollection>(<- FindMarketAuctionSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: asBidStoragePath)
            let cap = account.capabilities.storage.issue<&FindMarketAuctionSoft.MarketBidCollection>(asBidStoragePath)
            account.capabilities.publish(cap, at: asBidPublicPath)
        }

        self.saleItemsCap= FindMarketAuctionSoft.getSaleItemCapability(marketplace:marketplace, user:address) ?? panic("cannot find sale item cap")
        let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionSoft.SaleItemCollection>())

        let item = FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: id)

        let nftIdentifier = item.getItemType().identifier
        let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
        let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
        let nft = collection.collectionData

        let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

        let col= account.storage.borrow<&AnyResource>(from: nft.storagePath) as? &{NonFungibleToken.Collection}?
        if col == nil {
            let cd = item.getNFTCollectionData()
            account.storage.save(<- cd.createEmptyCollection(), to: cd.storagePath)
            account.capabilities.unpublish(cd.publicPath)
            let cap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath)
            account.capabilities.publish(cap, at: cd.publicPath)
            self.targetCapability=cap
        } else {
            //TODO: I do not think this works as intended
            var targetCapability= account.capabilities.get<&{NonFungibleToken.Collection}>(nft.publicPath) 
            if !targetCapability.check() {
                let cd = item.getNFTCollectionData()
                let cap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath)
                account.capabilities.unpublish(cd.publicPath)
                account.capabilities.publish(cap, at: cd.publicPath)
                targetCapability= account.capabilities.get<&{NonFungibleToken.Collection}>(nft.publicPath)
            }
            self.targetCapability=targetCapability
        }

        self.walletReference = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account. Account address : ".concat(account.address.toString()))
        self.ftVaultType = ft.type

        let bidStoragePath=tenant.getStoragePath(Type<@FindMarketAuctionSoft.MarketBidCollection>())

        self.bidsReference= account.storage.borrow<auth(FindMarketAuctionSoft.Buyer) &FindMarketAuctionSoft.MarketBidCollection>(from: bidStoragePath)
        self.balanceBeforeBid=self.walletReference.balance
        self.pointer= FindViews.createViewReadPointer(address: address, path:nft.publicPath, id: item.getItemID())
    }

    pre {
        self.bidsReference != nil : "This account does not have a bid collection"
        self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
    }

    execute {
        self.bidsReference!.bid(item:self.pointer, amount: amount, vaultType: self.ftVaultType, nftCap: self.targetCapability, bidExtraField: {})
    }
}
