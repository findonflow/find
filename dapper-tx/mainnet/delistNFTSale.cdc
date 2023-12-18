import FindMarket from 0x097bafa4e0b48eef
import FindMarketSale from 0x097bafa4e0b48eef

//Remove one or more listings from a marketplace
transaction(ids: [UInt64]) {

    let saleItems : &FindMarketSale.SaleItemCollection?

    prepare(account: auth(BorrowValue)  AuthAccountAccount) {
        let marketplace = FindMarket.getFindTenantAddress()
        let tenant=FindMarket.getTenant(marketplace)
        self.saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
    }

    pre{
        self.saleItems != nil : "Cannot borrow reference to saleItem"
    }

    execute{
        for id in ids {
            self.saleItems!.delist(id)
        }
    }
}
