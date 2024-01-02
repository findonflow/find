import FindMarket from "../contracts/FindMarket.cdc"
//import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
//import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
//import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
//import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"

transaction(ids: {String : [UInt64]}) {
    prepare(account: auth(BorrowValue) &Account) {

        let marketplace = FindMarket.getFindTenantAddress()
        let tenant=FindMarket.getTenant(marketplace)

        /*
        var saleType = Type<@FindMarketAuctionEscrow.SaleItemCollection>()
        if let ids = ids[FindMarket.getMarketOptionFromType(saleType)] {
            let saleItems= account.storage.borrow<&FindMarketAuctionEscrow.SaleItemCollection>(from: tenant.getStoragePath(saleType))!
            for id in ids {
                saleItems.relist(id)
            }
        }

        saleType = Type<@FindMarketAuctionSoft.SaleItemCollection>()
        if let ids = ids[FindMarket.getMarketOptionFromType(saleType)] {
            let saleItems= account.storage.borrow<&FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(saleType))!
            for id in ids {
                saleItems.relist(id)
            }
        }
        */

        var saleType = Type<@FindMarketSale.SaleItemCollection>()
        if let ids = ids[FindMarket.getMarketOptionFromType(saleType)] {
            let saleItems= account.storage.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(saleType))!
            for id in ids {
                saleItems.relist(id)
            }
        }

    }
}
