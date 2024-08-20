import "FindMarketAdmin"
import "FindMarket"
import "FlowToken"
import "FUSD"
import "FiatToken"
import "DapperUtilityCoin"
import "FlowUtilityToken"
import "MetadataViews"
import "FungibleToken"

transaction(tenant: String, tenantAddress: Address, findCut: UFix64) {

    prepare(account: auth(BorrowValue) &Account) {
        let adminClient=account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath)!

        // pass in the default cut rules here
        let rules = [
        FindMarket.TenantRule( name:"standard ft", types:[
        Type<@FUSD.Vault>(), 
        Type<@FlowToken.Vault>(), 
        Type<@FiatToken.Vault>(), 
        Type<@DapperUtilityCoin.Vault>() , 
        Type<@FlowUtilityToken.Vault>()], ruleType:"ft", allow:true)
        ]

        let royalty = MetadataViews.Royalty(
            receiver: adminClient.getSwitchboardReceiverPublic(),
            cut: findCut,
            description: "find"
        )

        let saleItem = FindMarket.TenantSaleItem(
            name: "findRoyalty",
            cut: royalty,
            rules : rules,
            status: "active",
        )

        //We create a tenant that has both auctions and direct offers
        let tenantCap= adminClient.createFindMarket(name: tenant, address: tenantAddress, findCutSaleItem: saleItem)

        let tenantAccount=getAccount(tenantAddress)
        let tenantClient=tenantAccount.capabilities.borrow<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath)!
        tenantClient.addCapability(tenantCap)
    }
}

