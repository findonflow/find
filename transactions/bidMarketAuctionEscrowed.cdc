import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(user: String, id: UInt64, amount: UFix64) {

    let saleItemsCap: Capability<&{FindMarketAuctionEscrow.SaleItemCollectionPublic}>
    var targetCapability : Capability<&{NonFungibleToken.Receiver}>
    let walletReference : auth(FungibleToken.Withdrawable) &{FungibleToken.Vault}
    let bidsReference: &FindMarketAuctionEscrow.MarketBidCollection?
    let balanceBeforeBid: UFix64
    let pointer: FindViews.ViewReadPointer

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue, NonFungibleToken.Withdrawable) &Account) {

        let marketplace = FindMarket.getFindTenantAddress()
        let resolveAddress = FIND.resolve(user)
        if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(user))}
        let address = resolveAddress!

        let tenantCapability= FindMarket.getTenantCapability(marketplace)!
        let tenant = tenantCapability.borrow()!
        let receiverCap=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
        /// auctions that escrow ft
        let aeBidType= Type<@FindMarketAuctionEscrow.MarketBidCollection>()

        let aeBidPublicPath=FindMarket.getPublicPath(aeBidType, name: tenant.name)
        let aeBidStoragePath= FindMarket.getStoragePath(aeBidType, name:tenant.name)

        let aeBidCap= account.capabilities.get<&{FindMarketAuctionEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(aeBidPublicPath)
        if aeBidCap==nil{
            account.storage.save<@FindMarketAuctionEscrow.MarketBidCollection>(<- FindMarketAuctionEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: aeBidStoragePath)
            let cap = account.capabilities.storage.issue<&{FindMarketAuctionEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(aeBidStoragePath)
            account.capabilities.publish(cap, at: aeBidPublicPath)
        }

        self.saleItemsCap= FindMarketAuctionEscrow.getSaleItemCapability(marketplace:marketplace, user:address) ?? panic("cannot find sale item cap. User address : ".concat(address.toString()))

        let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionEscrow.SaleItemCollection>())
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
            let cap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath)
            account.capabilities.publish(cap, at: cd.publicPath)
            self.targetCapability=cap
        } else {
            //TODO: I do not think this works as intended, this works as intended
            var targetCapability= account.capabilities.get<&{NonFungibleToken.Collection}>(nft.publicPath)
            if targetCapability == nil || !targetCapability!.check() {
                let cd = item.getNFTCollectionData()
                let cap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(cd.storagePath)
                account.capabilities.publish(cap, at: cd.publicPath)
                targetCapability= account.capabilities.get<&{NonFungibleToken.Collection}>(nft.publicPath)
            }
            self.targetCapability=targetCapability!
        }

        self.walletReference = account.storage.borrow<auth(FungibleToken.Withdrawable) &{FungibleToken.Vault}>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
        let bidSstoragePath=tenant.getStoragePath(Type<@FindMarketAuctionEscrow.MarketBidCollection>())

        self.bidsReference= account.storage.borrow<&FindMarketAuctionEscrow.MarketBidCollection>(from: bidSstoragePath)
        self.balanceBeforeBid=self.walletReference.getBalance()
        self.pointer= FindViews.createViewReadPointer(address: address, path:nft.publicPath, id: item.getItemID())
    }

    pre {
        self.bidsReference != nil : "This account does not have a bid collection"
        self.walletReference.getBalance() > amount : "Your wallet does not have enough funds to pay for this item"
    }

    execute {
        let vault <- self.walletReference.withdraw(amount: amount)
        self.bidsReference!.bid(item:self.pointer, vault: <- vault, nftCap: self.targetCapability, bidExtraField: {})
    }

}
