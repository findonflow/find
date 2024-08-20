import "FindMarket"
import "FindMarketAuctionSoft"

transaction() {

    let saleItems : auth(FindMarketAuctionSoft.Seller) &FindMarketAuctionSoft.SaleItemCollection?

    prepare(account: auth(BorrowValue) &Account) {
        let marketplace = FindMarket.getFindTenantAddress()
        let tenant = FindMarket.getTenant(marketplace)
        self.saleItems= account.storage.borrow<auth(FindMarketAuctionSoft.Seller) &FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>()))

    }

    pre{
        self.saleItems != nil : "Cannot borrow reference to the saleItem."
    }

    execute {
        let ids = self.saleItems!.getIds()
        for id in ids {
            self.saleItems!.cancel(id)
        }
    }
}
