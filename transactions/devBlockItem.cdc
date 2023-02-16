import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import Dandy from "../contracts/Dandy.cdc"

transaction(tenant: Address){
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        let rules = [
            FindMarket.TenantRule(name:"nft", types:[Type<@Dandy.NFT>()], ruleType:"nft", allow:false)
        ]
        let item = FindMarket.TenantSaleItem(name:"Block Dandy", cut:nil, rules:rules, status:"active")
        adminRef.addFindBlockItem(tenant: tenant, item: item)
    }
}

