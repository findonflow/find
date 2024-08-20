import "FindLeaseMarketDirectOfferSoft"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "FindMarket"
import "FindLeaseMarket"
import "FIND"

transaction(leaseName: String) {

    let market : auth(FindLeaseMarketDirectOfferSoft.Seller) &FindLeaseMarketDirectOfferSoft.SaleItemCollection
    let pointer : FindLeaseMarket.AuthLeasePointer

    prepare(account: auth(Storage, IssueStorageCapabilityController) &Account) {
        let marketplace = FindMarket.getFindTenantAddress()
        let tenant=FindMarket.getTenant(marketplace)
        let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>())
        self.market = account.storage.borrow<auth(FindLeaseMarketDirectOfferSoft.Seller) &FindLeaseMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!


        let storagePathIdentifer = FIND.LeaseStoragePath.toString().split(separator:"/")[1]
        let providerIdentifier = storagePathIdentifer.concat("ProviderFlow")
        let providerStoragePath = StoragePath(identifier: providerIdentifier)!

        var existingProvider= account.storage.copy<Capability<auth(FIND.LeaseOwner) &FIND.LeaseCollection>>(from: providerStoragePath) 
        if existingProvider==nil {
            existingProvider=account.capabilities.storage.issue<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(FIND.LeaseStoragePath) 
            account.storage.save(existingProvider!, to: providerStoragePath)
        }
        var cap = existingProvider!
        self.pointer= FindLeaseMarket.AuthLeasePointer(cap: cap, name: leaseName)


    }

    execute {
        self.market.acceptOffer(self.pointer)
    }
}

