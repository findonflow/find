import FindMarket from 0x097bafa4e0b48eef
import FindLeaseMarketSale from 0x097bafa4e0b48eef

transaction(leases: [String]) {
    let saleItems : &FindLeaseMarketSale.SaleItemCollection?

    prepare(account: AuthAccount) {

        let tenant=FindMarket.getTenant(FindMarket.getFindTenantAddress())
        self.saleItems= account.borrow<&FindLeaseMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketSale.SaleItemCollection>()))

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
