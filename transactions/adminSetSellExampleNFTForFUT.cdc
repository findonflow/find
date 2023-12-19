import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"

transaction(tenant: Address) {
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.storage.borrow<&FindMarketAdmin.AdminProxy>(from: FindMarketAdmin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        let flowExample = FindMarket.TenantSaleItem(name:"FlowExampleNFT", cut: nil, rules:[
            FindMarket.TenantRule(name:"Fut", types:[Type<@FlowUtilityToken.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"ExampleNFT", types:[ Type<@ExampleNFT.NFT>()], ruleType: "nft", allow: true)
            ],
            status: "active"
        )

        adminRef.setMarketOption(tenant: tenant, saleItem: flowExample)

    }
}
