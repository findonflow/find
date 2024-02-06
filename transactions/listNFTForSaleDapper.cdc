import "FindMarket"
import "FindMarketSale"
import "FINDNFTCatalog"
import "FTRegistry"
import "FindViews"
import "NonFungibleToken"
import "MetadataViews"
import "FlowUtilityToken"
import "TokenForwarding"
import "FungibleToken"

transaction(nftAliasOrIdentifier: String, id: UInt64, ftAliasOrIdentifier: String, directSellPrice:UFix64, validUntil: UFix64?) {

    let saleItems : auth(FindMarketSale.Seller) &FindMarketSale.SaleItemCollection?
    let pointer : FindViews.AuthNFTPointer
    let vaultType : Type

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {

        let marketplace = FindMarket.getFindTenantAddress()
        let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
        let tenantCapability= FindMarket.getTenantCapability(marketplace)!

        let tenant = tenantCapability.borrow()!

        //TODO:how do we fix this on testnet/mainnet
        let dapper=getAccount(FindViews.getDapperAddress())

        let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
        let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

        let saleItemCap= account.capabilities.get<&FindMarketSale.SaleItemCollection>(publicPath)
        if saleItemCap==nil {
            account.storage.save(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
            let cap = account.capabilities.storage.issue<&FindMarketSale.SaleItemCollection>(storagePath)
            account.capabilities.publish(cap, at: publicPath)
        }
        // Get supported NFT and FT Information from Registries from input alias
        let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftAliasOrIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifier))
        let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
        let nft = collection.collectionData

        let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

        let futReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        if ft.type == Type<@FlowUtilityToken.Vault>() && !futReceiver!.check() {
            // Create a new Forwarder resource for FUT and store it in the new account's storage
            let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)!)
            account.storage.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)
            let receiverCap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/flowUtilityTokenReceiver)
            account.capabilities.publish(receiverCap, at: /public/flowUtilityTokenReceiver)

            let vaultCap = account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/flowUtilityTokenReceiver)
            account.capabilities.publish(vaultCap, at: /public/flowUtilityTokenVault)
        }

        var providerCap=account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(nft.storagePath)
        // Get the salesItemRef from tenant
        self.saleItems= account.storage.borrow<auth(FindMarketSale.Seller) &FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
        self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
        self.vaultType= ft.type
    }

    pre{
        self.saleItems != nil : "Cannot borrow reference to saleItem"
    }

    execute{
        self.saleItems!.listForSale(pointer: self.pointer, vaultType: self.vaultType, directSellPrice: directSellPrice, validUntil: validUntil, extraField: {})

    }
}
