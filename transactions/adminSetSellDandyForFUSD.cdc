import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Dandy from "../contracts/Dandy.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"


transaction(tenant: Address, market: String){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        var marketType : [Type] = [Type<@FindMarketSale.SaleItem>()]
        switch market {
            case "AuctionEscrow" :
                marketType = [Type<@FindMarketAuctionEscrow.SaleItem>()]

            case "AuctionSoft" :
                marketType = [Type<@FindMarketAuctionSoft.SaleItem>()]

            case "DirectOfferEscrow" :
                marketType = [Type<@FindMarketDirectOfferEscrow.SaleItem>()]

            case "DirectOfferSoft" :
                marketType = [Type<@FindMarketDirectOfferSoft.SaleItem>()]

        }

        let saleItem = FindMarket.TenantSaleItem(name:"FlowDandy".concat(market), cut: nil, rules:[
            FindMarket.TenantRule(name:"Flow", types:[Type<@FUSD.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Dandy", types:[Type<@Dandy.NFT>()], ruleType: "nft", allow: true),
            FindMarket.TenantRule(name: market, types:marketType, ruleType: "listing", allow: true)
            ],
            status: "active"
        )

        adminRef.setMarketOption(tenant: tenant, saleItem: saleItem)
    }
}

