import "FindLeaseMarketDirectOfferSoft"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "FindMarket"
import "FindLeaseMarket"
import "FungibleToken"
import "FIND"

transaction(leaseName: String) {

    let market : &FindLeaseMarketDirectOfferSoft.SaleItemCollection
    let pointer : FindLeaseMarket.AuthLeasePointer

    prepare(account: auth(BorrowValue, IssueStorageCapabilityController) &Account) {

        let marketplace = FindMarket.getFindTenantAddress()
        let tenant=FindMarket.getTenant(marketplace)
        let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>())
        self.market = account.storage.borrow<&FindLeaseMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!

        let cap = account.capabilities.storage.issue<auth(FIND.Leasee) &FIND.LeaseCollection>(FIND.LeaseStoragePath)
        self.pointer= FindLeaseMarket.AuthLeasePointer(cap: cap, name: leaseName)

    }

    execute {
        self.market.acceptOffer(self.pointer)
    }

}
