import FindMarket from "../contracts/FindMarket.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import Dandy from "../contracts/Dandy.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"


transaction(optionName: String, tenantRuleName: String){
    prepare(account: AuthAccount){
        let path = FindMarket.TenantClientStoragePath
        let tenantRef = account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Reference.")

        tenantRef.removeTenantRule(optionName: optionName, tenantRuleName: tenantRuleName)
    }
}
