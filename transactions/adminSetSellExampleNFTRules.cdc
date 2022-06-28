import FindMarket from "../contracts/FindMarket.cdc"
import Admin from "../contracts/Admin.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(tenant: Address) {
    prepare(account: AuthAccount){
        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        let rules = [
            FindMarket.TenantRule(name:"DUC", types:[Type<@DapperUtilityCoin.Vault>()], ruleType: "ft", allow: true),
            FindMarket.TenantRule(name:"ExampleNFT", types:[ Type<@ExampleNFT.NFT>()], ruleType: "nft", allow: true)
            ]

        let ducExample = FindMarket.TenantSaleItem(name:"DUCExampleNFT", cut: nil, rules:rules, status: "active" )

        adminRef.setMarketOption(tenant: tenant, saleItem: ducExample)

        let cap = getAccount(account.address).getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        adminRef.addFindCut(tenant: tenant, FindCutName: "findDapperRoyalty", rayalty: MetadataViews.Royalty(recepient: cap, cut: 0.02, description: "find"), rules: rules, status: "active")

    }
}
