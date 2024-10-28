import "FindMarket"
import "FindMarketAdmin"
import "FlowToken"
import "Dandy"

transaction(tenant: Address) {
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        let flowDandy = FindMarket.TenantSaleItem(name:"FlowDandy", cut: nil, rules:[
        FindMarket.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
        FindMarket.TenantRule(name:"Dandy", types:[ Type<@Dandy.NFT>()], ruleType: "nft", allow: true)
        ],
        status: "active"
    )

    adminRef.setMarketOption(tenant: tenant, saleItem: flowDandy)

}
}
