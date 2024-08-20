import "FindMarket"
import "FindMarketAdmin"
import "FlowUtilityToken"
import "FUSD"
import "ExampleNFT"

transaction(tenant: Address) {
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        let flowExample = FindMarket.TenantSaleItem(name:"FlowExampleNFT", cut: nil, rules:[
            FindMarket.TenantRule(name:"Fut", types:[Type<@FlowUtilityToken.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"ExampleNFT", types:[ Type<@ExampleNFT.NFT>()], ruleType: "nft", allow: true)
            ],
            status: "active"
        )

        adminRef.setMarketOption(tenant: tenant, saleItem: flowExample)

    }
}
