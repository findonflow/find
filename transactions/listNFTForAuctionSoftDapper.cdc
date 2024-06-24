import "FindMarket"
import "FindMarketAuctionSoft"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "FINDNFTCatalog"
import "FTRegistry"

transaction(nftAliasOrIdentifier:String, id: UInt64, ftAliasOrIdentifier:String, price:UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64, auctionValidUntil: UFix64?) {

    let saleItems : auth(FindMarketAuctionSoft.Seller) &FindMarketAuctionSoft.SaleItemCollection?
    let pointer : FindViews.AuthNFTPointer
    let vaultType : Type

    prepare(account: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {
        let marketplace = FindMarket.getFindTenantAddress()
        let tenantCapability= FindMarket.getTenantCapability(marketplace)!
        let tenant = tenantCapability.borrow()!

        /// auctions that refers FT so 'soft' auction
        let asSaleType= Type<@FindMarketAuctionSoft.SaleItemCollection>()
        let asSalePublicPath=FindMarket.getPublicPath(asSaleType, name: tenant.name)
        let asSaleStoragePath= FindMarket.getStoragePath(asSaleType, name:tenant.name)
        let asSaleCap= account.capabilities.get<&FindMarketAuctionSoft.SaleItemCollection>(asSalePublicPath)
        if !asSaleCap.check() {
            account.storage.save<@FindMarketAuctionSoft.SaleItemCollection>(<- FindMarketAuctionSoft.createEmptySaleItemCollection(tenantCapability), to: asSaleStoragePath)
            let saleColCap = account.capabilities.storage.issue<&FindMarketAuctionSoft.SaleItemCollection>(asSaleStoragePath)
            account.capabilities.publish(saleColCap, at: asSalePublicPath)
        }

        // Get supported NFT and FT Information from Registries from input alias
        let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftAliasOrIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifier))
        let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
        let nft = collection.collectionData

        let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

        var providerCap = account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(nft.storagePath)

        self.saleItems= account.storage.borrow<auth(FindMarketAuctionSoft.Seller) &FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>()))
        self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
        self.vaultType= ft.type
    }

    pre{
        // Ben : panic on some unreasonable inputs in trxn
        minimumBidIncrement > 0.0 :"Minimum bid increment should be larger than 0."
        (auctionReservePrice - auctionReservePrice) % minimumBidIncrement == 0.0 : "Acution ReservePrice should be in step of minimum bid increment."
        auctionDuration > 0.0 : "Auction Duration should be greater than 0."
        auctionExtensionOnLateBid > 0.0 : "Auction Duration should be greater than 0."
        self.saleItems != nil : "Cannot borrow reference to saleItem"
    }

    execute{
        self.saleItems!.listForAuction(pointer: self.pointer, vaultType: self.vaultType, auctionStartPrice: price, auctionReservePrice: auctionReservePrice, auctionDuration: auctionDuration, auctionExtensionOnLateBid: auctionExtensionOnLateBid, minimumBidIncrement: minimumBidIncrement, auctionValidUntil: auctionValidUntil, saleItemExtraField: {})
    }
}
