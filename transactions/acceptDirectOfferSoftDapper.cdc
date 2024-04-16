import "FindMarketDirectOfferSoft"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "NFTCatalog"
import "FINDNFTCatalog"
import "FindMarket"
import "FungibleToken"
import "ViewResolver"

transaction(id: UInt64) {

    let market : auth(FindMarketDirectOfferSoft.Seller) &FindMarketDirectOfferSoft.SaleItemCollection
    let pointer : FindViews.AuthNFTPointer

    prepare(account: auth(Storage, BorrowValue, IssueStorageCapabilityController) &Account) {

        let marketplace = FindMarket.getFindTenantAddress()
        let tenant=FindMarket.getTenant(marketplace)
        let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
        self.market = account.storage.borrow<auth(FindMarketDirectOfferSoft.Seller) &FindMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
        let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())
        let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)
        let nftIdentifier = item.getItemType().identifier

        let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
        let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
        let nft = collection.collectionData



        let storagePathIdentifer = nft.storagePath.toString().split(separator:"/")[1]
        let providerIdentifier = storagePathIdentifer.concat("Provider")
        let providerStoragePath = StoragePath(identifier: providerIdentifier)!

        //if this stores anything but this it will panic, why does it not return nil?
        var existingProvider= account.storage.copy<Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>>(from: providerStoragePath) 
        if existingProvider==nil {
            existingProvider=account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(nft.storagePath)
            //we save it to storage to memoize it
            account.storage.save(existingProvider!, to: providerStoragePath)
            log("create new cap")
        }
        var providerCap = existingProvider!

        self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())

    }

    execute {
        self.market.acceptOffer(self.pointer)
    }

}
