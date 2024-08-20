import "FindMarket"
import "FindMarketAuctionSoft"

transaction(ids: [UInt64]) {

    let saleItems : auth(FindMarketAuctionSoft.Seller) &FindMarketAuctionSoft.SaleItemCollection?

    prepare(account: auth(BorrowValue) &Account) {
        let marketplace = FindMarket.getFindTenantAddress()
        let tenant=FindMarket.getTenant(marketplace)
        self.saleItems= account.storage.borrow<auth(FindMarketAuctionSoft.Seller) &FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>()))
    }

    pre{
        self.saleItems != nil
    }

    execute{
        for id in ids {
            self.saleItems!.cancel(id)
        }
    }

}
