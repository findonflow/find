import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import Dandy from "../contracts/Dandy.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
import Admin from "../contracts/Admin.cdc"
>>>>>>> Stashed changes
=======
import Admin from "../contracts/Admin.cdc"
>>>>>>> Stashed changes


transaction(market: String){
    prepare(account: AuthAccount){
<<<<<<< Updated upstream
<<<<<<< Updated upstream
        let path = FindMarketTenant.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarketTenant.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")
=======
        let adminProxyRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Proxy Reference.")
>>>>>>> Stashed changes
=======
        let adminProxyRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Proxy Reference.")
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
<<<<<<< Updated upstream
        tenantRef.setMarketOption(name:"FlowDandy".concat(market), cut: nil, rules:[
=======
        adminProxyRef.setTenantMarketOption(tenantName: "find", name:"FlowDandy".concat(market), cut: nil, rules:[
>>>>>>> Stashed changes
=======
        adminProxyRef.setTenantMarketOption(tenantName: "find", name:"FlowDandy".concat(market), cut: nil, rules:[
>>>>>>> Stashed changes
            FindMarketTenant.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
            FindMarketTenant.TenantRule(name:"Dandy", types:[Type<@Dandy.NFT>()], ruleType: "nft", allow: true),
            FindMarketTenant.TenantRule(name: market, types:marketType, ruleType: "listing", allow: true)
            ]
        )
    }
}
