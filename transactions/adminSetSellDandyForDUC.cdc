import FindMarket from "../contracts/FindMarket.cdc"
import Admin from "../contracts/Admin.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import Dandy from "../contracts/Dandy.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketAuctionIOUEscrowed from "../contracts/FindMarketAuctionIOUEscrowed.cdc"
import FindMarketAuctionIOUDapper from "../contracts/FindMarketAuctionIOUDapper.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"


transaction(tenant: Address, market: String){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        var marketType : [Type] = [Type<@FindMarketSale.SaleItem>()]
        switch market {
            case "AuctionEscrow" :
                marketType = [Type<@FindMarketAuctionEscrow.SaleItem>()]

            case "AuctionSoft" :
                marketType = [Type<@FindMarketAuctionSoft.SaleItem>()]

            case "AuctionIOUEscrowed" :
                marketType = [Type<@FindMarketAuctionIOUEscrowed.SaleItem>()]

            case "AuctionIOUDapper" :
                marketType = [Type<@FindMarketAuctionIOUDapper.SaleItem>()]

                // If it is with Dapper, have to set Find Cuts for Dapper Coins 
                let rules = [
                    FindMarket.TenantRule(name:"DUC", types:[Type<@DapperUtilityCoin.Vault>(), Type<@FlowUtilityToken.Vault>()], ruleType: "ft", allow: true),
                    FindMarket.TenantRule(name:"ExampleNFT", types:[ Type<@Dandy.NFT>()], ruleType: "nft", allow: true)
                    ]
                let cap = getAccount(tenant).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
                adminRef.addFindCut(tenant: tenant, FindCutName: "findDapperRoyalty", rayalty: MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find"), rules: rules, status: "active")

            case "DirectOfferEscrow" :
                marketType = [Type<@FindMarketDirectOfferEscrow.SaleItem>()]

            case "DirectOfferSoft" :
                marketType = [Type<@FindMarketDirectOfferSoft.SaleItem>()]
        }

        let saleItem = FindMarket.TenantSaleItem(name:"FlowDandy".concat(market), cut: nil, rules:[
            FindMarket.TenantRule(name:"DUC", types:[Type<@DapperUtilityCoin.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Dandy", types:[Type<@Dandy.NFT>()], ruleType: "nft", allow: true),
            FindMarket.TenantRule(name: market, types:marketType, ruleType: "listing", allow: true)
            ], 
            status: "active"
        )

        adminRef.setMarketOption(tenant: tenant, saleItem: saleItem)
    }
}

