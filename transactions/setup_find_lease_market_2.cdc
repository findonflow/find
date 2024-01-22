import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

transaction(tenantAddress: Address) {
    prepare(account: auth(BorrowValue) &Account) {
        let adminClient=account.storage.borrow<auth(FindMarketAdmin.Owner) &FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath)!

        let cut = [
        FindMarket.TenantRule( name:"standard ft", types:[Type<@DapperUtilityCoin.Vault>(), Type<@FlowUtilityToken.Vault>()], ruleType:"ft", allow:true)
        ]

        let royalty = MetadataViews.Royalty(
            receiver: adminClient.getSwitchboardReceiverPublic(),
            cut: 0.025,
            description: "find"
        )

        let saleItem = FindMarket.TenantSaleItem(
            name: "findRoyalty",
            cut: royalty,
            rules : cut,
            status: "active",
        )

        //We create a tenant that has both auctions and direct offers
        let tenantCap= adminClient.createFindMarket(name: "find", address: tenantAddress, findCutSaleItem: saleItem)

        let tenantAccount=getAccount(tenantAddress)
        let tenantClient=tenantAccount.capabilities.borrow<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientPublicPath)!
        tenantClient.addCapability(tenantCap)
    }
}

