import Admin from "../contracts/Admin.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"

transaction() {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute{
        let saleItemCollectionTypes: [Type] = [Type<@FindMarketSale.SaleItemCollection>(), 
                                               Type<@FindMarketAuctionSoft.SaleItemCollection>(),
                                               Type<@FindMarketAuctionEscrow.SaleItemCollection>(),
                                               Type<@FindMarketDirectOfferSoft.SaleItemCollection>(),
                                               Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()
                                               ]

        let marketBidCollectionTypes: [Type] = [Type<@FindMarketAuctionSoft.MarketBidCollection>(),
                                               Type<@FindMarketAuctionEscrow.MarketBidCollection>(),
                                               Type<@FindMarketDirectOfferSoft.MarketBidCollection>(),
                                               Type<@FindMarketDirectOfferEscrow.MarketBidCollection>()
                                               ]          
        for type in saleItemCollectionTypes {
            self.adminRef.addSaleItemCollectionType(type)
        }

        for type in marketBidCollectionTypes {
            self.adminRef.addMarketBidCollectionType(type)
        }
    }
}
