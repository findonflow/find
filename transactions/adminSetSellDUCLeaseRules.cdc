import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(tenant: Address) {
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        let rules = [
            FindMarket.TenantRule(name:"DUC", types:[Type<@DapperUtilityCoin.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"Lease", types:[ Type<@FIND.Lease>()], ruleType: "nft", allow: true)
            ]

        let ducExample = FindMarket.TenantSaleItem(name:"DUCLease", cut: nil, rules:rules, status: "active" )

        adminRef.setMarketOption(tenant: tenant, saleItem: ducExample)

    }
}
