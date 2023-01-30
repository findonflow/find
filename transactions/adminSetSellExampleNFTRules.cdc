import FindMarket from "../contracts/FindMarket.cdc"
import Admin from "../contracts/Admin.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(tenant: Address, merchAddress: Address) {
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        let rules = [
            FindMarket.TenantRule(name:"DUC", types:[Type<@DapperUtilityCoin.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"ExampleNFT", types:[ Type<@ExampleNFT.NFT>()], ruleType: "nft", allow: true)
            ]

        let ducExample = FindMarket.TenantSaleItem(name:"DUCExampleNFT", cut: nil, rules:rules, status: "active" )

        adminRef.setMarketOption(tenant: tenant, saleItem: ducExample)

        let exampleNFTRules = [
            FindMarket.TenantRule(name:"Flow", types:[Type<@FlowToken.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"ExampleNFT", types:[ Type<@ExampleNFT.NFT>()], ruleType: "nft", allow: true)
            ]

        let flowExample = FindMarket.TenantSaleItem(name:"FlowExampleNFT", cut: nil, rules:exampleNFTRules, status: "active" )

        adminRef.setMarketOption(tenant: tenant, saleItem: flowExample)

        let cap = getAccount(merchAddress).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        adminRef.addFindCut(tenant: tenant, FindCutName: "findDapperRoyalty", rayalty: MetadataViews.Royalty(receiver: cap, cut: 0.025, description: "find"), rules: rules, status: "active")

    }
}
