import "FindMarketAdmin"
import "FindMarket"
import "Dandy"

transaction(tenant: Address){
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        let rules = [
            FindMarket.TenantRule(name:"nft", types:[Type<@Dandy.NFT>()], ruleType:"nft", allow:false)
        ]
        let item = FindMarket.TenantSaleItem(name:"Block Dandy", cut:nil, rules:rules, status:"active")
        adminRef.addFindBlockItem(tenant: tenant, item: item)
    }
}

