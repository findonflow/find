import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

transaction(nftAliasOrIdentifier:String, id: UInt64, ftAliasOrIdentifier:String, price:UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64, auctionStartTime: UFix64?, auctionValidUntil: UFix64?) {

    let saleItems : &FindMarketAuctionEscrow.SaleItemCollection?
    let vaultType : Type
    let pointer : FindViews.AuthNFTPointer

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue, NonFungibleToken.Withdrawable) &Account) {
        let marketplace = FindMarket.getFindTenantAddress()
        let tenantCapability= FindMarket.getTenantCapability(marketplace)!
        let tenant = tenantCapability.borrow()!
        let path=FindMarket.getStoragePath(Type<@FindMarketAuctionEscrow.SaleItemCollection>(), name: tenant.name)

        /// auctions that escrow ft
        let aeSaleType= Type<@FindMarketAuctionEscrow.SaleItemCollection>()
        let aeSalePublicPath=FindMarket.getPublicPath(aeSaleType, name: tenant.name)
        let aeSaleStoragePath= FindMarket.getStoragePath(aeSaleType, name:tenant.name)
        let aeSaleCap= account.capabilities.get<&{FindMarketAuctionEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(aeSalePublicPath)
        if aeSaleCap==nil {
            account.storage.save<@FindMarketAuctionEscrow.SaleItemCollection>(<- FindMarketAuctionEscrow.createEmptySaleItemCollection(tenantCapability), to: aeSaleStoragePath)

            let cap = account.capabilities.storage.issue<&{FindMarketAuctionEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(aeSaleStoragePath)
            account.capabilities.publish(cap, at: aeSalePublicPath)
        }

        // Get supported NFT and FT Information from Registries from input alias
        let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftAliasOrIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifier))
        let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
        let nft = collection.collectionData

        let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))


        var providerCap=account.capabilities.storage.issue<auth(NonFungibleToken.Withdrawable) &{NonFungibleToken.Collection}>(nft.storagePath)

        self.saleItems= account.storage.borrow<&FindMarketAuctionEscrow.SaleItemCollection>(from: path)
        self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
        self.vaultType= ft.type
    }

    pre{
        // Ben : panic on some unreasonable inputs in trxn
        minimumBidIncrement > 0.0 : "Minimum bid increment should be larger than 0."
        (auctionReservePrice - auctionReservePrice) % minimumBidIncrement == 0.0 : "Acution ReservePrice should be in step of minimum bid increment."
        auctionDuration > 0.0 : "Auction Duration should be greater than 0."
        auctionExtensionOnLateBid > 0.0 : "Auction Duration should be greater than 0."
        self.saleItems != nil : "Cannot borrow reference to saleItem"
    }

    execute {
        self.saleItems!.listForAuction(pointer: self.pointer, vaultType: self.vaultType, auctionStartPrice: price, auctionReservePrice: auctionReservePrice, auctionDuration: auctionDuration, auctionExtensionOnLateBid: auctionExtensionOnLateBid, minimumBidIncrement: minimumBidIncrement, auctionStartTime: auctionStartTime, auctionValidUntil:auctionValidUntil, saleItemExtraField: {})
    }
}
