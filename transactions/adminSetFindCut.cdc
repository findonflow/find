import "FindMarketAdmin"
import "FindMarket"
import "FlowToken"
import "FUSD"
import "FiatToken"
import "DapperUtilityCoin"
import "FlowUtilityToken"
import "MetadataViews"

transaction(tenant: Address, cut: UFix64){
    prepare(account: auth(BorrowValue) &Account){

        let adminRef = account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        let defaultRules : [FindMarket.TenantRule] = [
        FindMarket.TenantRule(
            name: "standardFT",
            types:[Type<@FlowToken.Vault>(), Type<@FUSD.Vault>(), Type<@FiatToken.Vault>(), Type<@DapperUtilityCoin.Vault>(), Type<@FlowUtilityToken.Vault>()],
            ruleType: "ft",
            allow:true
        )
        ]

        let royalty = MetadataViews.Royalty(
            receiver: adminRef.getSwitchboardReceiverPublic(),
            cut: cut,
            description: "find"
        )

        let saleItem = FindMarket.TenantSaleItem(
            name: "findRoyalty",
            cut: royalty,
            rules: defaultRules,
            status: "active"
        )

        adminRef.setFindCut(tenant: tenant, saleItem:saleItem)
    }
}

