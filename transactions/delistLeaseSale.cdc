import "FindMarket"
import "FindLeaseMarketSale"

transaction(leases: [String]) {
    let saleItems : auth(FindLeaseMarketSale.Seller) &FindLeaseMarketSale.SaleItemCollection?

    prepare(account: auth(BorrowValue) &Account) {

        let tenant=FindMarket.getTenant(FindMarket.getFindTenantAddress())
        self.saleItems= account.storage.borrow<auth(FindLeaseMarketSale.Seller) &FindLeaseMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketSale.SaleItemCollection>()))

    }

    pre{
        self.saleItems != nil : "Cannot borrow reference to saleItem"
    }

    execute{
        for lease in leases {
            self.saleItems!.delist(lease)
        }
    }
}
