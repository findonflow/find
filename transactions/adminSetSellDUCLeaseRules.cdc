import "FindMarket"
import "FindMarketAdmin"
import "DapperUtilityCoin"
import "MetadataViews"
import "FungibleToken"
import "FIND"

transaction(tenant: Address) {
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        let rules = [
            FindMarket.TenantRule(name:"DUC", types:[Type<@DapperUtilityCoin.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Lease", types:[ Type<@FIND.Lease>()], ruleType: "nft", allow: true)
            ]

        let ducExample = FindMarket.TenantSaleItem(name:"DUCLease", cut: nil, rules:rules, status: "active" )

        adminRef.setMarketOption(tenant: tenant, saleItem: ducExample)

    }
}
