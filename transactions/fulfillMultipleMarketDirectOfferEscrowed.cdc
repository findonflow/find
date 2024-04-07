import "FindMarketDirectOfferEscrow"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "NFTCatalog"
import "FINDNFTCatalog"
import "FindMarket"

transaction(ids: [UInt64]) {

    let market : &FindMarketDirectOfferEscrow.SaleItemCollection?
    let pointer : [FindViews.AuthNFTPointer]

    prepare(account: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {

        let marketplace = FindMarket.getFindTenantAddress()
        let tenant=FindMarket.getTenant(marketplace)
        let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())
        let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())
        self.market = account.storage.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: storagePath)
        self.pointer = []

        let nfts : {String : NFTCatalog.NFTCollectionData} = {}
        var counter = 0
        while counter < ids.length {
            let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: ids[counter])

            var nft : NFTCatalog.NFTCollectionData? = nil
            let nftIdentifier = item.getItemType().identifier

            if nfts[nftIdentifier] != nil {
                nft = nfts[nftIdentifier]
            } else {
                let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier))
                let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
                nft = collection.collectionData
                nfts[nftIdentifier] = nft
            }

            let storagePathIdentifer = nft.storagePath.toString().split(separator:"/")[1]
            let providerIdentifier = storagePathIdentifer.concat("Provider")
            let providerStoragePath = StoragePath(identifier: providerIdentifier)!

            //if this stores anything but this it will panic, why does it not return nil?
            var existingProvider= account.storage.copy<Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>>(from: providerStoragePath) 
            if existingProvider==nil {
                existingProvider=account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(collectionData.storagePath)
                //we save it to storage to memoize it
                account.storage.save(existingProvider!, to: providerStoragePath)
                log("create new cap")
            }
            var providerCap = existingProvider!

            let pointer= FindViews.AuthNFTPointer(cap: providerCap, id: item.getItemID())
            self.pointer.append(pointer)
            counter = counter + 1
        }

    }

    pre{
        self.market != nil : "Cannot borrow reference to saleItem"
    }

    execute{
        var counter = 0
        while counter < ids.length {
            self.market!.acceptDirectOffer(self.pointer[counter])
            counter = counter + 1
        }
    }
}
